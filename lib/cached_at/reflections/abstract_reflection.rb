module CachedAt
  module AbstractReflection
  
    def through_relationship_endpoints
      return @through_relationship_endpoints if instance_variable_defined?(:@through_relationship_endpoints)
    
      @through_relationship_endpoints = []
      active_record.reflections.each do |name, r|
        next if r == self
        begin
          if r.polymorphic?
            # TODO
          else
            r.klass.reflections.each do |name2, r2|
              if r2.options[:cached_at] && r2.options[:through] && r2.options[:through] == r.inverse_of&.name
                @through_relationship_endpoints << r2
              end
            end
          end
        rescue NameError
        end
      end
    
      @through_relationship_endpoints
    end
  
  end
end

ActiveRecord::Reflection::AbstractReflection.include(CachedAt::AbstractReflection)