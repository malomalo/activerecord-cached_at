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

    # Memory
    assert_equal time.to_i, org.images_cached_at.to_i
    
    # DB
    assert_equal time.to_i, org.reload.images_cached_at.to_i
  end
  
  test "::update" do
    org = Organization.create
    image = Image.create(item: org)
    time = Time.now + 60

    travel_to(time) { image.update(title: 'new name') }

    # Memory
    assert_equal time.to_i, org.images_cached_at.to_i

    # DB
    assert_equal time.to_i, org.reload.images_cached_at.to_i
  end

  test "::update changing relationship" do
    olditem = Organization.create
    newitem = Account.create
    image = Image.create(item: olditem)
    time = Time.now + 60
    
    travel_to(time) { image.update(item: newitem) }
    
    # Memory
    assert_equal time.to_i, newitem.images_cached_at.to_i
    assert_equal time.to_i, olditem.images_cached_at.to_i

    # DB
    assert_equal time.to_i, newitem.reload.images_cached_at.to_i
    assert_equal time.to_i, olditem.reload.images_cached_at.to_i
  end

  test "::destroy" do
    org = Organization.create
    image = Image.create(item: org)
    time = Time.now + 60

    travel_to(time) { image.destroy }

    # Memory
    assert_equal time.to_i, org.images_cached_at.to_i

    # DB
    assert_equal time.to_i, org.reload.images_cached_at.to_i
  end

  test ".relationship = nil" do
    org = Organization.create
    image = Image.create(item: org)
    time = Time.now + 60

    travel_to(time) { image.update(item: nil) }

    # Memory
    assert_equal time.to_i, org.images_cached_at.to_i
    # assert_equal time.to_i, account.items_cached_at.to_i

    # DB
    assert_equal time.to_i, org.reload.images_cached_at.to_i
    # assert_equal time.to_i, account.reload.items_cached_at.to_i
  end
  
end