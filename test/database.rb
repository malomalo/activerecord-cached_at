ActiveRecord::Base.establish_connection(
    :adapter => "sqlite3",
    :database  => ":memory:"
)

ActiveRecord::Migration.suppress_messages do
  ActiveRecord::Schema.define do

    create_table "accounts", force: :cascade do |t|
      t.string   "name",                 limit: 255
      t.integer  'photos_count', null: false, default: 0
      t.datetime 'cached_at', null: false
    end
    
    create_table "photos", force: :cascade do |t|
      t.integer  "account_id"
      t.string   "format",                 limit: 255
    end

    create_table "regions", force: :cascade do |t|
    end
    
  end
end

class Account < ActiveRecord::Base
  
  has_many :photos
  
end

class Photo < ActiveRecord::Base
  
  belongs_to :account, :counter_cache => true

end

class Region < ActiveRecord::Base
  
end

class Mountain < ActiveRecord::Base
end