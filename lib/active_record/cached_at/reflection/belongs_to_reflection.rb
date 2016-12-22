module ActiveRecord
  module Reflection
    
    class BelongsToReflection
      def touch_cached_at(owner, timestamp)
        return unless options[:cached_at]

        if !options[:inverse_of]
          puts "WARNING: cannot updated cached at for relationship: #{owner.class.name}.#{name}, inverse_of not set"
          return
        end
        
        types = {}

        cache_column = "#{options[:inverse_of]}_cached_at"
        if options[:polymorphic]
          oldtype = owner.send("#{foreign_type}_was")
          oldid = owner.send("#{foreign_key}_was")
          newtype = owner.send(foreign_type)
          newid = owner.send(foreign_key)
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
          ids = [owner.send(foreign_key), owner.send("#{foreign_key}_was")].compact.uniq
          query = klass.where({ association_primary_key => ids })
          query.update_all({ cache_column => timestamp })

          traverse_relationships(klass, options[:cached_at], query, cache_column, timestamp)
        end
      end
      
    end

  end
end