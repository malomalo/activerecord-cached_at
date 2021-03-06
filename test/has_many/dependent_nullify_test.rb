require 'test_helper'

class HasManyDependentNullifyTest < ActiveSupport::TestCase

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
    has_many :accounts, dependent: :nullify, cached_at: true, inverse_of: :organization
  end

  class Account < ActiveRecord::Base
    belongs_to :organization, inverse_of: :accounts
  end

  test "::create" do
    account = Account.create
    
    time = Time.now + 60
    org = travel_to(time) do
      Organization.create(accounts: [account])
    end
    
    assert_in_memory_and_persisted(account, :organization_cached_at, time)
  end
  
  test "::update attributes" do
    account = Account.create
    org = Organization.create(accounts: [account])

    time = Time.now + 60
    travel_to(time) { org.update(name: 'new name') }

    assert_in_memory_and_persisted(account, :organization_cached_at, time)
  end
  
  test "::update association" do
    account1 = Account.create
    account2 = Account.create
    org = Organization.create(accounts: [account1])

    time = Time.now + 60
    travel_to(time) { org.update(accounts: [account2]) }

    assert_nil account1.reload.organization_id
    assert_in_memory_and_persisted(account2, :organization_cached_at, time)
  end
  
  test "::touch" do
    account = Account.create
    org = Organization.create(accounts: [account])

    time = Time.now + 60
    travel_to(time) { org.touch }

    assert_in_memory_and_persisted(account, :organization_cached_at, time)
  end

  test "::destroy" do
    account = Account.create
    org = Organization.create(accounts: [account])

    time = Time.now + 60
    travel_to(time) { org.destroy }
    
    assert_nil account.reload.organization_id
  end

end
