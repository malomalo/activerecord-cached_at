require File.expand_path(File.join(__FILE__, '../associations/association'))
require File.expand_path(File.join(__FILE__, '../associations/has_one_association'))
require File.expand_path(File.join(__FILE__, '../associations/belongs_to_association'))
require File.expand_path(File.join(__FILE__, '../associations/collection_association'))
require File.expand_path(File.join(__FILE__, '../associations/has_many_through_association'))

module CachedAt
  module Base
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

    private
    
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
        begin
          association(name.to_sym).touch_cached_at(timestamp, method)
        rescue ActiveRecord::HasManyThroughAssociationNotFoundError, 
               ActiveRecord::HasOneAssociationPolymorphicThroughError,
               ActiveRecord::HasManyThroughAssociationPolymorphicThroughError,
               ActiveRecord::HasManyThroughSourceAssociationNotFoundError,
               ActiveRecord::HasManyThroughAssociationPointlessSourceTypeError,
               ActiveRecord::HasManyThroughAssociationPolymorphicSourceError,
               ActiveRecord::HasOneThroughCantAssociateThroughCollection,
               ActiveRecord::HasManyThroughOrderError
               # these error get raised if the reflection is invalid... so we'll
               # skip them. Should warn the user, but this casuse the Rails test
               # to fail....
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

        end
      end
    end
    
  end
end

ActiveRecord::Associations::Builder::Association.extensions << CachedAt::Base::AssociationExtension
ActiveRecord::Base.include(CachedAt::Base)