require 'test_helper'
silent{ load 'bin/dashing' }

module Thor::Actions
  def source_paths
    [File.join(File.expand_path(File.dirname(__FILE__)), '../templates')]
  end
end

class CliTest < Dashing::Test

  def test_project_directory_created
    temp do |dir|
      cli = Dashing::CLI.new
      silent{ cli.new 'Dashboard' }
      assert Dir.exist?(File.join(dir,'dashboard')), 'Dashing directory was not created.'
    end
  end

end