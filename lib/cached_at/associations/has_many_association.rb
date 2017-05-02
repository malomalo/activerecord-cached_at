module CachedAt
  module HasManyAssociation
  
    def replace_records(new_target, original_target)
      timestamp = Time.now
      added_records = new_target - original_target
      removed_records = original_target - new_target
      touched_records = added_records + removed_records
      
      parent_reflection = reflection.parent_reflection
      if parent_reflection.is_a?(ActiveRecord::Reflection::HasAndBelongsToManyReflection)
        if parent_reflection.options[:cached_at]
          cache_column = "#{parent_reflection.inverse_of.name}_cached_at"
          
          klass.where({ klass.primary_key => touched_records.map(&:id) }).update_all({
            cache_column => timestamp
          })
          touched_records.each do |r|
            r.raw_write_attribute(cache_column, timestamp)
          end
        end
        
        if owner.persisted? && parent_reflection.inverse_of.parent_reflection.options[:cached_at]
          cache_column = "#{parent_reflection.name}_cached_at"
          owner.raw_write_attribute(cache_column, timestamp)
          owner.update_column(cache_column, timestamp)
        end
      elsif self.is_a?(ActiveRecord::Associations::HasManyThroughAssociation) && touched_records.size > 0
        if reflection.inverse_of.nil?
          puts "WARNING: cannot updated cached at for relationship: #{owner.class.name}.#{reflection.name}, inverse_of not set"
        elsif reflection.inverse_of.options[:cached_at] && owner.persisted?
          owner.update_column("#{reflection.name}_cached_at", timestamp)
        end
      end

      super
    end

  end
end

ActiveRecord::Associations::HasManyAssociation.prepend(CachedAt::HasManyAssociation)