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
require File.expand_path(File.join(__FILE__, '../../active_record/cached_at/associations/has_many_through_association'))


require File.expand_path(File.join(__FILE__, '../../../ext/active_record/associations/has_many_association'))
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

      after_commit      :cleanup
      after_rollback    :cleanup
    end
    
    class_methods do
    end
    
    private
      
    def cleanup
      Thread.current[:cached_at_timestamp] = nil
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
      Thread.current[:cached_at_timestamp] = timestamp if method == :destroy

      self._reflections.each do |name, reflection|
        association(name.to_sym).touch_cached_at(timestamp)
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