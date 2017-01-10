module CachedAt
  module HasManyThroughAssociation
  
    def touch_cached_at(timestamp, method)
      using_reflection = reflection.parent_reflection || reflection
      
      if using_reflection.options[:cached_at]
        return if method == :create && !using_reflection.is_a?(ActiveRecord::Reflection::HasAndBelongsToManyReflection)

        if using_reflection.inverse_of.nil?
          puts "WARNING: cannot updated cached at for relationship: #{owner.class.name}.#{using_reflection.name}, inverse_of not set"
          return
        end
        cache_column = "#{using_reflection.inverse_of.name}_cached_at"

        query = nil
        if loaded?
          target.each { |r| r.raw_write_attribute(cache_column, timestamp) }
          query = klass.where(klass.primary_key => target.map(&:id))
        else
          ids = [owner.send(using_reflection.association_primary_key), owner.send("#{using_reflection.association_primary_key}_was")].compact.uniq
          arel_table = klass._reflections[using_reflection.inverse_of.options[:through].to_s].klass.arel_table
          query = klass.joins(using_reflection.inverse_of.options[:through])
          query = if using_reflection.is_a?(ActiveRecord::Reflection::HasAndBelongsToManyReflection)
            query.where(arel_table[using_reflection.foreign_key].in(ids))
          else
            query.where(arel_table[using_reflection.inverse_of.foreign_key].in(ids))
          end
        end
        
        query.update_all({ cache_column => timestamp })
        traverse_relationships(klass, options[:cached_at], query, cache_column, timestamp)
      end

      if using_reflection.inverse_of && using_reflection.inverse_of.options[:cached_at]
        cache_column = "#{using_reflection.name}_cached_at"
        owner.raw_write_attribute(cache_column, timestamp)
        #TODO: test with new record (fails in mls)
        owner.update_columns(cache_column => timestamp) unless owner.new_record?
      end
    end
    
    def touch_records_cached_at(records, timestamp)
      using_reflection = reflection.parent_reflection || reflection
      
      if using_reflection.options[:cached_at]
        if using_reflection.inverse_of.nil?
          puts "WARNING: cannot updated cached at for relationship: #{klass.name}.#{name}, inverse_of not set"
          return
        end

        cache_column = "#{using_reflection.inverse_of.name}_cached_at"
        records.each { |r| r.raw_write_attribute(cache_column, timestamp) }
        query = klass.where(klass.primary_key => records.map(&:id))
        query.update_all({ cache_column => timestamp })
        traverse_relationships(klass, using_reflection.options[:cached_at], query, cache_column, timestamp)
      end
      
      if using_reflection.inverse_of&.options.try(:[], :cached_at) || using_reflection.inverse_of&.parent_reflection&.options.try(:[], :cached_at)
        cache_column = "#{using_reflection.name}_cached_at"
        owner.update_column(cache_column, timestamp) unless owner.new_record?
      end
    end

  end
end

ActiveRecord::Associations::HasManyThroughAssociation.prepend(CachedAt::HasManyThroughAssociation)