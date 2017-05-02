require 'test_helper'

class HasManyDependentDestroyTest < ActiveSupport::TestCase

  schema do
    create_table "organizations", force: :cascade do |t|
      t.string   "name",                limit: 255
      t.datetime 'cached_at',           null: false
    end

    create_table "accounts", force: :cascade do |t|
      t.string   "name",                    limit: 255
      t.datetime 'cached_at',               null: false
      t.integer  "organization_id"
      t.datetime 'organization_cached_at',  null: false
    end
  end

  class Organization < ActiveRecord::Base
    has_many :accounts, dependent: :destroy, cached_at: true, inverse_of: :organization
  end

  class Account < ActiveRecord::Base
    belongs_to :organization, inverse_of: :accounts
  end

  test "::create" do
    account = Account.create
    
    time = Time.now + 60
    org = travel_to(time) do
      assert_queries(2) { Organization.create(accounts: [account]) }
    end
    
    assert_in_memory_and_persisted(account, :organization_cached_at, time)
  end
  
  test "::update attributes" do
    account = Account.create
    org = Organization.create(accounts: [account])

    time = Time.now + 60
    travel_to(time) do
      assert_queries(2) { org.update(name: 'new name') }
    end

    assert_in_memory_and_persisted(account, :organization_cached_at, time)
  end
  
  test "::update association" do
    account1 = Account.create
    account2 = Account.create
    org = Organization.create(accounts: [account1])

    time = Time.now + 60
    travel_to(time) do
      assert_queries(2) { org.update(accounts: [account2]) }
    end

    assert account1.destroyed?
    assert_in_memory_and_persisted(account2, :organization_cached_at, time)
  end
  
  test "::touch" do
    account = Account.create
    org = Organization.create(accounts: [account])

    time = Time.now + 60
    travel_to(time) do
      assert_queries(2) { org.touch }
    end

    assert_in_memory_and_persisted(account, :organization_cached_at, time)
  end

  test "::destroy" do
    account = Account.create
    org = Organization.create(accounts: [account])

    time = Time.now + 60
    travel_to(time) do
      assert_queries(2) { org.destroy }
    end

    assert account.destroyed?
  end

end
