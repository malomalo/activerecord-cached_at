require 'test_helper'

class HasManyTest < ActiveSupport::TestCase

  schema do
    create_table "organizations", force: :cascade do |t|
      t.string   "name",                limit: 255
      t.datetime "updated_at",          null: false
      t.datetime 'cached_at',           null: false
      t.datetime 'accounts_cached_at',  null: false
      t.datetime 'photos_cached_at',  null: false
      t.datetime 'ships_cached_at',  null: false
    end

    create_table "accounts", force: :cascade do |t|
      t.string   "name",                    limit: 255
      t.datetime 'cached_at',               null: false
      t.integer  "organization_id"
      t.datetime 'organization_cached_at',  null: false
      t.integer  "photos_count",            null: false, default: 0
    end

    create_table "photos", force: :cascade do |t|
      t.integer  "organization_id"
      t.datetime 'organization_cached_at',  null: false
    end
    
    create_table "ships", force: :cascade do |t|
      t.integer  "organization_id"
      t.datetime 'organization_cached_at',  null: false
    end
    
    create_table "planes", force: :cascade do |t|
      t.integer  "organization_id"
      t.datetime 'organization_cached_at',  null: false
    end
  end

  class Organization < ActiveRecord::Base
    has_many :accounts, cached_at: true, inverse_of: :organization
    has_many :photos, dependent: :nullify, cached_at: true, inverse_of: :organization
    has_many :ships, dependent: :delete_all, cached_at: true, inverse_of: :organization
    has_many :planes, dependent: :destroy, cached_at: true, inverse_of: :organization
  end

  class Account < ActiveRecord::Base
    belongs_to :organization, cached_at: true, inverse_of: :accounts
  end

  class Photo < ActiveRecord::Base
    belongs_to :organization, cached_at: true, inverse_of: :photos
  end

  class Ship < ActiveRecord::Base
    belongs_to :organization, cached_at: true, inverse_of: :ships
  end

  class Plane < ActiveRecord::Base
    belongs_to :organization, cached_at: true, inverse_of: :ships
  end

  test "::create" do
    account = Account.create
    
    time = Time.now + 60
    org = travel_to(time) do
      Organization.create(accounts: [account])
    end
    
    # Memory
    assert_equal time.to_i, account.organization_cached_at.to_i
    
    # DB
    assert_equal time.to_i, account.reload.organization_cached_at.to_i
  end
  
  test "::update attributes" do
    account = Account.create
    org = Organization.create(accounts: [account])

    time = Time.now + 60
    travel_to(time) { org.update(name: 'new name') }
    
    # Memory
    assert_equal time.to_i, account.organization_cached_at.to_i
    
    # DB
    assert_equal time.to_i, account.reload.organization_cached_at.to_i
  end
  
  test "::update association" do
    account1 = Account.create
    account2 = Account.create
    org = Organization.create(accounts: [account1])

    time = Time.now + 60
    travel_to(time) { org.update(accounts: [account2]) }
    
    # Memory
    assert_equal time.to_i, account1.organization_cached_at.to_i
    assert_equal time.to_i, account2.organization_cached_at.to_i
    
    # DB
    assert_equal time.to_i, account1.reload.organization_cached_at.to_i
    assert_equal time.to_i, account2.reload.organization_cached_at.to_i
  end
  
  test "::touch" do
    account = Account.create
    org = Organization.create(accounts: [account])

    time = Time.now + 60
    travel_to(time) { org.touch }

    # Memory
    assert_equal time.to_i, account.organization_cached_at.to_i
    
    # DB
    assert_equal time.to_i, account.reload.organization_cached_at.to_i
  end

  test "::destroy" do
    account = Account.create
    org = Organization.create(accounts: [account])

    time = Time.now + 60
    travel_to(time) { org.destroy }

    # Memory
    assert_equal time.to_i, account.organization_cached_at.to_i
    
    # DB
    assert_equal time.to_i, account.reload.organization_cached_at.to_i
  end
  
  test "::destroy dependent: :delete_all" do
    ships = [Ship.create, Ship.create]
    org = Organization.create(ships: ships)

    time = Time.now + 60
    travel_to(time) { org.destroy }
  
    assert_equal 0, Ship.count
  end
  
  test "::destroy dependent: :destroy" do
    planes = [Plane.create, Plane.create]
    org = Organization.create(planes: planes)

    time = Time.now + 60
    travel_to(time) { org.destroy }

    assert_equal 0, Plane.count
  end
    
  test "::destroy dependent: :nullify" do
    photos = [Photo.create, Photo.create]
    org = Organization.create(photos: photos)

    time = Time.now + 60
    travel_to(time) { org.destroy }

    # Memory
    assert_equal [time.to_i, time.to_i], photos.map{ |p| p.organization_cached_at.to_i }
    
    # DB
    assert_equal [time.to_i, time.to_i], photos.map{ |p| p.reload.organization_cached_at.to_i }
  end

end
