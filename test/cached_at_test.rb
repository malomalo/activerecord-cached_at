require 'test_helper'

class CachedAtTest < ActiveSupport::TestCase

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

  test 'Migration timestamps' do
    ActiveRecord::Migration.suppress_messages do
      ActiveRecord::Migration.create_table(:mountains) do |t|
        t.timestamps
      end
    end
    
    Mountain.reset_column_information
    assert_equal ["id", "created_at", "updated_at", "cached_at"], Mountain.column_names
    
    ActiveRecord::Migration.suppress_messages do
      ActiveRecord::Migration.drop_table(:mountains)
    end
  end
    
  test 'Migration add_timestamps' do
    ActiveRecord::Migration.suppress_messages do
      ActiveRecord::Migration.create_table :mountains
      ActiveRecord::Migration.add_timestamps(:mountains, {null: true})
    end
    
    Mountain.reset_column_information
    assert_equal ["id", "created_at", "updated_at", "cached_at"], Mountain.column_names
    
    ActiveRecord::Migration.suppress_messages do
      ActiveRecord::Migration.remove_timestamps(:mountains)
      ActiveRecord::Migration.drop_table(:mountains)
    end
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
