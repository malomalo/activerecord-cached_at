module ActiveRecord
  module ConnectionAdapters #:nodoc:

    class TableDefinition

      def internal_table?
        @name == "#{ActiveRecord::Base.table_name_prefix}#{ActiveRecord::Base.internal_metadata_table_name}#{ActiveRecord::Base.table_name_suffix}"
      end
      
      def timestamps(**options)
        options[:null] = false if options[:null].nil?

        if !options.key?(:precision) && @conn.supports_datetime_with_precision?
          options[:precision] = 6
        end

        column(:created_at, :datetime, **options)
        column(:updated_at, :datetime, **options)
        column(:cached_at, :datetime,  **options) if !internal_table?
      end
    end

  end
end