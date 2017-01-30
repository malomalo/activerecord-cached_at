module CachedAt
  module AssociationExtension

    def self.build(model, reflection)
    end
    
    def self.valid_options
      [:cached_at]
    end
      
  end
end

ActiveRecord::Associations::Builder::Association.extensions << CachedAt::AssociationExtension