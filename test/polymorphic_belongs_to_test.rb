require 'test_helper'

class PolymorphicBelongsToTest < ActiveSupport::TestCase
  
  schema do
    create_table "organizations", force: :cascade do |t|
      t.string   "name",                limit: 255
      t.datetime 'cached_at',           null: false
      t.datetime 'images_cached_at',    null: false
    end

    create_table "accounts", force: :cascade do |t|
      t.string   "name",                    limit: 255
      t.datetime 'cached_at',               null: false
      t.datetime 'images_cached_at',        null: false
    end
    
    create_table "images", force: :cascade do |t|
      t.string   "title",                    limit: 255
      t.string   'item_type'
      t.integer  'item_id'
      t.datetime 'cached_at',                null: false
    end
  end

  class Organization < ActiveRecord::Base
    has_many :images
  end

  class Account < ActiveRecord::Base
    has_many :images
  end
  
  class Image < ActiveRecord::Base
    belongs_to :item, polymorphic: true, inverse_of: :images, cached_at: true
  end
  
  test "::create" do
    org = Organization.create
    time = Time.now + 60
    
    travel_to(time) do
      Image.create(item: org)
    end

    assert_in_memory_and_persisted(org, :images_cached_at, time)
  end
  
  test "::update" do
    org = Organization.create
    image = Image.create(item: org)
    time = Time.now + 60

    travel_to(time) { image.update(title: 'new name') }

    assert_in_memory_and_persisted(org, :images_cached_at, time)
  end

  test "::update changing relationship" do
    olditem = Organization.create
    newitem = Organization.create
    image = Image.create(item: olditem)
    time = Time.now + 60
    
    travel_to(time) { image.update(item: newitem) }

    assert_in_memory_and_persisted(newitem, :images_cached_at, time)
    assert_in_memory_and_persisted(olditem, :images_cached_at, time)
  end
  
  test "::update changing relationship to a different model" do
    olditem = Organization.create
    newitem = Account.create
    image = Image.create(item: olditem)
    time = Time.now + 60
    
    travel_to(time) { image.update(item: newitem) }
    
    assert_in_memory_and_persisted(newitem, :images_cached_at, time)
    assert_in_memory_and_persisted(olditem, :images_cached_at, time)
  end

  test "::destroy" do
    org = Organization.create
    image = Image.create(item: org)
    time = Time.now + 60

    travel_to(time) do
      image.destroy
    end

    assert_in_memory_and_persisted(org, :images_cached_at, time)
  end

  test ".relationship = nil" do
    org = Organization.create
    image = Image.create(item: org)
    time = Time.now + 60

    travel_to(time) { image.update(item: nil) }


    assert_in_memory_and_persisted(org, :images_cached_at, time)
  end
  
end