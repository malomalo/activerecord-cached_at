require 'simplecov'
SimpleCov.start do
  add_filter '/test/'
end

# To make testing/debugging easier, test within this source tree versus an
# installed gem
$LOAD_PATH << File.expand_path('../lib', __FILE__)

require "minitest/autorun"
require 'minitest/unit'
require 'minitest/reporters'
require 'active_record/cached_at'

# Setup the test db
ActiveSupport.test_order = :random

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
    ActiveRecord::Base.establish_connection(adapter: "sqlite3", database: ":memory:")

    if !instance_variable_defined?(:@suite_setup_run) && self.class.class_variable_defined?(:@@schema)
      ActiveRecord::Migration.suppress_messages do
        ActiveRecord::Schema.define(&self.class.class_variable_get(:@@schema))
        ActiveRecord::Base.connection.data_sources.each do |table|
          next if table == 'ar_internal_metadata'
          ActiveRecord::Migration.execute("INSERT INTO SQLITE_SEQUENCE (name,seq) VALUES ('#{table}', #{rand(50_000)})")
        end
      end
    end
    @suite_setup_run = true
  end
  
  def debug
    ActiveRecord::Base.logger = Logger.new(STDOUT)
    $debugging = true
    yield
  ensure
    ActiveRecord::Base.logger = nil
    $debugging = false
  end
  
end
