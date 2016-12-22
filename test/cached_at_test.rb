require 'test_helper'

class CachedAtTest < ActiveSupport::TestCase

  schema do
    create_table "accounts", force: :cascade do |t|
      t.string   "name",                    limit: 255
      t.datetime 'cached_at',               null: false
      t.integer  "organization_id"
      t.datetime 'organization_cached_at',  null: false
    end
    
    create_table "regions", force: :cascade do |t|
    end
  end
  
  class Account < ActiveRecord::Base
  end
  
  class Region < ActiveRecord::Base
  end
  
  test "::create" do
    time = Time.now
    model = travel_to(time) do
      Account.create
    end
    
    assert_equal time.to_i, model.cached_at.to_i
  end
  
  test "::create on model w/o cached_at" do
    assert Region.create
  end
  
  test "#update" do
    time = Time.now
    
    model = travel_to(1.week.ago) do
      Account.create
    end
    
    travel_to(time) do
      model.update(:name => 'new')
    end
    
    assert_equal time.to_i, model.cached_at.to_i
  end

  # test 'counter caches' do
  #   t1 = 1.week.ago
  #   t2 = Time.now
  #
  #   model = travel_to(t1) do
  #     Account.create
  #   end
  #
  #   puts model.reload.photos_count
  #   travel_to(t2) do
  #     Photo.create(account: model)
  #   end
  #
  #   # TODO... rails doen'st update updated_at on counter_cache
  # end


end
