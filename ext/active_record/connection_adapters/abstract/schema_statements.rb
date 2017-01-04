module ActiveRecord
  module ConnectionAdapters #:nodoc:

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