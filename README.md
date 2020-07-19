# ActiveRecord - CachedAt [![Travis CI](https://travis-ci.org/malomalo/activerecord-cached_at.svg?branch=master)](https://travis-ci.org/malomalo/activerecord-cached_at)

This gem causes ActiveRecord to update a `cached_at` column if present, like the
`updated_at` column.

When calculating a `cache_key` for a model it will also consider the `cached_at`
column to determine the key of a model.

Any `ActiveRecord::Migration` that calls `timestamps` will include a `cached_at`
column.

Call to [`ActiveRecord::Persistence::touch`](https://api.rubyonrails.org/classes/ActiveRecord/Persistence.html#method-i-touch)
will also touch the `cached_at` column.

## Installation

Add the following line to your `Gemfile`:

    gem 'activerecord-cached_at', require: 'cached_at'

If you just need the `ActiveRecord::Base#cache_key` and associated helpers and
aren't updating the models you can just require the helpers:

    gem 'activerecord-cached_at', require: 'cached_at/helpers'

## Configuration

By default updates to the `cached_at`, `updated_at`, and `created_at` columns
will not trigger and update to the `cached_at` column. You can add aditional
fields to ignore:

```ruby
class User
  cached_at ignore: :my_column
end

class Photo
  cached_at ignore: :column_a, :column_b
end
```
## Relationship Cache Keys

CachedAt also allows you to keep cache keys for relationships. This allows you
to use the record to determine if a cache is valid for a relationship instead
of doing another database query.

For example:

```ruby
class User < ActiveRecord::Base
  has_many :photos
end

class Photo
  belongs_to :user, cached_at: true
end

bob_ross = User.create(name: 'Bob Ross')
# => INSERT INTO "users"
#    ("name", "cached_at", "updated_at_", "created_at")
#    VALUES
#    ("Bob Ross", "2020-07-19 20:22:03", "2020-07-19 20:22:03", "2020-07-19 20:22:03")

photo = Photo.create(user: bob_ross, file: ...)
# =>INSERT INTO "photos" ("user_id", "cached_at", "updated_at_", "created_at") VALUES (1, "Bob Ross", "2020-07-19 20:22:04", "2020-07-19 20:22:04", "2020-07-19 20:22:04")
# => UPDATE "users" SET "photos_cached_at" = "2020-07-19 20:22:04" WHERE "users"."id" = 1

photo.update(file: ...)
# =>UPDATE "photos" (..., "cached_at", "updated_at_") VALUES (..., "2020-07-19 20:22:05", "2020-07-19 20:22:05", "2020-07-19 20:22:05")
# => UPDATE "users" SET "photos_cached_at" = "2020-07-19 20:22:05" WHERE "users"."id" = 1

photo.update(user: not_bob_ross)
# =>UPDATE "photos" ("user_id", "cached_at", "updated_at_") VALUES (2, "2020-07-19 20:22:06", "2020-07-19 20:22:06", "2020-07-19 20:22:06")
# => UPDATE "users" SET "photos_cached_at" = "2020-07-19 20:22:06" WHERE "users"."id" IN (1, 2)

photo.destroy
# => UPDATE "users" SET "photos_cached_at" = "2020-07-19 20:22:07" WHERE "users"."id" = 2
# => DELETE FROM "users" WHERE WHERE "users"."id" = 2
```

# Usage

`cached_at` will automatically be used for determining the cache key in Rails.

However if you need to calculate the cache key based on relationship cache keys
you will need to manually compute the cache key. Examples are below:

The cache key here is the maxium of the following keys: `cached_at`,
`listings_cached_at`, and `photos_cached_at`

```erb
<%= render partial: 'row', collection: @properties, as: :property, cached: Proc.new { |item|
  [item.cache_key_with_version(:listings, :photos), current_account.id ]
} %>

<% cache @property.cache_key_with_version(:listings, :photos) do %>
  <b>All the info on this property</b>
  <%= @property.name %>
  <% @property.listings.each do |listing| %>
    <%= listing.info %>
  <% end %>
  <% @property.photos.each do |photo| %>
    <%= image_tag(photo.url) %>
  <% end %>
<% end %>

```
## TODO:

* Document going more than one level with cached_at keys

* Add a `cache_key` method to the Model class that gets `MAX(cached_at)`

* change option to cache: true

* add cache_association helper
