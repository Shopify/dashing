require 'test_helper'
require File.expand_path('../../lib/dashing', __FILE__)

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
    end
  end

  begin
    require 'haml'
    def test_get_haml
      with_generated_project do |dir|
        File.write(File.join(dir, "dashboards/hamltest.haml"), <<-HAML)
.gridster
  %ul
    %li{data: {col: 1, row: 1, sizex: 1, sizey: 1}}
      %div{data: {view: "Clock"}}
      %i.icon-time.icon-background
HAML
        get '/hamltest'
        assert_equal 200, last_response.status
        assert_include last_response.body, "class='gridster'"
      end
    end
  rescue LoadError
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
end