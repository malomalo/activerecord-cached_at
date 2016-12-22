module ActiveRecord
  module Reflection
    
    class HasManyReflection
      def touch_cached_at(owner, timestamp)
        return unless options[:cached_at]
    
        if inverse_of.nil?
          puts "WARNING: cannot updated cached at for relationship: #{owner.class.name}.#{name}, inverse_of not set"
          return
        end
    
        cache_column = "#{inverse_of.name}_cached_at"
        ids = [owner.send(association_primary_key), owner.send("#{association_primary_key}_was")].compact.uniq
        query = klass.where({ foreign_key => ids })
    
        case options[:dependent]
        when nil
          query.update_all({ cache_column => timestamp })
          traverse_relationships(klass, options[:cached_at], query, cache_column, timestamp)
        when :destroy
          query.update_all({ cache_column => timestamp })
          traverse_relationships(klass, options[:cached_at], query, cache_column, timestamp)
          # shouldn't need to to worry about :destroy, that will touch the other caches on destroy
        when :delete_all, :nullify
          traverse_relationships(klass, options[:cached_at], query, cache_column, timestamp)
        end
      end
    end
    
  end
end