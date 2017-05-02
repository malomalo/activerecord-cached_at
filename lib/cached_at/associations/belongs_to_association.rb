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
        oldtype = owner.send("#{reflection.foreign_type}_was")
        oldid = owner.send("#{reflection.foreign_key}_was")
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
        ids = [owner.send(reflection.foreign_key), owner.send("#{reflection.foreign_key}_was")].compact.uniq
        query = klass.where({ reflection.association_primary_key => ids })
        query.update_all({ cache_column => timestamp })
        traverse_relationships(klass, options[:cached_at], query, cache_column, timestamp)
      end
      
      if loaded? && target
        target.raw_write_attribute(cache_column, timestamp)
      end
    end
    
    def replace(record)
      if options[:cached_at] && options[:inverse_of]
        timestamp = Time.now
        cache_column = "#{options[:inverse_of]}_cached_at"
        if loaded? && target
          target.raw_write_attribute(cache_column, timestamp)
        end
      end
      
      super
    end

    def owner_destroyed(timestamp)
      if options[:cached_at]
        if options[:polymorphic]
          model_klass = owner.send(reflection.foreign_type).constantize
          query = model_klass.where({ (options[:primary_key] || 'id') => owner.send(reflection.foreign_key) })
          query.update_all({ "#{options[:inverse_of]}_cached_at" => timestamp })
          if loaded? && target
            target.raw_write_attribute("#{options[:inverse_of]}_cached_at", timestamp)
          end
        else
          klass.where(reflection.association_primary_key => owner.send(reflection.foreign_key)).update_all({
            cache_column => timestamp
          })
          if loaded? && target
            target.raw_write_attribute(cache_column, timestamp)
          end
        end

      end
      
      if reflection.through_relationship_endpoints.size > 0 && owner.instance_variable_get(:@destroyed_by_association).nil?
        reflection.through_relationship_endpoints.each do |r|
          cache_column = "#{r.inverse_of.name}_cached_at"
          
          if loaded? && target && target.association(r.name.to_sym).loaded?
            target.association(r.name.to_sym).target.each do |t|
              t.raw_write_attribute(cache_column, timestamp)
            end
          end

          source_assoc = owner.association(r.source_reflection_name.to_sym)
          if source_assoc.loaded?
            source_assoc.target.raw_write_attribute(cache_column, timestamp)
          end
          query = r.klass.where(r.association_primary_key => owner.send(r.foreign_key))
          query.update_all({ cache_column => timestamp })

        end
      end
      
    end

  end
end

ActiveRecord::Associations::BelongsToAssociation.prepend(CachedAt::BelongsToAssociation)