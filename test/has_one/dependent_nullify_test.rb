require 'test_helper'

class HasOneDependentNullifyTest < ActiveSupport::TestCase

  schema do
    create_table "accounts", force: :cascade do |t|
      t.string   "name",                 limit: 255
      t.datetime 'cached_at', null: false
    end
    
    create_table "avatars", force: :cascade do |t|
      t.string "sha256"
      t.integer  "account_id"
      t.datetime 'account_cached_at',      null: false
    end
  end
  
  class Account < ActiveRecord::Base
    has_one :avatar, cached_at: true, inverse_of: :account, dependent: :nullify
  end

  class Avatar < ActiveRecord::Base
    belongs_to :account
  end
  
    
  test "::create" do
    avatar = Avatar.create
    
    time = Time.now + 60
    account = travel_to(time) do
      assert_queries(2) { Account.create(avatar: avatar) }
    end
    
    assert_in_memory_and_persisted(avatar, :account_cached_at, time)
  end

  test "::update" do
    avatar = Avatar.create
    account = Account.create(avatar: avatar)
    
    time = Time.now + 60
    travel_to(time) do
      assert_queries(2) { account.update(name: 'new_name') }
    end
    
    assert_in_memory_and_persisted(avatar, :account_cached_at, time)
  end
  
  test "::destroy" do
    avatar = Avatar.create
    account = Account.create(avatar: avatar)
    
    time = Time.now + 60
    travel_to(time) do
      assert_queries(2) { account.destroy }
    end
    
    assert_in_memory_and_persisted(avatar, :account_cached_at, time)
  end

  test "add via =" do
    avatar = Avatar.create
    account = Account.create
    
    time = Time.now + 60
    travel_to(time) do
      assert_queries(2) { account.avatar = avatar }
    end
    
    assert_in_memory_and_persisted(avatar, :account_cached_at, time)
  end
  
  test "replaced via =" do
    avatar = Avatar.create
    avatar2 = Avatar.create
    account = Account.create(avatar: avatar)
    
    time = Time.now + 60
    travel_to(time) do
      debug do
      assert_queries(2) { account.avatar = avatar2 }
    end
    end
    
    assert_in_memory_and_persisted(avatar, :account_cached_at, time)
  end
  
  # test "relationship model added via <<" do
  #   ship = Ship.create
  #   image = Image.create
  #
  #   time = Time.now + 60
  #   travel_to(time) do
  #     assert_queries(2) { ship.images << image }
  #   end
  #
  #   assert_in_memory_and_persisted(ship, :images_cached_at, time)
  # end
  #
  # test "relationship set via = [...]" do
  #   ship = Ship.create
  #   image = Image.create
  #
  #   time = Time.now + 60
  #   travel_to(time) do
  #     assert_queries(3) { ship.images = [image] }
  #   end
  #
  #   assert_in_memory_and_persisted(ship, :images_cached_at, time)
  # end
  #
  # test "relationship model removed via = [...]" do
  #   image1 = Image.create
  #   image2 = Image.create
  #   ship = Ship.create(images: [image1, image2])
  #
  #   time = Time.now + 60
  #   travel_to(time) do
  #     assert_queries(2) { ship.images = [image2] }
  #   end
  #
  #   assert_in_memory_and_persisted(ship, :images_cached_at, time)
  # end


end