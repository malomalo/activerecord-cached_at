require 'byebug'
require 'active_record'

require File.expand_path(File.join(__FILE__, '../../../ext/active_record/timestamp'))
require File.expand_path(File.join(__FILE__, '../../../ext/active_record/connection_adapters/abstract/schema_definitions'))
require File.expand_path(File.join(__FILE__, '../../../ext/active_record/connection_adapters/abstract/schema_statements'))

module ActiveRecord
  module CachedAt
    extend ActiveSupport::Concern
    
    module AssociationExtension
      
      def self.build(model, reflection)
        return unless reflection.options[:cached_at]


        
      end
  
      def self.valid_options
        [:cached_at]
      end
      
    end
    
    included do
      after_touch   :update_relations_cached_at_from_cached_at
      after_save    :update_relations_cached_at_from_cached_at
      after_destroy :update_relations_cached_at
    end
    
    class_methods do
    end
    
    private
      
      def update_relations_cached_at_from_cached_at
        update_relations_cached_at(timestamp: self.class.column_names.include?('cached_at') ? cached_at : nil)
      end
      
      def update_relations_cached_at(timestamp: nil)
        timestamp ||= current_time_from_proper_timezone
        
        self.class.reflect_on_all_associations.each do |reflection|
          
          case reflection
          when ActiveRecord::Reflection::BelongsToReflection
            reflection.touch_cached_at(self, timestamp)
          when ActiveRecord::Reflection::HasManyReflection
            reflection.touch_cached_at(self, timestamp)
          when ActiveRecord::Reflection::ThroughReflection

          end
        end
      end
      
  end
end

ActiveRecord::Associations::Builder::Association.extensions << ActiveRecord::CachedAt::AssociationExtension
ActiveRecord::Base.include(ActiveRecord::CachedAt)

class ActiveRecord::Reflection::AbstractReflection
  
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

class ActiveRecord::Reflection::BelongsToReflection
  def touch_cached_at(owner, timestamp)
    return unless options[:cached_at]
    
    if inverse_of.nil?
      puts "WARNING: cannot updated cached at for relationship: #{owner.class.name}.#{name}, inverse_of not set"
      return
    end
    
    cache_column = "#{inverse_of.name}_cached_at"
    ids = [owner.send(foreign_key), owner.send("#{foreign_key}_was")].compact.uniq
    query = klass.where({ association_primary_key => ids })
    query.update_all({ cache_column => timestamp })

    traverse_relationships(klass, options[:cached_at], query, cache_column, timestamp)
  end
end

class ActiveRecord::Reflection::HasManyReflection
  def touch_cached_at(owner, timestamp)
    return unless options[:cached_at]
    
    if inverse_of.nil?
      puts "WARNING: cannot updated cached at for relationship: #{owner.class.name}.#{name}, inverse_of not set"
      return
    end
    
    cache_column = "#{inverse_of.name}_cached_at"
    ids = [owner.send(association_primary_key), owner.send("#{association_primary_key}_was")].compact.uniq
    query = klass.where({ foreign_key => ids })
    
    case options[:dependent]
    when nil
      query.update_all({ cache_column => timestamp })
    when :destroy, :delete_all, :nullify
    end
    
    traverse_relationships(klass, options[:cached_at], query, cache_column, timestamp)
    
  end
end