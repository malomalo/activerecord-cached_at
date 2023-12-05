require 'bundler/setup'
require "bundler/gem_tasks"
Bundler.require(:development)

require 'fileutils'
require "rake/testtask"

# ==== Test Tasks =============================================================
ADAPTERS = %w(postgres sqlite)

namespace :test do
  ADAPTERS.each do |adapter|
    Rake::TestTask.new(adapter => "#{adapter}:setup") do |t|
        t.libs << 'lib' << 'test'
        t.test_files = FileList[ARGV[1] ? ARGV[1] : 'test/**/*_test.rb']
        t.warning = false
        t.verbose = true
    end
    
    namespace adapter do
      task(:setup) { ENV["AR_ADAPTER"] = adapter }
    end
  end
  
  desc "Run test with all adapters"
  task all: ADAPTERS.shuffle.map{ |e| "test:#{e}" }
end

task test: "test:all"

# # require "sdoc"
# RDoc::Task.new do |rdoc|
#   rdoc.main = 'README.md'
#   rdoc.title = 'Wankel API'
#   rdoc.rdoc_dir = 'doc'
#
#   rdoc.rdoc_files.include('README.md')
#   rdoc.rdoc_files.include('logo.png')
#   rdoc.rdoc_files.include('lib/**/*.rb')
#   rdoc.rdoc_files.include('ext/**/*.{h,c}')
#
#   rdoc.options << '-f' << 'sdoc'
#   rdoc.options << '-T' << '42floors'
#   rdoc.options << '--charset' << 'utf-8'
#   rdoc.options << '--line-numbers'
#   rdoc.options << '--github'
# end
