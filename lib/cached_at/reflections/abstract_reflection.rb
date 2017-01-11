module CachedAt
  module AbstractReflection
  
    def cache_through_relationship_endpoints
      if defined?(Rails)
        Rails.application.config.cache_classes
      else
        true
      end
    end
    
    def through_relationship_endpoints
      return @through_relationship_endpoints if instance_variable_defined?(:@through_relationship_endpoints) && cache_through_relationship_endpoints

      @through_relationship_endpoints = if defined?(Rails)
        Rails.application.reloader.wrap { calculate_through_relationship_endpoints }
      else
        calculate_through_relationship_endpoints
      end

      @through_relationship_endpoints
    end
  
    def calculate_through_relationship_endpoints
      endpoints = []
      
      if self.polymorphic?
      else
        self.klass._reflections.each do |name, r|
          if r.options[:cached_at] && r.options[:through] && r.options[:through] == self.inverse_of&.name
            endpoints << r
          end
        end
      end

      endpoints
    end
    
  end
end

ActiveRecord::Reflection::AbstractReflection.include(CachedAt::AbstractReflection)
