require 'test_helper'

class HasManyTest < ActiveSupport::TestCase

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
  
end
