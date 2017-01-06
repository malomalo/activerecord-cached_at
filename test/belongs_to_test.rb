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
      assert_queries(2) { Account.create(organization: org) }
    end

    assert_in_memory_and_persisted(org, :accounts_cached_at, time)
  end
  
  test "::update" do
    org = Organization.create
    account = Account.create(organization: org)
    time = Time.now + 60
    
    travel_to(time) do
      assert_queries(2) { account.update(name: 'new name') }
    end

    assert_in_memory_and_persisted(org, :accounts_cached_at, time)
  end
  
  test "::update changing relationship" do
    oldorg = Organization.create
    neworg = Organization.create
    account = Account.create(organization: oldorg)
    time = Time.now + 60
    
    travel_to(time) do
      assert_queries(2) { account.update(organization: neworg) }
    end

    assert_in_memory_and_persisted(neworg, :accounts_cached_at, time)
    assert_in_memory_and_persisted(oldorg, :accounts_cached_at, time)
  end
  
  test "::destroy" do
    org = Organization.create
    account = Account.create(organization: org)
    time = Time.now + 60
    
    travel_to(time) do
      assert_queries(2) { account.destroy }
    end

    assert_in_memory_and_persisted(org, :accounts_cached_at, time)
  end
  
  test ".relationship = nil" do
    org = Organization.create
    account = Account.create(organization: org)
    time = Time.now + 60
    
    travel_to(time) do
      assert_queries(2) { account.update(organization: nil) }
    end

    assert_in_memory_and_persisted(org, :accounts_cached_at, time)
  end
  
end