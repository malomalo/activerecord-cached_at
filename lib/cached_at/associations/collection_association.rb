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

    def add_to_target(record, skip_callbacks = false, &block)
      value = super
      touch_records_cached_at([record], Time.now) if !(instance_variable_defined?(:@caching) && @caching)
      value
    end
    
    def replace_records(new_target, original_target)
      @caching = true
      changed_records = (target - new_target) | (new_target - target)
      value = super
      touch_records_cached_at(changed_records, Time.now) unless owner.new_record?
      value
    ensure
      @caching = false
    end

    def delete_all(dependent = nil)
      touch_cached_at(Time.now, :destroy)
      super
    end
    
  end
end

ActiveRecord::Associations::CollectionAssociation.prepend(CachedAt::CollectionAssociation)