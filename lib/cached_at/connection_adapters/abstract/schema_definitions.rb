module ActiveRecord
  module ConnectionAdapters #:nodoc:
    
    class TableDefinition
      def timestamps(*args)
        options = args.extract_options!
        
        options[:null] = false if options[:null].nil?
        
        column(:created_at, :datetime, options)
        column(:updated_at, :datetime, options)
        column(:cached_at, :datetime, options) if @name != ActiveRecord::Base.internal_metadata_table_name
      end
    end
    
  end
end