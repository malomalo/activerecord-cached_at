module ActiveRecord
  module Timestamp
  private
    def timestamp_attributes_for_update
      [:updated_at, :updated_on, :cached_at]
    end

    def timestamp_attributes_for_create
      [:created_at, :created_on, :cached_at]
    end
  end
end


module ActiveRecord
  module ConnectionAdapters #:nodoc:
    
    class TableDefinition
      def timestamps(*args)
        options = args.extract_options!

        options[:null] = false if options[:null].nil?

        column(:created_at, :datetime, options)
        column(:updated_at, :datetime, options)
        column(:cached_at, :datetime, options)
      end
    end
    
    module SchemaStatements
      def add_timestamps(table_name, options = {})
        options[:null] = false if options[:null].nil?

        add_column table_name, :created_at, :datetime, options
        add_column table_name, :updated_at, :datetime, options
        add_column table_name, :cached_at, :datetime, options
      end
      
      def remove_timestamps(table_name, options = {})
        remove_column table_name, :updated_at
        remove_column table_name, :created_at
        remove_column table_name, :cached_at
      end
    end
    
  end
end