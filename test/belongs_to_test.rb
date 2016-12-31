require 'test_helper'

class BelongsToTest < ActiveSupport::TestCase
  
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
    end
  end

  class Organization < ActiveRecord::Base
    has_many :accounts, cached_at: true, inverse_of: :organization
  end

  class Account < ActiveRecord::Base
    belongs_to :organization, cached_at: true, inverse_of: :accounts
  end
  
  test "::create" do
    org = Organization.create
    time = Time.now + 60
    
    travel_to(time) do
      Account.create(organization: org)
    end

    # Memory
    assert_equal time.to_i, org.accounts_cached_at.to_i
    
    # DB
    assert_equal time.to_i, org.reload.accounts_cached_at.to_i
  end
  
  test "::update" do
    org = Organization.create
    account = Account.create(organization: org)
    time = Time.now + 60
    
    travel_to(time) { account.update(name: 'new name') }

    # Memory
    assert_equal time.to_i, org.accounts_cached_at.to_i
    
    # DB
    assert_equal time.to_i, org.reload.accounts_cached_at.to_i
  end
  
  test "::update changing relationship" do
    oldorg = Organization.create
    neworg = Organization.create
    account = Account.create(organization: oldorg)
    time = Time.now + 60
    
    travel_to(time) { account.update(organization: neworg) }

    # Memory
    assert_equal time.to_i, neworg.accounts_cached_at.to_i
    assert_equal time.to_i, oldorg.accounts_cached_at.to_i
    
    # DB
    assert_equal time.to_i, neworg.reload.accounts_cached_at.to_i
    assert_equal time.to_i, oldorg.reload.accounts_cached_at.to_i
  end
  
  test "::destroy" do
    org = Organization.create
    account = Account.create(organization: org)
    time = Time.now + 60
    
    travel_to(time) { account.destroy }

    # Memory
    assert_equal time.to_i, org.accounts_cached_at.to_i
    
    # DB
    assert_equal time.to_i, org.reload.accounts_cached_at.to_i
  end
  
  test ".relationship = nil" do
    org = Organization.create
    account = Account.create(organization: org)
    time = Time.now + 60
    
    travel_to(time) { account.update(organization: nil) }
    
    # Memory
    assert_equal time.to_i, org.accounts_cached_at.to_i
    assert_equal time.to_i, account.organization_cached_at.to_i
    
    # DB
    assert_equal time.to_i, org.reload.accounts_cached_at.to_i
    assert_equal time.to_i, account.reload.organization_cached_at.to_i
  end
  
end