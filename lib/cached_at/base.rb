require File.expand_path(File.join(__FILE__, '../association_extension'))
require File.expand_path(File.join(__FILE__, '../associations/association'))
require File.expand_path(File.join(__FILE__, '../associations/has_one_association'))
require File.expand_path(File.join(__FILE__, '../associations/belongs_to_association'))
require File.expand_path(File.join(__FILE__, '../associations/collection_association'))
require File.expand_path(File.join(__FILE__, '../associations/collection_proxy'))
require File.expand_path(File.join(__FILE__, '../associations/has_many_through_association'))

require File.expand_path(File.join(__FILE__, '../reflections/abstract_reflection'))

module CachedAt
  module Base
    extend ActiveSupport::Concern

    included do
      class_attribute   :cached_at_settings, default: {ignore: ['cached_at', 'updated_at', 'created_at']}
      before_save       :set_cached_at
      before_save       :update_belongs_to_cached_at_keys
      before_destroy    { update_relations_cached_at(method: :destroy) }

      after_touch       { update_relations_cached_at_from_cached_at(method: :touch) }
      after_save        :update_relations_cached_at_from_cached_at
    end

    class_methods do
      def cached_at(ignore: [])
        ignore = [ignore] if !ignore.is_a?(Array)
        self.cached_at_settings[:ignore].push(*ignore.map(&:to_s))
      end
    end

    def touch(*names, time: nil)
      names.push('cached_at')
      super(*names, time: time)
    end

    private
    
    def update_relations_cached_at_from_cached_at(method: nil)
      update_relations_cached_at(
        timestamp: (self.class.column_names.include?('cached_at') ? cached_at : nil),
        method: method
      )
    end
    
    def update_relations_cached_at(timestamp: nil, method: nil)
      method = @_new_record_before_last_commit ? :create : :update if method.nil?
      
      diff = saved_changes.transform_values(&:first)
      return if method == :create && diff.empty?
      return if method == :update && diff.empty?
      
      timestamp ||= current_time_from_proper_timezone

      self._reflections.each do |name, reflection|
        next unless reflection.options[:cached_at] || reflection&.parent_reflection&.class == ActiveRecord::Reflection::HasAndBelongsToManyReflection || !reflection.through_relationship_endpoints.empty?
        next if instance_variable_defined?(:@relationships_cached_at_touched) && (!@relationships_cached_at_touched.nil? && @relationships_cached_at_touched[reflection.name])
        next if reflection.is_a?(ActiveRecord::Reflection::HasManyReflection) && method == :create

        assoc = association(name.to_sym)
        assoc.touch_cached_at(timestamp, method)
        assoc.touch_through_reflections(timestamp)
      end
    end

    def set_cached_at
      return if !self.class.column_names.include?('cached_at')
      diff = changes.transform_values(&:first)
      return if diff.keys.all? { |k| cached_at_settings[:ignore].include?(k) }

      self.cached_at = current_time_from_proper_timezone
    end

    def update_belongs_to_cached_at_keys
      self.class.reflect_on_all_associations.each do |reflection|
        next unless reflection.is_a?(ActiveRecord::Reflection::BelongsToReflection)
        cache_column = "#{reflection.name}_cached_at"

        if self.attribute_names.include?(cache_column)
          if self.changes_to_save.has_key?(reflection.foreign_key) && self.changes_to_save[reflection.foreign_key][1].nil?
            self.assign_attributes({ cache_column => current_time_from_proper_timezone })
          elsif (self.changes_to_save[reflection.foreign_key] || self.new_record? || (self.association(reflection.name).loaded? && self.send(reflection.name) && self.send(reflection.name).id.nil?)) && self.send(reflection.name).try(:cached_at)
            self.assign_attributes({ cache_column => self.send(reflection.name).cached_at })
          end
        end
        
      end
    end

  end
end

ActiveRecord::Base.include(CachedAt::Base)