module CachedAt
  module BelongsToAssociation
  
    def touch_cached_at(timestamp, method)
      return unless options[:cached_at]

      if !options[:inverse_of]
        puts "WARNING: cannot updated cached at for relationship: #{owner.class.name}.#{name}, inverse_of not set"
        return
      end
      
      types = {}

      cache_column = "#{options[:inverse_of]}_cached_at"
      if options[:polymorphic]
        oldtype = owner.send("#{reflection.foreign_type}_before_last_save")
        oldid = owner.send("#{reflection.foreign_key}_before_last_save")
        newtype = owner.send(reflection.foreign_type)
        newid = owner.send(reflection.foreign_key)
        if !oldtype.nil? && oldtype == newtype
          model_klass = oldtype.constantize
          query = model_klass.where({ (options[:primary_key] || 'id') => [oldid, newid] })
          query.update_all({ cache_column => timestamp })
          traverse_relationships(model_klass, options[:cached_at], query, cache_column, timestamp)
        else
          if oldtype
            model_klass = oldtype.constantize
            query = model_klass.where({ (options[:primary_key] || 'id') => oldid })
            query.update_all({ cache_column => timestamp })
            traverse_relationships(model_klass, options[:cached_at], query, cache_column, timestamp)
          end
          
          if newtype
            model_klass = newtype.constantize
            query = model_klass.where({ (options[:primary_key] || 'id') => newid })
            query.update_all({ cache_column => timestamp })
            traverse_relationships(model_klass, options[:cached_at], query, cache_column, timestamp)
          end
        end
      else
        ids = [owner.send(reflection.foreign_key), owner.send("#{reflection.foreign_key}_before_last_save")].compact.uniq
        query = klass.where({ reflection.association_primary_key => ids })
        query.update_all({ cache_column => timestamp })
        traverse_relationships(klass, options[:cached_at], query, cache_column, timestamp)
      end
      
      if loaded? && target
        target.send(:write_attribute_without_type_cast, cache_column, timestamp)
      end
    end
    
    def replace(record)
      if options[:cached_at] && options[:inverse_of]
        timestamp = Time.now
        cache_column = "#{options[:inverse_of]}_cached_at"
        if loaded? && target
          target.send(:write_attribute_without_type_cast, cache_column, timestamp)
        end
      end
      
      super
    end
    
  end
end

ActiveRecord::Associations::BelongsToAssociation.prepend(CachedAt::BelongsToAssociation)