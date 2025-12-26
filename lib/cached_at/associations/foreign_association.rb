# frozen_string_literal: tru

module CachedAt
  module ForeignAssociation # :nodoc:

    def nullified_owner_attributes
      Hash.new.tap do |attrs|
        Array(reflection.foreign_key).each { |foreign_key| attrs[foreign_key] = nil }
        attrs[reflection.type] = nil if reflection.type.present?
        attrs["#{reflection.inverse_of.name}_cached_at"] = Time.now if reflection.options[:cached_at]
      end
    end

  end
end

ActiveRecord::Associations::HasOneAssociation.prepend(CachedAt::ForeignAssociation)