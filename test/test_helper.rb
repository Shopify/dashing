require 'simplecov'
SimpleCov.start do
  add_filter "/vendor/"
  add_filter "/test/"
end

require 'rack/test'
require 'stringio'
require 'tmpdir'
require 'fakeweb'
require 'minitest/autorun'
require 'minitest/pride'
require 'mocha/setup'

require_relative '../lib/dashing'

FakeWeb.allow_net_connect = false

ENV['RACK_ENV'] = 'test'
WORKING_DIRECTORY = Dir.pwd.freeze
ARGV.clear

def load_quietly(file)
  Minitest::Test.new(nil).capture_io do
    load file
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
  class Test < Minitest::Test
    include Rack::Test::Methods

    alias_method :silent, :capture_io

    def teardown
      FileUtils.rm_f('history.yml')
    end
  end
end
