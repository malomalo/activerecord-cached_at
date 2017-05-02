module CachedAt
  module CollectionAssociation
  
    def touch_cached_at(timestamp, method)
      return unless options[:cached_at]

      if reflection.inverse_of.nil?
        puts "WARNING: cannot updated cached at for relationship: #{owner.class.name}.#{name}, inverse_of not set"
        return
      end

      cache_column = "#{reflection.inverse_of.name}_cached_at"
      ids = [owner.send(reflection.association_primary_key), owner.send("#{reflection.association_primary_key}_was")].compact.uniq
      query = klass.where({ reflection.foreign_key => ids })
    
      if loaded?
        target.each { |r| r.raw_write_attribute(cache_column, timestamp) }
      end
      
      if method != :destroy
        query.update_all({ cache_column => timestamp })
        traverse_relationships(klass, options[:cached_at], query, cache_column, timestamp)
      else
        if options[:dependent].nil?
          query.update_all({ cache_column => timestamp })
          traverse_relationships(klass, options[:cached_at], query, cache_column, timestamp)
        else
          traverse_relationships(klass, options[:cached_at], query, cache_column, timestamp)
        end
      end
    end

    def touch_records_cached_at(records, timestamp)
      return unless options[:cached_at]

      if reflection.inverse_of.nil?
        puts "WARNING: cannot updated cached at for relationship: #{owner.class.name}.#{name}, inverse_of not set"
        return
      end

      cache_column = "#{reflection.inverse_of.name}_cached_at"

      records.each { |r| r.raw_write_attribute(cache_column, timestamp) unless r.destroyed? }

      query = klass.where({ klass.primary_key => records.map(&:id) })
      query.update_all({ cache_column => timestamp })
      traverse_relationships(klass, options[:cached_at], query, cache_column, timestamp)
    end

    def delete_all(dependent = nil)
      touch_cached_at(Time.now, :destroy)
      super
    end
    
    def owner_destroyed(timestamp)
      klass.where(reflection.foreign_key => owner.id).update_all({
        cache_column => timestamp
      })
      
      if loaded?
        target.each { |r| r.raw_write_attribute(cache_column, timestamp) }
      end
    end
    
  end
end

ActiveRecord::Associations::CollectionAssociation.prepend(CachedAt::CollectionAssociation)