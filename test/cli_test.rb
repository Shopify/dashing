require 'test_helper'
load_quietly 'bin/dashing'

module Thor::Actions
  def source_paths
    [File.join(File.expand_path(File.dirname(__FILE__)), '../templates')]
  end
end

class CliTest < Dashing::Test

  def test_project_directory_created
    temp do |dir|
      cli = Dashing::CLI.new
      silent { cli.new 'Dashboard' }
      assert Dir.exist?(File.join(dir,'dashboard')), 'Dashing directory was not created.'
    end
  end

  def test_hyphenate
    assert_equal 'power', Dashing::CLI.hyphenate('Power')
    assert_equal 'power', Dashing::CLI.hyphenate('POWER')
    assert_equal 'power-rangers', Dashing::CLI.hyphenate('PowerRangers')
    assert_equal 'power-ranger', Dashing::CLI.hyphenate('Power_ranger')
    assert_equal 'super-power-rangers', Dashing::CLI.hyphenate('SuperPowerRangers')
  end

end
