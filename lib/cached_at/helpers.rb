module CachedAt
  module Base
    module Helpers
      extend ActiveSupport::Concern
    
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

      def cache_key(includes = nil)
        if includes.nil? || includes.empty?
          if cache_versioning
            "#{model_name.cache_key}/#{id}"
          else
            "#{model_name.cache_key}/#{id}@#{cache_version}"
          end
        else
          digest = Digest::MD5.hexdigest(paramaterize_cache_includes(includes))
          if cache_versioning
            "#{model_name.cache_key}/#{id}+#{digest}"
          else
            "#{model_name.cache_key}/#{id}+#{digest}@#{cache_version(includes)}"
          end
        end
      end

      def cache_version(includes = nil)
        timestamp = if includes.nil? || includes.empty?
          try(:cached_at) || try(:cached_at)
        else
          timestamp_keys = ['cached_at'] + self.class.cached_at_columns_for_includes(includes)
          timestamp = max_updated_column_timestamp(timestamp_keys)
        end
        
        timestamp.utc.to_s(:usec)
      end

      # TODO
      # def association_cache_key(association_name, includes = nil)
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

    end
  end
end

ActiveRecord::Base.include(CachedAt::Base::Helpers)