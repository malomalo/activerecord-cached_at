module CachedAt
  module HasOneAssociation
  
    def touch_cached_at(timestamp, method)
      return unless options[:cached_at]
      
      if reflection.inverse_of.nil?
        puts "WARNING: cannot updated cached at for relationship: #{owner.class.name}.#{name}, inverse_of not set"
        return
      end
  
      cache_column = "#{reflection.inverse_of.name}_cached_at"
      ids = [owner.send(reflection.association_primary_key), owner.send("#{reflection.association_primary_key}_before_last_save")].compact.uniq
      query = klass.where({ reflection.foreign_key => ids })
  
      case options[:dependent]
      when nil
        query.update_all({ cache_column => timestamp })
        traverse_relationships(klass, options[:cached_at], query, cache_column, timestamp)
      when :destroy
        # don't need to worry about :destroy, that will touch the other caches
      when :delete, :nullify
        traverse_relationships(klass, options[:cached_at], query, cache_column, timestamp)
      end
      
      if loaded? && target
        target.instance_variable_get(:@attributes).write_cast_value(cache_column, timestamp)
        target.send(:clear_attribute_change, cache_column)
      end
    end
    
  end
end

ActiveRecord::Associations::HasOneAssociation.prepend(CachedAt::HasOneAssociation)