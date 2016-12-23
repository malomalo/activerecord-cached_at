module ActiveRecord
  module Associations
    class HasManyAssociation
      
      private
      
      def delete_count(method, scope)
        if method == :delete_all
          scope.delete_all
        else
          updates = {reflection.foreign_key => nil}
          if reflection.options[:cached_at]
            cache_column = "#{reflection.inverse_of.name}_cached_at"
            updates[cache_column] = Thread.current[:cached_at_timestamp]
          end
          scope.update_all(updates)
        end
      end
    end
    
    class HasManyThroughAssociation

      # def delete_records(records, method)
      #   ensure_not_nested
      #
      #   scope = through_association.scope
      #   scope.where! construct_join_attributes(*records)
      #
      #   case method
      #   when :destroy
      #     if scope.klass.primary_key
      #       count = scope.destroy_all.length
      #     else
      #       scope.each(&:_run_destroy_callbacks)
      #
      #       arel = scope.arel
      #
      #       stmt = Arel::DeleteManager.new
      #       stmt.from scope.klass.arel_table
      #       stmt.wheres = arel.constraints
      #
      #       count = scope.klass.connection.delete(stmt, "SQL", scope.bound_attributes)
      #     end
      #   when :nullify
      #     count = scope.update_all(source_reflection.foreign_key => nil)
      #   else
      #     count = scope.delete_all
      #   end
      #
      #   delete_through_records(records)
      #
      #   if source_reflection.options[:counter_cache] && method != :destroy
      #     counter = source_reflection.counter_cache_column
      #     klass.decrement_counter counter, records.map(&:id)
      #   end
      #
      #   if through_reflection.collection? && update_through_counter?(method)
      #     update_counter(-count, through_reflection)
      #   else
      #     update_counter(-count)
      #   end
      # end
      
    end
    
  end
end

module A
  # def delete_records(records, method)
  #   puts method
  #   super
  # end
  
  def concat_records(records, should_raise = false)
    value = super
    
    if reflection.is_a?(ActiveRecord::Reflection::ThroughReflection)
      if reflection.parent_reflection.is_a?(ActiveRecord::Reflection::HasAndBelongsToManyReflection)
        reflection.parent_reflection.touch_records_added_cached_at(owner, records, Time.now)
      elsif reflection.is_a?(ActiveRecord::Reflection::ThroughReflection)
        if !owner.new_record?

          reflection.inverse_of&.touch_records_added_cached_at(owner, records, Time.now)
        end
      else
        # puts reflection.inspect
      end
    end
    
    value
  end
  
  def remove_records(existing_records, records, method)
    if reflection.parent_reflection.is_a?(ActiveRecord::Reflection::HasAndBelongsToManyReflection)
      reflection.parent_reflection.touch_records_added_cached_at(owner, existing_records, Time.now)
    elsif reflection.is_a?(ActiveRecord::Reflection::ThroughReflection)
      if !owner.new_record?
        reflection.inverse_of&.touch_records_added_cached_at(owner, records, Time.now)
      end
    else
      # puts reflection.inspect
    end
    
    super
  end
  
  def delete_all(dependent = nil)
    if reflection.parent_reflection.is_a?(ActiveRecord::Reflection::HasAndBelongsToManyReflection)
      reflection.parent_reflection.touch_cached_at(owner, Time.now)
    end
    
    super
  end
  
end
ActiveRecord::Associations::HasManyThroughAssociation.include(A)