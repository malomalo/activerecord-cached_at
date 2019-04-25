require 'byebug'
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
require 'cached_at'

# Setup the test db
ActiveSupport.test_order = :random
$debugging = false
Minitest::Reporters.use! Minitest::Reporters::SpecReporter.new

class ActiveSupport::TestCase

  def with_cache_versioning(value = true)
    @old_cache_versioning = ActiveRecord::Base.cache_versioning
    ActiveRecord::Base.cache_versioning = value
    yield
  ensure
    ActiveRecord::Base.cache_versioning = @old_cache_versioning
  end

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
  
  def assert_in_memory_and_persisted(record, column, time)
    assert_equal time.to_i, record.send(column).to_i, "#{record.inspect}.#{column} not updated in memory"
    assert_equal time.to_i, record.reload.send(column).to_i, "#{record.inspect}.#{column} not updated in database"
  end
  
  def debug
    ActiveRecord::Base.logger = Logger.new(STDOUT)
    $debugging = true
    yield
  ensure
    ActiveRecord::Base.logger = nil
    $debugging = false
  end
  
  def assert_sql(*patterns_to_match)
    capture_sql { yield }
  ensure
    failed_patterns = []
    patterns_to_match.each do |pattern|
      failed_patterns << pattern unless SQLCounter.log_all.any?{ |sql| pattern === sql }
    end
    assert failed_patterns.empty?, "Query pattern(s) #{failed_patterns.map(&:inspect).join(', ')} not found.#{SQLCounter.log.size == 0 ? '' : "\nQueries:\n#{SQLCounter.log.join("\n")}"}"
  end

  def assert_queries(num = 1, options = {})
    ignore_none = options.fetch(:ignore_none) { num == :any }
    SQLLogger.clear_log
    x = yield
    the_log = ignore_none ? SQLLogger.log_all : SQLLogger.log
    if num == :any
      assert_operator the_log.size, :>=, 1, "1 or more queries expected, but none were executed."
    else
      mesg = "#{the_log.size} instead of #{num} queries were executed.#{the_log.size == 0 ? '' : "\nQueries:\n#{the_log.join("\n")}"}"
      assert_equal num, the_log.size, mesg
    end
    x
  end
  
  class SQLLogger
    class << self
      attr_accessor :ignored_sql, :log, :log_all
      def clear_log; self.log = []; self.log_all = []; end
    end

    self.clear_log

    self.ignored_sql = [/^PRAGMA/i, /^SELECT currval/i, /^SELECT CAST/i, /^SELECT @@IDENTITY/i, /^SELECT @@ROWCOUNT/i, /^SAVEPOINT/i, /^ROLLBACK TO SAVEPOINT/i, /^RELEASE SAVEPOINT/i, /^SHOW max_identifier_length/i, /^BEGIN/i, /^COMMIT/i]

    # FIXME: this needs to be refactored so specific database can add their own
    # ignored SQL, or better yet, use a different notification for the queries
    # instead examining the SQL content.
    oracle_ignored     = [/^select .*nextval/i, /^SAVEPOINT/, /^ROLLBACK TO/, /^\s*select .* from all_triggers/im, /^\s*select .* from all_constraints/im, /^\s*select .* from all_tab_cols/im]
    mysql_ignored      = [/^SHOW FULL TABLES/i, /^SHOW FULL FIELDS/, /^SHOW CREATE TABLE /i, /^SHOW VARIABLES /, /^\s*SELECT (?:column_name|table_name)\b.*\bFROM information_schema\.(?:key_column_usage|tables)\b/im]
    postgresql_ignored = [/^\s*select\b.*\bfrom\b.*pg_namespace\b/im, /^\s*select tablename\b.*from pg_tables\b/im, /^\s*select\b.*\battname\b.*\bfrom\b.*\bpg_attribute\b/im, /^SHOW search_path/i]
    sqlite3_ignored =    [/^\s*SELECT name\b.*\bFROM sqlite_master/im, /^\s*SELECT sql\b.*\bFROM sqlite_master/im]

    [oracle_ignored, mysql_ignored, postgresql_ignored, sqlite3_ignored].each do |db_ignored_sql|
      ignored_sql.concat db_ignored_sql
    end

    attr_reader :ignore

    def initialize(ignore = Regexp.union(self.class.ignored_sql))
      @ignore = ignore
    end

    def call(name, start, finish, message_id, values)
      sql = values[:sql]

      # FIXME: this seems bad. we should probably have a better way to indicate
      # the query was cached
      return if 'CACHE' == values[:name]

      self.class.log_all << sql
      unless ignore =~ sql
        if $debugging
        puts caller.select { |l| l.starts_with?(File.expand_path('../../lib', __FILE__)) }
        puts "\n\n" 
        end
      end
      self.class.log << sql unless ignore =~ sql
    end
  end
  ActiveSupport::Notifications.subscribe('sql.active_record', SQLLogger.new)
  
end
