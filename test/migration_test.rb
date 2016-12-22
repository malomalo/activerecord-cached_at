require 'test_helper'

class MigrationTest < ActiveSupport::TestCase
  
  # schema do
  # end
  
  class Mountain < ActiveRecord::Base
  end

  test 'timestamps' do
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
    
  test 'add_timestamps' do
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
  
  test 'remove_timestamps' do
    ActiveRecord::Migration.suppress_messages do
      ActiveRecord::Migration.create_table :mountains
      ActiveRecord::Migration.add_timestamps(:mountains, {null: true})
    end
    
    Mountain.reset_column_information
    assert_equal ["id", "created_at", "updated_at", "cached_at"], Mountain.column_names
    
    ActiveRecord::Migration.suppress_messages do
      ActiveRecord::Migration.remove_timestamps(:mountains)
    end

    Mountain.reset_column_information
    assert_equal ["id"], Mountain.column_names
    
    ActiveRecord::Migration.suppress_messages do
      ActiveRecord::Migration.drop_table(:mountains)
    end
  end

end
