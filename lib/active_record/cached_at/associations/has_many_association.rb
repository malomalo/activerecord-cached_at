module ActiveRecord::CachedAt
  module HasManyAssociation

    private

    def delete_count(method, scope)
      if method == :delete_all
        scope.delete_all
      else
        updates = {reflection.foreign_key => nil}
        if reflection.options[:cached_at]
          cache_column = "#{reflection.inverse_of.name}_cached_at"
          updates[cache_column] = Time.now
        end
        scope.update_all(updates)
      end
    end

  end
end

ActiveRecord::Associations::HasManyAssociation.prepend(ActiveRecord::CachedAt::HasManyAssociation)