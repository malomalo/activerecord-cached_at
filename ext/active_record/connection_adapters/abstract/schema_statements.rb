module ActiveRecord
  module ConnectionAdapters #:nodoc:

    module SchemaStatements
      def add_timestamps(table_name, **options)
        options[:null] = false if options[:null].nil?

        if !options.key?(:precision) && supports_datetime_with_precision?
          options[:precision] = 6
        end

        add_column table_name, :created_at, :datetime, **options
        add_column table_name, :updated_at, :datetime, **options
        add_column table_name, :cached_at, :datetime,  **options
      end

      def remove_timestamps(table_name, **options)
        remove_column table_name, :updated_at
        remove_column table_name, :created_at
        remove_column table_name, :cached_at
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

      def remove_timestamps_for_alter(table_name, **options)
        remove_columns_for_alter(table_name, :updated_at, :created_at, :cached_at)
      end

    end

  end
end