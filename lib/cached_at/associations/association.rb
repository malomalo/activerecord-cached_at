module CachedAt
  module Association
    
    def traverse_relationships(klass, relationships, query, cache_column, timestamp)
      if relationships.is_a?(Symbol)
        reflection = klass.reflect_on_association(relationships)
        case reflection
        when ActiveRecord::Reflection::BelongsToReflection
          cache_column = "#{reflection.inverse_of.name}_#{cache_column}"
          reflection.klass.joins(reflection.inverse_of.name).merge(query).update_all({
            cache_column => timestamp
          })
        when ActiveRecord::Reflection::HasManyReflection
          cache_column = "#{reflection.inverse_of.name}_#{cache_column}"
          reflection.klass.joins(reflection.inverse_of.name).merge(query).update_all({
            cache_column => timestamp
          })
        when ActiveRecord::Reflection::HasAndBelongsToManyReflection
          query = reflection.klass.joins(reflection.inverse_of.name).merge(query)
          puts '!!!!!!!!!!!!!!!!!'
        when ActiveRecord::Reflection::ThroughReflection
          cache_column = "#{reflection.inverse_of.name}_#{cache_column}"
          reflection.klass.joins(reflection.inverse_of.name).merge(query).update_all({
            cache_column => timestamp
          })
        end
      elsif relationships.is_a?(Hash)
        relationships.each do |key, value|
          traverse_relationships(klass, key, query, cache_column, timestamp)
        end
      elsif relationships.is_a?(Array)
        relationships.each do |value|
          traverse_relationships(klass, value, query, cache_column, timestamp)
        end
      end
    end
    
    def touch_through_reflections(timestamp)
      reflection.through_relationship_endpoints.each do |r|
        cache_column = "#{r.inverse_of.name}_cached_at"
        
        source_assoc = owner.association(r.source_reflection_name.to_sym)
        if source_assoc.loaded?
          source_assoc.target.instance_variable_get(:@attributes).write_cast_value(cache_column, timestamp)
          source_assoc.target.send(:clear_attribute_change, cache_column)
        end
        query = r.klass.where(r.association_primary_key => owner.send(r.foreign_key))
        query.update_all({ cache_column => timestamp })
        traverse_relationships(r.klass, r.options[:cached_at], query, cache_column, timestamp)
      end
    end
    
  end
end

ActiveRecord::Associations::Association.include(CachedAt::Association)