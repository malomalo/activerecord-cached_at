require 'test_helper'

class HasManyThroughTest < ActiveSupport::TestCase

  schema do
    create_table "ships" do |t|
      t.string   "name",                 limit: 255
      t.datetime 'images_cached_at',      null: false
      t.datetime 'missiles_cached_at',      null: false
      t.datetime 'cannons_cached_at',      null: false
      t.datetime 'planes_cached_at',      null: false
    end

    create_table "image_orderings", force: :cascade do |t|
      t.integer "ship_id",   null: false
      t.integer "image_id",     null: false
    end

    create_table "images", force: :cascade do |t|
      t.string  "title"
    end
    
    create_table "missile_orderings", force: :cascade do |t|
      t.integer "ship_id",   null: false
      t.integer "missile_id",     null: false
    end

    create_table "missiles", force: :cascade do |t|
      t.string  "title"
    end
    
    create_table "cannon_orderings", force: :cascade do |t|
      t.integer "ship_id",   null: false
      t.integer "cannon_id",     null: false
    end

    create_table "cannons", force: :cascade do |t|
      t.string  "title"
    end
    
    create_table "plane_orderings", force: :cascade do |t|
      t.integer "ship_id"
      t.integer "plane_id",   null: false
    end

    create_table "planes", force: :cascade do |t|
      t.string  "title"
    end
  end

  class Ship < ActiveRecord::Base
    has_many :image_orderings, dependent: :destroy
    has_many :images, through: :image_orderings, source: :image, inverse_of: :ships
    
    has_many :missile_orderings
    has_many :missiles, through: :missile_orderings, source: :missile, inverse_of: :ships
    
    has_many :cannon_orderings
    has_many :cannons, through: :cannon_orderings, source: :cannon, inverse_of: :ships

    has_many :plane_orderings
    has_many :planes, through: :plane_orderings, source: :plane, inverse_of: :ships
  end

  class ImageOrdering < ActiveRecord::Base
    belongs_to :ship, class_name: 'HasManyThroughTest::Ship'
    belongs_to :image
  end

  class Image < ActiveRecord::Base
    has_many :image_orderings, dependent: :destroy
    has_many :ships, through: :image_orderings, inverse_of: :images, cached_at: true
    # cache_relation :photos, ->(record) { Ship.join(:image_ordergins).where('imageorderings.id = ?', record.id) }
  end
  
  class MissileOrdering < ActiveRecord::Base
    belongs_to :ship, class_name: 'HasManyThroughTest::Ship'
    belongs_to :missile
  end

  class Missile < ActiveRecord::Base
    has_many :missile_orderings
    has_many :ships, through: :missile_orderings, inverse_of: :missiles, cached_at: true, dependent: :destroy
  end
  
  class CannonOrdering < ActiveRecord::Base
    belongs_to :ship, class_name: 'HasManyThroughTest::Ship'
    belongs_to :cannon
  end

  class Cannon < ActiveRecord::Base
    has_many :cannon_orderings
    has_many :ships, through: :cannon_orderings, inverse_of: :cannons, cached_at: true, dependent: :delete_all
  end
  
  class PlaneOrdering < ActiveRecord::Base
    belongs_to :ship, class_name: 'HasManyThroughTest::Ship'
    belongs_to :plane
  end

  class Plane < ActiveRecord::Base
    has_many :plane_orderings
    has_many :ships, through: :plane_orderings, inverse_of: :planes, cached_at: true, dependent: :nullify
  end

  test "::create" do
    ship = Ship.create

    time = Time.now + 60
    image = travel_to(time) do
      Image.create(ships: [ship])
    end

    assert_equal time.to_i, ship.reload.images_cached_at.to_i
    # assert_equal time.to_i, image.reload.ships_cached_at.to_i
  end

  test "::update" do
    ship = Ship.create
    image = Image.create(ships: [ship])

    time = Time.now + 60
    travel_to(time) do
      image.update(title: "new title")
    end

    assert_equal time.to_i, ship.reload.images_cached_at.to_i
    # assert_equal time.to_i, image.reload.ships_cached_at.to_i
  end

  test "::destroy" do
    ship = Ship.create
    image = Image.create(ships: [ship])

    time = Time.now + 60
    travel_to(time) do
      image.destroy
    end

    assert_equal time.to_i, ship.reload.images_cached_at.to_i
  end

  test "::destroy dependent: :destroy" do
    ship = Ship.create
    missile = Missile.create(ships: [ship])

    time = Time.now + 60
    travel_to(time) do
      missile.destroy
    end
    
    assert_equal 0, MissileOrdering.count

    assert_equal time.to_i, ship.reload.missiles_cached_at.to_i
  end
  
  test "::destroy dependent: :delete_all" do
    ship = Ship.create
    cannon = Cannon.create(ships: [ship])

    time = Time.now + 60
    travel_to(time) do
      cannon.destroy
    end
    
    assert_equal 0, CannonOrdering.count

    assert_equal time.to_i, ship.reload.cannons_cached_at.to_i
  end
  
  test "::destroy dependent: :nullify" do
    ship = Ship.create
    plane = Plane.create(ships: [ship])

    time = Time.now + 60
    travel_to(time) do
      plane.destroy
    end
    
    assert_equal 1, PlaneOrdering.where(ship_id: nil).count

    assert_equal time.to_i, ship.reload.planes_cached_at.to_i
  end

  test "relationship model added via <<" do
    ship = Ship.create
    image = Image.create

    time = Time.now + 60
    travel_to(time) { ship.images << image }
  
    assert_equal time.to_i, ship.reload.images_cached_at.to_i
    # assert_equal time.to_i, image.reload.ships_cached_at.to_i
  end

  test "relationship set via = [...]" do
    ship = Ship.create
    image = Image.create

    time = Time.now + 60
    travel_to(time) { ship.images = [image] }

    assert_equal time.to_i, ship.reload.images_cached_at.to_i
    # assert_equal time.to_i, image.reload.ships_cached_at.to_i
  end

  test "relationship model removed via = [...]" do
    image1 = Image.create
    image2 = Image.create
    ship = Ship.create(images: [image1, image2])

    time = Time.now + 60
    travel_to(time) { ship.images = [image2] }

    assert_equal time.to_i, ship.reload.images_cached_at.to_i
    # assert_equal time.to_i, image.reload.ships_cached_at.to_i
  end


end