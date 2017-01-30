module CachedAt
  module HasManyAssociation
  
    def replace_records(new_target, original_target)
      @caching = true
      
      timestamp = owner.cached_at || Time.now
      added_records = new_target - target
      removed_records = target - new_target
      touched_records = added_records + removed_records
      
      # case options[:dependent]
      # when :delete_all
      # else
      #   klass.where({ klass.primary_key => touched_records.map(&:id) }).update_all({
      #     cache_column => timestamp
      #   })
      # end

      value = super
      
      # case options[:dependent]
      # when :delete_all
      #   if added_records.size > 0
      #     klass.where({ klass.primary_key => added_records.map(&:id) }).update_all({
      #       cache_column => timestamp
      #     })
      #   end
      # else
        # if added_records.size > 0
        #   klass.where({ klass.primary_key => added_records.map(&:id) }).update_all({
        #     cache_column => timestamp
        #   })
        # end
      # end
      

        # added_records.each { |r| r.raw_write_attribute(cache_column, timestamp) }
        # removed_records.each { |r| r.raw_write_attribute(cache_column, timestamp) unless r.destroyed? }

      
      value
    ensure
      @caching = false
    end
    
    def insert_record(record, validate = true, raise = false)
      record[cache_column] = owner.cached_at
      super
    end

  end
end

ActiveRecord::Associations::HasManyAssociation.prepend(CachedAt::HasManyAssociation)