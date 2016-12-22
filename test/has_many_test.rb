require 'test_helper'

class HasManyTest < ActiveSupport::TestCase

  schema do
    create_table "organizations", force: :cascade do |t|
      t.string   "name",                limit: 255
      t.datetime 'cached_at',           null: false
      t.datetime 'accounts_cached_at',  null: false
    end

    create_table "accounts", force: :cascade do |t|
      t.string   "name",                    limit: 255
      t.datetime 'cached_at',               null: false
      t.integer  "organization_id"
      t.datetime 'organization_cached_at',  null: false
      t.integer  "photos_count",            null: false, default: 0
    end

    create_table "photos", force: :cascade do |t|
      t.integer  "account_id"
      t.datetime 'account_cached_at',      null: false
      t.string   "format",                 limit: 255
    end
  end

  class Organization < ActiveRecord::Base
    has_many :accounts, cached_at: true, inverse_of: :organization
  end

  class Account < ActiveRecord::Base
    belongs_to :organization, cached_at: true, inverse_of: :accounts
    has_many :photos, dependent: :nullify, cached_at: true, inverse_of: :account
  end

  class Photo < ActiveRecord::Base
    belongs_to :account, counter_cache: true
    has_many :photos, dependent: :nullify, cached_at: true, inverse_of: :account
  end

  test "::create" do
    account = Account.create
    
    time = Time.now + 60
    org = travel_to(time) do
      Organization.create(accounts: [account])
    end
    
    assert_equal time.to_i, account.reload.organization_cached_at.to_i
  end
  
  test "::update" do
    org = Organization.create
    account = Account.create(organization: org)

    time = Time.now + 60
    travel_to(time) { org.update(name: 'new name') }

    assert_equal time.to_i, account.reload.organization_cached_at.to_i
  end

  test "::destroy" do
    org = Organization.create
    account = Account.create(organization: org)

    time = Time.now + 60
    travel_to(time) { org.destroy }

    assert_equal time.to_i, account.reload.organization_cached_at.to_i
  end
  
  test "::destroy dependent: :destroy"
  test "::destroy dependent: :delete"
  
  test "::destroy dependent: :nullify" do
    account = Account.create
    photos = [Photo.create(account: account), Photo.create(account: account)]

    time = Time.now + 60
    travel_to(time) { account.destroy }

    assert_equal [time.to_i, time.to_i], photos.map{ |p| p.reload.account_cached_at.to_i }
  end

end
