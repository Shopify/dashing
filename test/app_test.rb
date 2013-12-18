require 'test_helper'
require 'haml'

Sinatra::Application.settings.history_file = File.join(Dir.tmpdir, 'history.yml')

class AppTest < Dashing::Test
  def setup
    @connection = []
    Sinatra::Application.settings.connections = [@connection]
    Sinatra::Application.settings.auth_token = nil
    Sinatra::Application.settings.default_dashboard = nil
  end

  def test_post_widgets_without_auth_token
    post '/widgets/some_widget', JSON.generate({value: 6})
    assert_equal 204, last_response.status

    assert_equal 1, @connection.length
    data = parse_data @connection[0]
    assert_equal 6, data['value']
    assert_equal 'some_widget', data['id']
    assert data['updatedAt']
  end

  def test_post_widgets_with_invalid_auth_token
    Sinatra::Application.settings.auth_token = 'sekrit'
    post '/widgets/some_widget', JSON.generate({value: 9})
    assert_equal 401, last_response.status
  end

  def test_post_widgets_with_valid_auth_token
    Sinatra::Application.settings.auth_token = 'sekrit'
    post '/widgets/some_widget', JSON.generate({value: 9, auth_token: 'sekrit'})
    assert_equal 204, last_response.status
  end

  def test_get_events
    post '/widgets/some_widget', JSON.generate({value: 8})
    assert_equal 204, last_response.status

    get '/events'
    assert_equal 200, last_response.status
    assert_equal 8, parse_data(@connection[0])['value']
  end

  def test_dashboard_events
    post '/dashboards/my_super_sweet_dashboard', JSON.generate({event: 'reload'})
    assert_equal 204, last_response.status

    get '/events'
    assert_equal 200, last_response.status
    assert_equal 'dashboards', parse_event(@connection[0])
    assert_equal 'reload', parse_data(@connection[0])['event']
  end

  def test_redirect_to_default_dashboard
    with_generated_project do
      Sinatra::Application.settings.default_dashboard = 'test1'
      get '/'
      assert_equal 302, last_response.status
      assert_equal 'http://example.org/test1', last_response.location
    end
  end

  def test_redirect_to_first_dashboard
    with_generated_project do
      get '/'
      assert_equal 302, last_response.status
      assert_equal 'http://example.org/sample', last_response.location
    end
  end

  def test_redirect_to_first_dashboard_without_erb
    with_generated_project do |dir|
      FileUtils.touch(File.join(dir, "dashboards/htmltest.html"))
      get '/'
      assert_equal 302, last_response.status
      assert_equal 'http://example.org/htmltest', last_response.location
    end
  end

  def test_get_dashboard
    with_generated_project do
      get '/sampletv'
      assert_equal 200, last_response.status
      assert_include last_response.body, 'class="gridster"'
      assert_include last_response.body, "DOCTYPE"
    end
  end

  def test_page_title_set_correctly
    with_generated_project do
      get '/sampletv'
      assert_include last_response.body, '<title>1080p dashboard</title>'
    end
  end

  def test_get_haml_dashboard
    with_generated_project do |dir|
      File.write(File.join(dir, 'dashboards/hamltest.haml'), '.gridster')
      get '/hamltest'
      assert_equal 200, last_response.status
      assert_include last_response.body, "class='gridster'"
    end
  end

  def test_get_haml_widget
    with_generated_project do |dir|
      File.write(File.join(dir, 'widgets/clock/clock.haml'), '%h1 haml')
      File.unlink(File.join(dir, 'widgets/clock/clock.html'))
      get '/views/clock.html'
      assert_equal 200, last_response.status
      assert_include last_response.body, '<h1>haml</h1>'
    end
  end

  def test_get_nonexistent_dashboard
    with_generated_project do
      get '/nodashboard'
      assert_equal 404, last_response.status
    end
  end

  def test_get_widget
    with_generated_project do
      get '/views/meter.html'
      assert_equal 200, last_response.status
      assert_include last_response.body, 'class="meter"'
    end
  end

  def with_generated_project
    temp do |dir|
      cli = Dashing::CLI.new
      silent { cli.new 'new_project' }

      Sinatra::Application.settings.views = File.join(dir, 'new_project/dashboards')
      Sinatra::Application.settings.root = File.join(dir, 'new_project')
      yield Sinatra::Application.settings.root
    end
  end

  def app
    Sinatra::Application
  end

  def parse_data(string)
    JSON.parse string[/data: (.+)/, 1]
  end

  def parse_event(string)
    string[/event: (.+)/, 1]
  end
end
