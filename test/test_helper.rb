require 'rack/test'
require 'stringio'
require 'test/unit'
require 'tmpdir'

ENV['RACK_ENV'] = 'test'
WORKING_DIRECTORY = Dir.pwd.freeze
ARGV.clear

def silent
  _stdout = $stdout
  $stdout = mock = StringIO.new
  begin
    yield
  ensure
    $stdout = _stdout
  end
end

def temp
  path = File.expand_path "#{Dir.tmpdir}/#{Time.now.to_i}#{rand(1000)}/"
  FileUtils.mkdir_p path
  Dir.chdir path
  yield path
ensure
  Dir.chdir WORKING_DIRECTORY
  FileUtils.rm_rf(path) if File.exists?(path)
end

module Dashing
  class Test < Test::Unit::TestCase
    include Rack::Test::Methods
  end
end