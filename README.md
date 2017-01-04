# ActiveRecord - CachedAt

This gem causes ActiveRecord to update a `cached_at` column if present, like the
`updated_at` column.

When calculating a `cache_key` for a model it will also consider the `cached_at`
column to determin the key of a model.

Any `ActiveRecord::Migration` that calls `timestamps` will include a `cached_at`
column.

TODO: Document about relationship caches

## Installation

Add the following line to your `Gemfile`:

    gem 'activerecord-cached_at', require: 'cached_at'

If you just need the `ActiveRecord::Base#cache_key` and associated helpers and
aren't updating the models you can just require the helpers:

    gem 'activerecord-cached_at', require: 'cached_at/helpers'


## TODO:

 Add a `cache_key` method to the Model class that gets `MAX(cached_at)`
