module ActiveRecord
  module Reflection
    
    class AbstractReflection
  
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
  
    end
    
  end
end