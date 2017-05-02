require 'test_helper'

class HasOneTest < ActiveSupport::TestCase

  schema do
    create_table "accounts", force: :cascade do |t|
      t.string   "name",                 limit: 255
      t.datetime 'cached_at', null: false
    end

    create_table "emails", force: :cascade do |t|
      t.integer  "account_id"
      t.datetime 'account_cached_at',      null: false
    end
  end
  
  class Account < ActiveRecord::Base
    has_one :email, cached_at: true, inverse_of: :account
  end

  class Email < ActiveRecord::Base
    belongs_to :account
  end

  test "::create" do
    email = Email.create
    
    time = Time.now + 60
    account = travel_to(time) do
      assert_queries(2) { Account.create(email: email) }
    end
    
    assert_in_memory_and_persisted(email, :account_cached_at, time)
  end
  
  test "::update" do
    account = Account.create
    email = Email.create(account: account)

    time = Time.now + 60
    travel_to(time) do
      assert_queries(2) { account.update(name: 'new name') }
    end

    assert_in_memory_and_persisted(email, :account_cached_at, time)
  end

  test "::destroy" do
    account = Account.create
    email = Email.create(account: account)

    time = Time.now + 60
    travel_to(time) do
      assert_queries(2) { account.destroy }
    end

    assert_in_memory_and_persisted(email, :account_cached_at, time)
  end
  
  # test "::destroy dependent: :nullify" do
  #   account = Account.create
  #   avatar = Avatar.create(account: account)
  #
  #   time = Time.now + 60
  #   travel_to(time) { account.destroy }
  #
  #   # Memory
  #   assert_equal time.to_i, avatar.account_cached_at.to_i
  #
  #   # DB
  #   assert_equal time.to_i, avatar.reload.account_cached_at.to_i
  # end
  
end
