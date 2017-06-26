module CachedAt
  module CollectionProxy
    def delete(*records)
      @association.touch_records_cached_at(records, Time.now) unless @association.owner.new_record?
      super
    end
  end
end

ActiveRecord::Associations::CollectionProxy.prepend(CachedAt::CollectionProxy)