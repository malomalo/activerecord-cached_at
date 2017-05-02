require 'test_helper'

class HasManyThroughPolymorhicTest < ActiveSupport::TestCase

  schema do
    create_table "ships" do |t|
      t.string   "name",                 limit: 255
      t.datetime 'images_cached_at',      null: false
    end
    
    create_table "buildings" do |t|
      t.string   "name",                 limit: 255
      t.datetime 'images_cached_at',      null: false
    end

    create_table "ownerships", force: :cascade do |t|
      t.integer "subject_id",   null: false
      t.string  "subject_type", null: false
      t.integer "image_id",     null: false
    end

    create_table "images", force: :cascade do |t|
      t.string  "title"
    end
  end

  class Ship < ActiveRecord::Base
    has_many :ownerships, as: :subject, dependent: :destroy
    has_many :images, through: :ownerships, source: :image, inverse_of: :ships
  end

  class Ownership < ActiveRecord::Base
    belongs_to :subject, polymorphic: true, inverse_of: :ownerships
    belongs_to :image, inverse_of: :ownerships
  end

  class Image < ActiveRecord::Base
    has_many :ownerships, dependent: :destroy
    has_many :ships, through: :ownerships, inverse_of: :images, source: :subject, source_type: 'HasManyThroughPolymorhicTest::Ship', cached_at: true
    # cache_relation :photos, ->(record) { Ship.join(:image_ordergins).where('imageorderings.id = ?', record.id) }
  end

  test "::create" do
    ship = Ship.create

    time = Time.now + 60
    image = travel_to(time) do
      assert_queries(3) { Image.create(ships: [ship]) }
    end

    assert_in_memory_and_persisted(ship, :images_cached_at, time)
  end

  test "::update" do
    ship = Ship.create
    image = Image.create(ships: [ship])

    time = Time.now + 60
    travel_to(time) do
      assert_queries(2) { image.update(title: "new title") }
    end

    assert_in_memory_and_persisted(ship, :images_cached_at, time)
  end

  test "::destroy" do
    ship = Ship.create
    image = Image.create(ships: [ship])

    time = Time.now + 60
    travel_to(time) do
      assert_queries(4) { image.destroy }
    end

    assert_in_memory_and_persisted(ship, :images_cached_at, time)
  end

  test "relationship model added via <<" do
    ship = Ship.create
    image = Image.create

    time = Time.now + 60
    travel_to(time) do
      assert_queries(2) { ship.images << image }
    end
    assert_in_memory_and_persisted(ship, :images_cached_at, time)
  end

  test "relationship set via = [...]" do
    ship = Ship.create
    image = Image.create

    time = Time.now + 60
    travel_to(time) do
      assert_queries(3) { ship.images = [image] }
    end

    assert_in_memory_and_persisted(ship, :images_cached_at, time)
  end

  test "relationship model removed via = [...]" do
    image1 = Image.create
    image2 = Image.create
    ship = Ship.create(images: [image1, image2])

    time = Time.now + 60
    travel_to(time) do
      assert_queries(2) { ship.images = [image2] }
    end

    assert_in_memory_and_persisted(ship, :images_cached_at, time)
  end
end