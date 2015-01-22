require 'test_helper'
require 'haml'

class ServerSentEventsTest < Dashing::Test
    def setup
        @connection=[]
        
        app.settings.eventsengine.instance_variable_set(:@connections,  [@connection])
        app.settings.auth_token = nil
        app.settings.default_dashboard = nil
        app.settings.history_file = File.join(Dir.tmpdir, 'history.yml')
    end
    def app
        Sinatra::Application
    end
    def eventsengine
        Sinatra::Application.settings.eventsengine
    end
    def test_stop_engine
        @connection.stubs(:close).returns(true).at_least_once
        eventsengine.stop()
        assert_equal 0,eventsengine.instance_variable_get(:@connections).length
    end    
end