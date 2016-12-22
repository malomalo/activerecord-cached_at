module ActiveRecord
  module Reflection
    
    class ThroughReflection
      def touch_cached_at(owner, timestamp)
        return unless options[:cached_at]
    
        if inverse_of.nil?
          puts "WARNING: cannot updated cached at for relationship: #{owner.class.name}.#{name}, inverse_of not set"
          return
        end
    
        cache_column = "#{inverse_of.name}_cached_at"
        ids = [owner.send(association_primary_key), owner.send("#{association_primary_key}_was")].compact.uniq
        arel_table = klass._reflections[inverse_of.options[:through].to_s].klass.arel_table
        query = klass.joins(inverse_of.options[:through]).where(arel_table[foreign_key].in(ids))
        query.update_all({ cache_column => timestamp })
        traverse_relationships(klass, options[:cached_at], query, cache_column, timestamp)
      end
    end
    
  end
end