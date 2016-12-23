require 'byebug'
require 'active_record'

require File.expand_path(File.join(__FILE__, '../../../ext/active_record/timestamp'))

require File.expand_path(File.join(__FILE__, '../../active_record/cached_at/reflection/abstract_reflection'))
require File.expand_path(File.join(__FILE__, '../../active_record/cached_at/reflection/belongs_to_reflection'))
require File.expand_path(File.join(__FILE__, '../../active_record/cached_at/reflection/has_and_belongs_to_many_reflection'))
require File.expand_path(File.join(__FILE__, '../../active_record/cached_at/reflection/has_many_reflection'))
require File.expand_path(File.join(__FILE__, '../../active_record/cached_at/reflection/has_one_reflection'))
require File.expand_path(File.join(__FILE__, '../../active_record/cached_at/reflection/through_reflection'))

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

      self.class.reflect_on_all_associations.each do |reflection|
        # puts [self.class.name, reflection.name, reflection.class.name].inspect
        case reflection
        when ActiveRecord::Reflection::BelongsToReflection
          reflection.touch_cached_at(self, timestamp)
        when ActiveRecord::Reflection::HasManyReflection
          reflection.touch_cached_at(self, timestamp)
        when ActiveRecord::Reflection::HasOneReflection
          reflection.touch_cached_at(self, timestamp)
        when ActiveRecord::Reflection::HasAndBelongsToManyReflection
          reflection.touch_cached_at(self, timestamp)
        when ActiveRecord::Reflection::ThroughReflection
          reflection.touch_cached_at(self, timestamp)
        end
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
          
          # if self.send("#{assoc.name}_id_was") && self.send("#{assoc.name}_id_was") != self.send("#{assoc.name}_id")
          #   assoc_klass = if assoc.options[:polymorphic]
          #     self.send("#{assoc.name}_type_was").constantize
          #   else
          #     assoc.klass
          #   end
          #
          #           other_id = assoc_klass.find(self.send("#{assoc.name}_id_was"))
          #
          #           inverse_assoc = if assoc.options[:polymorphic]
          #             assoc_klass.reflect_on_association(assoc.options[:inverse_of])
          #           else
          #             assoc.inverse_of
          #           end
          #           inverse_assoc.options[:cached_at_updates].try(:call, other_id, timestamp)
          #         end
          #         if self.send(assoc.name)
          #           @_update_belongs_to ||= []
          #           @_update_belongs_to << assoc
          #         end

        end
      end
    end
    
  end
end

ActiveRecord::Associations::Builder::Association.extensions << ActiveRecord::CachedAt::AssociationExtension
ActiveRecord::Base.include(ActiveRecord::CachedAt)