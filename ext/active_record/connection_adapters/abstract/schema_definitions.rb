module ActiveRecord
  module ConnectionAdapters #:nodoc:

    class TableDefinition
      def timestamps(**options)
        options[:null] = false if options[:null].nil?

        if !options.key?(:precision) && @conn.supports_datetime_with_precision?
          options[:precision] = 6
        end

        column(:created_at, :datetime, **options)
        column(:updated_at, :datetime, **options)
        column(:cached_at, :datetime,  **options)
      end
    end

  end
end