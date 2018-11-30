module ActiveRecord
  module CachedAt
    module Timestamp
      extend ActiveSupport::Concern
      
      class_methods do
        private
    
        def timestamp_attributes_for_update
          ['updated_at']
        end

        def timestamp_attributes_for_create
          ['created_at', 'udpated_at', 'cached_at'] + column_names.select{|c| c.end_with?('_cached_at') }
        end

      end
    end
  end
end

ActiveRecord::Base.include(ActiveRecord::CachedAt::Timestamp)