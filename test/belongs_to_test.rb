require 'test_helper'

class BelongsToTest < ActiveSupport::TestCase

  test "::create" do
    org = Organization.create
    time = Time.now + 60
    model = travel_to(time) do
      Account.create(organization: org)
    end
    
    assert_equal time.to_i, org.reload.accounts_cached_at.to_i
  end
  
  test "::update" do
    org = Organization.create
    account = Account.create(organization: org)
    time = Time.now + 60
    
    travel_to(time) { account.update(name: 'new name') }
    
    assert_equal time.to_i, org.reload.accounts_cached_at.to_i
  end
  
  test "::update changing relationship" do
    oldorg = Organization.create
    neworg = Organization.create
    account = Account.create(organization: oldorg)
    time = Time.now + 60
    
    travel_to(time) { account.update(organization: neworg) }
    
    assert_equal time.to_i, neworg.reload.accounts_cached_at.to_i
    assert_equal time.to_i, oldorg.reload.accounts_cached_at.to_i
  end
  
  test "::destroy" do
    org = Organization.create
    account = Account.create(organization: org)
    time = Time.now + 60
    
    travel_to(time) { account.destroy }
    
    assert_equal time.to_i, org.reload.accounts_cached_at.to_i
  end
  
end
