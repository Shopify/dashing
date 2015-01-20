require "test_helper"
require 'json'
require 'sinatra-websocket/ext/thin/connection'

class WebSocketEventsTest < Dashing::Test
    def setup
        @connection=[]
        app.settings.eventsengine = EventsEngine.create(EventsEngineTypes::WS)
        app.settings.auth_token = nil
        app.settings.default_dashboard = nil
        app.settings.history_file = File.join(Dir.tmpdir, 'history.yml')
        app.settings.server='thin'
    end
    def app
        Sinatra::Application
    end
    def eventsengine
        Sinatra::Application.settings.eventsengine
    end
    def test_no_subscriptions
        connection=[]
        connection.expects(:send).with(:body) do |body|
            objs = JSON.parse(body)
            assert objs['data']['result']=='ok' if objs['type']=='subscribe'
            assert objs['data'].length==0 if objs['type']=='event'
            connection << body
        end.at_least_once
        eventsengine.openConnection(connection)
        assert_equal 1,connection.length
        assert_raises(NoMethodError) {eventsengine.openConnection(connection,{})}
        eventsengine.openConnection(connection,{'data'=>{'events'=>[]}})
        eventsengine.send_event('id',{data:'data'})
    end
    def test_subscriptions
        connection=[]
        connection.expects(:send).with(:body) do |body|
            objs = JSON.parse(body)
            assert objs['data'].length>0 if objs['type']=='event'
            connection << body
        end.at_least_once
        eventsengine.send_event('id',{data:'data'})
        eventsengine.openConnection(connection,{'data'=>{'events'=>['id']}})
        assert_equal 2,connection.length
        eventsengine.send_event('id2',{data:'data'})
        assert_equal 2,connection.length
    end

    def test_init_connection
        request = mock()
        connection=[]
        connection.expects(:send).with(:body) { |body| connection <<body }.at_least_once       
        connection.expects(:onopen).yields().at_least_once
        connection.stubs(:onclose).yields()
        connection.expects(:onmessage).yields({type:'subsribe','data'=>{'events'=>['id']}}.to_json)
        request.expects(:websocket).yields(connection).at_least_once
        logger=mock('logger')
        logger.expects(:warn).with("websocket closed")
        WebSocketEvents.init_websocket_connection(request,logger)
    end
    def test_init_invalid_connection
        request = mock()
        connection=[]
        connection.expects(:send).with(:body) { |body| connection <<body }.times(2)       
        connection.expects(:onopen).yields().times(2)
        connection.stubs(:onclose).yields()
        connection.expects(:onmessage).yields({type:'subsribe','data'=>{'events'=>['id']}})
        request.expects(:websocket).yields(connection).at_least_once
        logger=mock('logger')
        logger.expects(:warn).times(5)
        WebSocketEvents.init_websocket_connection(request,logger)
        connection.expects(:onmessage).yields({type:'event','data'=>{'events'=>['id']}}.to_json)
        WebSocketEvents.init_websocket_connection(request,logger)
    end
    def test_stop_engine
        connection=[]
        connection.expects(:send).with(:body) do |body|
            connection << body
        end.at_least_once
        connection.stubs(:close).returns(true).at_least_once
        eventsengine.openConnection(connection,{'type'=>'event','data'=>{'events'=>['id']}})
        eventsengine.stop()
        assert_equal 0,eventsengine.instance_variable_get(:@connections).length
    end      
end