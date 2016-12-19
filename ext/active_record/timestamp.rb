module ActiveRecord
  module Timestamp
  private
    def timestamp_attributes_for_update
      [:updated_at, :updated_on, :cached_at]
    end

    def timestamp_attributes_for_create
      [:created_at, :created_on, :cached_at] + self.class.column_names.select{|c| c.end_with?('_cached_at') }.map(&:to_sym)
    end
  end
end