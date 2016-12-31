require 'test_helper'

class HasManyThroughTest < ActiveSupport::TestCase

  schema do
    create_table "ships" do |t|
      t.string   "name",                 limit: 255
      t.datetime 'images_cached_at',      null: false
    end

    create_table "image_orderings", force: :cascade do |t|
      t.integer "subject_id",   null: false
      t.string  "subject_type", null: false
      t.integer "image_id",     null: false
    end

    create_table "images", force: :cascade do |t|
      t.string  "title"
    end
  end

  class Ship < ActiveRecord::Base
    has_many :image_orderings, as: :subject, dependent: :destroy
    has_many :images, through: :image_orderings, source: :image, inverse_of: :ships
  end

  class ImageOrdering < ActiveRecord::Base
    belongs_to :subject, polymorphic: true, inverse_of: :image_orderings
    belongs_to :image
  end

  class Image < ActiveRecord::Base
    has_many :image_orderings, dependent: :destroy
    has_many :ships, class_name: 'Ship', through: :image_orderings, inverse_of: :images, source: :subject, source_type: 'HasManyThroughTest::Ship', cached_at: true
    # cache_relation :photos, ->(record) { Ship.join(:image_ordergins).where('imageorderings.id = ?', record.id) }
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