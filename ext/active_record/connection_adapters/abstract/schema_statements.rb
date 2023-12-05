module ActiveRecord
  module ConnectionAdapters #:nodoc:

    module SchemaStatements
      def remove_timestamps(table_name, **options)
        remove_columns table_name, :updated_at, :created_at, :cached_at
      end

      def add_timestamps_for_alter(table_name, **options)
        options[:null] = false if options[:null].nil?

        if !options.key?(:precision) && supports_datetime_with_precision?
          options[:precision] = 6
        end

        [
          add_column_for_alter(table_name, :created_at, :datetime, **options),
          add_column_for_alter(table_name, :updated_at, :datetime, **options),
          add_column_for_alter(table_name, :cached_at, :datetime, **options)
        ]
      end
    end

  end
end


ActiveSupport.on_load(:active_record_sqlite3adapter) do
  class ActiveRecord::ConnectionAdapters::SQLite3Adapter
    def add_timestamps(table_name, **options)
      options[:null] = false if options[:null].nil?

      if !options.key?(:precision)
        options[:precision] = 6
      end

      alter_table(table_name) do |definition|
        definition.column :created_at, :datetime, **options
        definition.column :updated_at, :datetime, **options
        definition.column :cached_at, :datetime, **options
      end
    end 
  end
end