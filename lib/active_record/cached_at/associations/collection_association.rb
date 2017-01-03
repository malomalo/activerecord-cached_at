module ActiveRecord::CachedAt
  module CollectionAssociation
  
    def touch_cached_at(timestamp)
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
    
      case options[:dependent]
      when nil
        query.update_all({ cache_column => timestamp })
        traverse_relationships(klass, options[:cached_at], query, cache_column, timestamp)
      when :destroy
        traverse_relationships(klass, options[:cached_at], query, cache_column, timestamp)
        # shouldn't need to to worry about :destroy, that will touch the other caches on destroy
      when :delete_all, :nullify
        traverse_relationships(klass, options[:cached_at], query, cache_column, timestamp)
      end
    end
    
    def touch_records_added_cached_at(records, timestamp)
      return if owner.new_record? || records.empty?
      
      if reflection.options[:cached_at]
        if reflection.inverse_of.nil?
          puts "WARNING: cannot updated cached at for relationship: #{klass.name}.#{name}, inverse_of not set"
          return
        end
        
        cache_column = "#{reflection.inverse_of.name}_cached_at"
        if loaded?
          target.each { |r| r.raw_write_attribute(cache_column, timestamp) }
        end
        
        ids = records.inject([]) { |a, o| a += [o.send(klass.primary_key), o.send("#{klass.primary_key}_was")] }.compact.uniq
        query = klass.where(klass.primary_key => ids)
        query.update_all({ cache_column => timestamp })
        traverse_relationships(klass, reflection.options[:cached_at], query, cache_column, timestamp)
      end
      
      # if using_reflection.inverse_of&.options.try(:[], :cached_at) || using_reflection.inverse_of&.parent_reflection&.options.try(:[], :cached_at)
      #   cache_column = "#{using_reflection.name}_cached_at"
      #   owner.update_column(cache_column, timestamp) unless owner.new_record?
      # end
    end
    
    def concat_records(records, should_raise = false)
      value = super
      touch_records_added_cached_at(records, Time.now)
      value
    end

    def remove_records(existing_records, records, method)
      touch_records_added_cached_at(existing_records, Time.now)
      super
    end

    def delete_all(dependent = nil)
      touch_cached_at(Time.now)
      super
    end
    
  end
end

ActiveRecord::Associations::CollectionAssociation.prepend(ActiveRecord::CachedAt::CollectionAssociation)