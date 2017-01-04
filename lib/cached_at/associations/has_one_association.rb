module CachedAt
  module HasOneAssociation
  
    def touch_cached_at(timestamp, method)
      return unless options[:cached_at]
      
      if reflection.inverse_of.nil?
        puts "WARNING: cannot updated cached at for relationship: #{owner.class.name}.#{name}, inverse_of not set"
        return
      end
  
      cache_column = "#{reflection.inverse_of.name}_cached_at"
      ids = [owner.send(reflection.association_primary_key), owner.send("#{reflection.association_primary_key}_was")].compact.uniq
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
        target.raw_write_attribute(cache_column, timestamp)
      end
    end
    
    def delete(method = options[:dependent])
      if load_target
        case method
        when :delete
          target.delete
        when :destroy
          target.destroy
        when :nullify
          updates = {reflection.foreign_key => nil}
          if reflection.options[:cached_at]
            cache_column = "#{reflection.inverse_of.name}_cached_at"
            updates[cache_column] = Time.now
          end
          target.update_columns(updates) if target.persisted?
        end
      end
    end
    
  end
end

ActiveRecord::Associations::HasOneAssociation.prepend(CachedAt::HasOneAssociation)