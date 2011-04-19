# -*- ruby -*-

# require 'rubygems'
# require 'hoe'

$LOAD_PATH.unshift('lib')

# PKG_NAME    = 'bitcoin-protocol'
# PKG_VERSION = Bitcoin::Protocol::VERSION
# PKG_DIST    = "#{PKG_NAME}-#{PKG_VERSION}"
# PKG_TAR     = "pkg/#{PKG_DIST}.tar.gz"
# MANIFEST    = `git ls-files`.split("\n")
# MINRUBY     = "1.8.7"

# Hoe.plugin :git

require 'tasks/bitcoin'

desc "Open an irb session preloaded with this library"
task :console do
  sh "irb -rubygems -r ./lib/bitcoin.rb"
end

desc "Prepare distribution"
task :distro do
  
end


task :default => :test

require 'rake/testtask'
Rake::TestTask.new(:test) do |test|
  test.pattern = 'test/**/{helper,test_*}.rb'
  test.warning = true
  test.verbose = true
end


