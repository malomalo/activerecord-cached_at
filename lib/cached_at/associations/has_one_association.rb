module CachedAt
  module HasOneAssociation
  
    def touch_cached_at(timestamp, method)
      return unless options[:cached_at]
      
      if reflection.inverse_of.nil?
        puts "WARNING: cannot updated cached at for relationship: #{owner.class.name}.#{name}, inverse_of not set"
        return
      end
  
      cache_column = "#{reflection.inverse_of.name}_cached_at"
      ids = [owner.send(reflection.association_primary_key), owner.send("#{reflection.association_primary_key}_was")].compact.uniq
      query = klass.where({ reflection.foreign_key => ids })
  
      if method == :destroy
        case options[:dependent]
        when nil
          query.update_all({ cache_column => timestamp })
          traverse_relationships(klass, options[:cached_at], query, cache_column, timestamp)
        when :destroy
          # don't need to worry about :destroy, that will touch the other caches
        when :delete, :nullify
          traverse_relationships(klass, options[:cached_at], query, cache_column, timestamp)
        end
      else
        query.update_all({ cache_column => timestamp })
        traverse_relationships(klass, options[:cached_at], query, cache_column, timestamp)
      end
      
      if loaded? && target
        target.raw_write_attribute(cache_column, timestamp)
      end
    end
    
    def delete(method = options[:dependent])
      if load_target
        case method
        when :delete
          target.delete
        when :destroy
          target.destroy
        when :nullify
          updates = {reflection.foreign_key => nil}
          if reflection.options[:cached_at]
            cache_column = "#{reflection.inverse_of.name}_cached_at"
            updates[cache_column] = Time.now
          end
          target.update_columns(updates) if target.persisted?
        end
      end
    end
    
    def replace(record, save = true)
      raise_on_type_mismatch!(record) if record
      load_target

      return self.target if !(target || record)

      assigning_another_record = target != record
      if assigning_another_record || record.changed?
        save &&= owner.persisted?

        transaction_if(save) do
          remove_target!(options[:dependent]) if target && !target.destroyed? && assigning_another_record

          if record
            set_owner_attributes(record)
            set_inverse_instance(record)

            if save && !record.save
              nullify_owner_attributes(record)
              set_owner_attributes(target) if target
              raise RecordNotSaved, "Failed to save the new associated #{reflection.name}."
            end
          end
        end
      end

      self.target = record
    end

    
    def owner_destroyed(timestamp)
      klass.where(reflection.foreign_key => owner.send(reflection.association_primary_key)).update_all({
        cache_column => timestamp
      })
      
      if loaded? && target
        target.raw_write_attribute(cache_column, timestamp)
      end
    end
    
    private
    
    def remove_target!(method)
      case method
        when :delete
          target.delete
        when :destroy
          target.destroy
        else
          nullify_owner_attributes(target)
          
          if target.persisted? && owner.persisted? && !target.save
            set_owner_attributes(target)
            raise RecordNotSaved, "Failed to remove the existing associated #{reflection.name}. " +
                                  "The record failed to save after its foreign key was set to nil."
          end
      end
    end
    
    def nullify_owner_attributes(record)
      record[reflection.foreign_key] = nil
      record["#{reflection.inverse_of.name}_cached_at"] = Time.now
    end
    
  end
end

ActiveRecord::Associations::HasOneAssociation.prepend(CachedAt::HasOneAssociation)