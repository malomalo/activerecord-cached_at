require 'byebug'
require 'active_record'

require File.expand_path(File.join(__FILE__, '../../../ext/active_record/timestamp'))

#   Association
#     SingularAssociation
#       HasOneAssociation + ForeignAssociation
#         HasOneThroughAssociation + ThroughAssociation
#       BelongsToAssociation
#         BelongsToPolymorphicAssociation
#     CollectionAssociation
#       HasManyAssociation + ForeignAssociation
#         HasManyThroughAssociation + ThroughAssociation
require File.expand_path(File.join(__FILE__, '../../active_record/cached_at/associations/association'))
require File.expand_path(File.join(__FILE__, '../../active_record/cached_at/associations/has_one_association'))
require File.expand_path(File.join(__FILE__, '../../active_record/cached_at/associations/belongs_to_association'))
require File.expand_path(File.join(__FILE__, '../../active_record/cached_at/associations/collection_association'))
require File.expand_path(File.join(__FILE__, '../../active_record/cached_at/associations/has_many_association'))
require File.expand_path(File.join(__FILE__, '../../active_record/cached_at/associations/has_many_through_association'))


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
      before_save       :update_belongs_to_cached_at_keys
      before_destroy    { update_relations_cached_at(method: :destroy) }
      after_touch       { update_relations_cached_at_from_cached_at(method: :touch) }

      after_save     :update_relations_cached_at_from_cached_at
    end
    
    class_methods do

      def can_cache?(includes)
        cache_columns = ['cached_at'] + cached_at_columns_for_includes(includes)

        (cache_columns - column_names).empty?
      end

      def cached_at_columns_for_includes(includes, prefix=nil)
        if includes.is_a?(Array)
          includes.inject([]) { |s, k| s + cached_at_columns_for_includes(k, prefix) }
        elsif includes.is_a?(Hash)
          includes.map { |k, v|
            value = ["#{prefix}#{k}_cached_at"]
            if v != true
              value << cached_at_columns_for_includes(v, "#{prefix}#{k}_")
            end
            value
          }.flatten
        else
          ["#{prefix}#{includes}_cached_at"]
        end
      end

    end

    def cache_key_including(includes = nil)
      if includes.nil? || includes.empty?
        cache_key
      else
        timestamp_keys = ['cached_at'] + self.class.cached_at_columns_for_includes(includes)
        timestamp = max_updated_column_timestamp(timestamp_keys).utc.to_s(cache_timestamp_format)
        digest ||= Digest::MD5.new()
        digest << paramaterize_cache_includes(includes)
        "#{model_name.cache_key}/#{id}+#{digest.hexdigest}@#{timestamp}"
      end
    end
    #
    # def cache_key_for_association(association_name)
    # end
    
    private

    def paramaterize_cache_includes(includes, paramaterized_cache_key = nil)
      paramaterized_cache_key ||= ""

      if includes.is_a?(Hash)
        includes.keys.sort.each_with_index do |key, i|
          paramaterized_cache_key << ',' unless i == 0
          paramaterized_cache_key << key.to_s
          if includes[key].is_a?(Hash) || includes[key].is_a?(Array)
            paramaterized_cache_key << "["
            paramaterize_cache_includes(includes[key], paramaterized_cache_key)
            paramaterized_cache_key << "]"
          elsif includes[key] != true
            paramaterized_cache_key << "["
            paramaterized_cache_key << includes[key].to_s
            paramaterized_cache_key << "]"
          end
        end
      elsif includes.is_a?(Array)
        includes.sort.each_with_index do |value, i|
          paramaterized_cache_key << ',' unless i == 0
          if value.is_a?(Hash) || value.is_a?(Array)
            paramaterize_cache_includes(value, paramaterized_cache_key)
          else
            paramaterized_cache_key << value.to_s
          end
        end
      else
        paramaterized_cache_key << includes.to_s
      end

      paramaterized_cache_key
    end
    
    def update_relations_cached_at_from_cached_at(method: nil)
      update_relations_cached_at({
        timestamp: (self.class.column_names.include?('cached_at') ? cached_at : nil),
        method: method
      })
    end
    
    def update_relations_cached_at(timestamp: nil, method: nil)
      return if (method == nil && changes.empty?) && method != :destroy && method != :touch
      timestamp ||= current_time_from_proper_timezone

      self._reflections.each do |name, reflection|
        association(name.to_sym).touch_cached_at(timestamp, method)
      end
    end

    def update_belongs_to_cached_at_keys
      self.class.reflect_on_all_associations.each do |reflection|
        next unless reflection.is_a?(ActiveRecord::Reflection::BelongsToReflection)
        cache_column = "#{reflection.name}_cached_at"

        if self.attribute_names.include?(cache_column)
          if self.changes.has_key?(reflection.foreign_key) && self.changes[reflection.foreign_key][1].nil?
            self.assign_attributes({ cache_column => current_time_from_proper_timezone })
          elsif (self.changes[reflection.foreign_key] || self.new_record? || (self.association(reflection.name).loaded? && self.send(reflection.name) && self.send(reflection.name).id.nil?)) && self.send(reflection.name).try(:cached_at)
            self.assign_attributes({ cache_column => self.send(reflection.name).cached_at })
          end

        end
      end
    end
    
  end
end

ActiveRecord::Associations::Builder::Association.extensions << ActiveRecord::CachedAt::AssociationExtension
ActiveRecord::Base.include(ActiveRecord::CachedAt)