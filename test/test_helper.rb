require 'simplecov'
SimpleCov.start

# To make testing/debugging easier, test within this source tree versus an
# installed gem
$LOAD_PATH << File.expand_path('../lib', __FILE__)

require "minitest/autorun"
require 'minitest/unit'
require 'minitest/reporters'
require 'active_record/cached_at'

# Setup the test db
ActiveSupport.test_order = :random
require File.expand_path('../database', __FILE__)

Minitest::Reporters.use! Minitest::Reporters::SpecReporter.new

class ActiveSupport::TestCase

  # File 'lib/active_support/testing/declarative.rb'
  def self.test(name, &block)
    test_name = "test_#{name.gsub(/\s+/, '_')}".to_sym
    defined = method_defined? test_name
    raise "#{test_name} is already defined in #{self}" if defined
    if block_given?
      define_method(test_name, &block)
    else
      define_method(test_name) do
        skip "No implementation provided for #{name}"
      end
    end
  end
  
  def self.schema(&block)
    self.class_variable_set(:@@schema, block)
  end
  
  set_callback(:setup, :before) do
    if !instance_variable_defined?(:@suite_setup_run) && self.class.class_variable_defined?(:@@schema)

      ActiveRecord::Migration.suppress_messages do
        ActiveRecord::Base.establish_connection(adapter: "sqlite3", database: ":memory:")
        ActiveRecord::Schema.define(&self.class.class_variable_get(:@@schema))
      end
    end
    @suite_setup_run = true
  end
  
end
