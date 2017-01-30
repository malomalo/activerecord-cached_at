require 'test_helper'

class HasManyDependentDeleteAllTest < ActiveSupport::TestCase

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
    has_many :accounts, dependent: :delete_all, cached_at: true, inverse_of: :organization
  end

  class Account < ActiveRecord::Base
    belongs_to :organization, inverse_of: :accounts
  end

  test "::create" do
    account = Account.create

    time = Time.now + 60
    org = travel_to(time) do
      debug do
      assert_queries(2) { Organization.create(accounts: [account]) }
    end
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
    t1 = Time.now
    org = travel_to(t1) do
      Organization.create(accounts: [account1])
    end

    time = Time.now + 60
    travel_to(time) do
      assert_queries(2) { org.update(accounts: [account2]) }
    end

    assert_equal 0, Account.where(id: account1.id).count
    assert_in_memory_and_persisted(account2, :organization_cached_at, t1)
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

    assert_equal 0, Account.where(id: account.id).count
  end

end
