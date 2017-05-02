module CachedAt
  module CollectionProxy

    def <<(*records)
      puts proxy_association.owner.instance_variable_get(:@_already_called).has_key?("autosave_associated_records_for_#{proxy_association.reflection.name}".to_sym)
      if proxy_association.owner.persisted?
        if proxy_association.reflection.parent_reflection.is_a?(ActiveRecord::Reflection::HasAndBelongsToManyReflection)
          timestamp = Time.now
          if proxy_association.reflection.parent_reflection.options[:cached_at]
            cache_column = "#{proxy_association.reflection.parent_reflection.inverse_of.name}_cached_at"
            records.each { |r| r.raw_write_attribute(cache_column, timestamp) }
            rklass = proxy_association.reflection.parent_reflection.klass
            query = rklass.where(rklass.primary_key => records.map(&:id))
            query.update_all({ cache_column => timestamp })
            # proxy_association.owner.update_column(cache_column, timestamp) if proxy_association.owner.persisted?
          end
        elsif proxy_association.reflection.is_a?(ActiveRecord::Reflection::ThroughReflection)
          if proxy_association.reflection.inverse_of.options[:cached_at]
            cache_column = "#{proxy_association.reflection.name}_cached_at"
            timestamp = Time.now
            proxy_association.owner.raw_write_attribute(cache_column, timestamp)
            proxy_association.owner.update_column(cache_column, timestamp)
          end
        end
      end
      
      super
    end
    
    def delete(*records)
      if proxy_association.owner.persisted?
        if proxy_association.reflection.parent_reflection.is_a?(ActiveRecord::Reflection::HasAndBelongsToManyReflection)
          timestamp = Time.now
          if proxy_association.reflection.parent_reflection.options[:cached_at]
            cache_column = "#{proxy_association.reflection.parent_reflection.inverse_of.name}_cached_at"
            records.each { |r| r.raw_write_attribute(cache_column, timestamp) }
            rklass = proxy_association.reflection.parent_reflection.klass
            query = rklass.where(rklass.primary_key => records.map(&:id))
            query.update_all({ cache_column => timestamp })
          end
        end
      end

      super
    end

  end
end

ActiveRecord::Associations::CollectionProxy.prepend(CachedAt::CollectionProxy)