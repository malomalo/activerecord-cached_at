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
      Account.create(email: email)
    end
    
    # Memory
    assert_equal time.to_i, email.account_cached_at.to_i
    
    # DB
    assert_equal time.to_i, email.reload.account_cached_at.to_i
  end
  
  test "::update" do
    account = Account.create
    email = Email.create(account: account)

    time = Time.now + 60
    travel_to(time) { account.update(name: 'new name') }

    # Memory
    assert_equal time.to_i, email.account_cached_at.to_i
    
    # DB
    assert_equal time.to_i, email.reload.account_cached_at.to_i
  end

  test "::destroy" do
    account = Account.create
    email = Email.create(account: account)

    time = Time.now + 60
    travel_to(time) { account.destroy }

    # Memory
    assert_equal time.to_i, email.account_cached_at.to_i
    
    # DB
    assert_equal time.to_i, email.reload.account_cached_at.to_i
  end

  test "::destroy dependent: :destroy"
  test "::destroy dependent: :delete"
  test "::destroy dependent: :nullify"
  
end
