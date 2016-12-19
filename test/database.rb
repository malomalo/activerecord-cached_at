ActiveRecord::Base.establish_connection(
    :adapter => "sqlite3",
    :database  => ":memory:"
)

ActiveRecord::Migration.suppress_messages do
  ActiveRecord::Schema.define do

    create_table "organizations", force: :cascade do |t|
      t.string   "name",                limit: 255
      t.integer  'photos_count',        null: false, default: 0
      t.datetime 'cached_at',           null: false
      t.datetime 'accounts_cached_at',  null: false
    end
    
    create_table "accounts", force: :cascade do |t|
      t.integer  "organization_id"
      t.string   "name",                 limit: 255
      t.integer  'photos_count', null: false, default: 0
      t.datetime 'cached_at', null: false
      t.datetime 'organization_cached_at', null: false
    end
    
    create_table "photos", force: :cascade do |t|
      t.integer  "account_id"
      t.string   "format",                 limit: 255
    end

    create_table "regions", force: :cascade do |t|
    end
    
  end
end

class Organization < ActiveRecord::Base
  
  has_many :accounts, cached_at: true, inverse_of: :organization
  
end

class Account < ActiveRecord::Base
  
  has_many :photos
  belongs_to :organization, cached_at: true, inverse_of: :accounts
  
end

class Photo < ActiveRecord::Base
  
  belongs_to :account, counter_cache: true

end

class Region < ActiveRecord::Base
  
end

class Mountain < ActiveRecord::Base
end