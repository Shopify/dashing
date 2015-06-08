require 'test_helper'

class CLITest < Dashing::Test
  def setup
    @cli = Dashing::CLI.new
  end

  def test_new_task_creates_project_directory
    app_name = 'custom_dashboard'
    @cli.stubs(:directory).with(:project, app_name).once
    @cli.new(app_name)
  end

  def test_generate_task_delegates_to_type
    types = %w(widget dashboard job)

    types.each do |type|
      @cli.stubs(:public_send).with("generate_#{type}".to_sym, 'name').once
      @cli.generate(type, 'name')
    end
  end

  def test_generate_task_warns_when_generator_is_not_defined
    output, _ = capture_io do
      @cli.generate('wtf', 'name')
    end

    assert_includes output, 'Invalid generator'
  end

  def test_generate_widget_creates_a_new_widget
    @cli.stubs(:directory).with(:widget, 'widgets').once
    @cli.generate_widget('WidgetName')
    assert_equal 'widget_name', @cli.name
  end

  def test_generate_dashboard_creates_a_new_dashboard
    @cli.stubs(:directory).with(:dashboard, 'dashboards').once
    @cli.generate_dashboard('DashBoardName')
    assert_equal 'dash_board_name', @cli.name
  end

  def test_generate_job_creates_a_new_job
    @cli.stubs(:directory).with(:job, 'jobs').once
    @cli.generate_job('MyCustomJob')
    assert_equal 'my_custom_job', @cli.name
  end

  def test_install_task_requests_gist_from_downloader
    return_value = { 'files' => [] }
    Dashing::Downloader.stubs(:get_gist).with(123).returns(return_value).once

    capture_io { @cli.install(123) }
  end

  def test_install_task_calls_create_file_for_each_valid_file_in_gist
    json_response = <<-JSON
      {
        "files": {
          "ruby_job.rb": { "content": "some job content" },
          "num.html": { "content": "some html content" },
          "num.scss": { "content": "some sass content" },
          "num.coffee": { "content": "some coffee content" }
        }
      }
    JSON

    Dir.stubs(:pwd).returns('')

    Dashing::Downloader.stubs(:get_gist).returns(JSON.parse(json_response))
    @cli.stubs(:create_file).with('/jobs/ruby_job.rb', 'some job content', {:skip => false}).once
    @cli.stubs(:create_file).with('/widgets/num/num.html', 'some html content', {:skip => false}).once
    @cli.stubs(:create_file).with('/widgets/num/num.scss', 'some sass content', {:skip => false}).once
    @cli.stubs(:create_file).with('/widgets/num/num.coffee', 'some coffee content', {:skip => false}).once

    capture_io { @cli.install(123) }
  end

  def test_install_task_ignores_invalid_files
    json_response = <<-JSON
      {
        "files": {
          "ruby_job.js": { "content": "some job content" },
          "num.css": { "content": "some sass content" }
        }
      }
    JSON

    Dashing::Downloader.stubs(:get_gist).returns(JSON.parse(json_response))
    @cli.stubs(:create_file).never

    capture_io { @cli.install(123) }
  end

  def test_install_task_warns_when_gist_not_found
    error = OpenURI::HTTPError.new('error', mock())
    Dashing::Downloader.stubs(:get_gist).raises(error)

    output, _ = capture_io { @cli.install(123) }

    assert_includes output, 'Could not find gist at '
  end

  def test_start_task_starts_thin_with_default_port
    command = 'bundle exec thin -R config.ru start -p 3030 '
    @cli.stubs(:run_command).with(command).once
    @cli.start
  end

  def test_start_task_starts_thin_with_specified_port
    command = 'bundle exec thin -R config.ru start -p 2020'
    @cli.stubs(:run_command).with(command).once
    @cli.start('-p', '2020')
  end

  def test_start_task_supports_job_path_option
    commands = [
      'export JOB_PATH=other_spot; ',
      'bundle exec thin -R config.ru start -p 3030 '
    ]

    @cli.stubs(:options).returns(job_path: 'other_spot')
    @cli.stubs(:run_command).with(commands.join('')).once
    @cli.start
  end

  def test_stop_task_stops_thin_server
    @cli.stubs(:run_command).with('bundle exec thin stop')
    @cli.stop
  end

  def test_job_task_requires_job_file
    Dir.stubs(:pwd).returns('')
    @cli.stubs(:require_file).with('/jobs/special_job.rb').once

    @cli.job('special_job')
  end

  def test_job_task_requires_every_ruby_file_in_lib
    Dir.stubs(:pwd).returns('')
    Dir.stubs(:[]).returns(['lib/dashing/cli.rb', 'lib/dashing.rb'])
    @cli.stubs(:require_file).times(3)

    @cli.job('special_job')
  end

  def test_job_sets_auth_token
    @cli.class.stubs(:auth_token=).with('my_token').once
    @cli.stubs(:require_file)

    @cli.job('my_job', 'my_token')
  end

  def test_hyphenate_lowers_and_hyphenates_inputs
    assertion_map = {
      'Power' => 'power',
      'POWER' => 'power',
      'PowerRangers' => 'power-rangers',
      'Power_ranger' => 'power-ranger',
      'SuperPowerRangers' => 'super-power-rangers'
    }

    assertion_map.each do |input, expected|
      assert_equal expected, Dashing::CLI.hyphenate(input)
    end
  end

end
