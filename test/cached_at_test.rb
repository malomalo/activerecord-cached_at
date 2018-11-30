require 'test_helper'

class CachedAtTest < ActiveSupport::TestCase

  schema do
    create_table "accounts", force: :cascade do |t|
      t.string   "name",                    limit: 255
      t.datetime 'cached_at',               null: false
      t.string   'ignore_column'
      t.integer  "organization_id"
      t.datetime 'organization_cached_at',  null: false
      t.datetime 'organization_images_cached_at',  null: false
    end
    
    create_table "regions", force: :cascade do |t|
    end
  end
  
  class Account < ActiveRecord::Base
    cached_at ignore: :ignore_column
  end
  
  class Region < ActiveRecord::Base
  end
  
  test "::create" do
    time = Time.now
    model = travel_to(time) do
      assert_queries(1) { Account.create }
    end
    
    assert_equal time.to_i, model.cached_at.to_i
  end
  
  test "::create on model w/o cached_at" do
    assert_queries(1) do
      assert Region.create
    end
  end
  
  test "#update" do
    time = Time.now
    
    model = travel_to(1.week.ago) do
      assert_queries(1) { Account.create }
    end
    
    travel_to(time) do
      assert_queries(1) { model.update(:name => 'new') }
    end
    
    assert_equal time.to_i, model.cached_at.to_i
  end

  test "#update just ignored column doesn't update cached at" do
    old_time = 1.week.ago
    time = Time.now

    model = travel_to(1.week.ago) do
      assert_queries(1) { Account.create }
    end

    travel_to(time) do
      assert_queries(1) { model.update(:ignore_column => 'new') }
    end

    assert_equal old_time.to_i, model.cached_at.to_i
  end

  test "::cached_at_columns_for_includes" do
    assert_equal ['organization_cached_at'], Account.cached_at_columns_for_includes([:organization])
    assert_equal ['organization_cached_at', 'region_cached_at'], Account.cached_at_columns_for_includes([:organization, :region])

    assert_equal ['organization_cached_at', 'organization_images_cached_at', 'region_cached_at'], Account.cached_at_columns_for_includes({organization: [:images], region: true}).sort
  end

  test "::can_cache?" do
    assert Account.can_cache?([])
    assert Account.can_cache?([:organization])
    assert Account.can_cache?({organization: true})
    refute Account.can_cache?([:organization, :region])
    refute Account.can_cache?({organization: [:images], region: true})
  end

  test "#cache_key" do
    t1 = Time.now
    t2 = Time.now + 10
    t3 = Time.now + 20
    account = Account.create
    account.update_columns(cached_at: t1, organization_cached_at: t2, organization_images_cached_at: t3)

    assert_equal "cached_at_test/accounts/#{account.id}-#{t1.utc.to_s(:usec)}", account.cache_key
    assert_equal "cached_at_test/accounts/#{account.id}+b4c1948c087fafc89a88450fcbb64c77@#{t2.utc.to_s(:usec)}", account.cache_key(:organization)
    assert_equal "cached_at_test/accounts/#{account.id}+b471431f7777fe57283f68842e724add@#{t3.utc.to_s(:usec)}", account.cache_key(organization: :images)
    assert_equal "cached_at_test/accounts/#{account.id}+b471431f7777fe57283f68842e724add@#{t3.utc.to_s(:usec)}", account.cache_key([organization: [:images]])
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
