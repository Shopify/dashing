# Events Engines
Dashing provides two engines for processing events to and from clients. __ServerSentEvents__ and __WebSockets__. The __ServerSentEvents__ engine provides one way comunication from the dashing server to a client. __WebSockets__ engine provides two way communication and supports subscriptions to reduce traffic between the server and the client. A dashboard automatically subscribes to receive message only for widgets it contains.

## Engine Selection
Dashing is using _eventsengine_ setting as engine instance reference. One can select the engine type during the configuration of the application: 

__config.ru:__
```ruby
configure do
  set :auth_token, 'YOUR_AUTH_TOKEN'
  set :eventsengine, EventsEngine.create(EventsEngineTypes::WS)
end
```
The above selects websocket engine.

Currently supported engines are:
* ServerSideEvents - _EventsEngineTypes::SSE_
* WebSockets - _EventsEngineTypes::WS_

## Add your own engine
To add an engine, you need to provide a route for accepting request and subclass EventsEngine class. Optionally you could add a constant to the EventsEngineType module to improve code readability. You also need to add engine on the client side. 

__1. add constant__
```ruby
module EventsEngineTypes
	WEBSOCKET2="WS2" #new web socket implementation
end
```

__2. route__: 
```ruby
get '/events', provides: 'text/event-stream' do
  protected!
  response.headers['X-Accel-Buffering'] = 'no' # Disable buffering for nginx
  stream :keep_open do |out|
  	settings.eventsengine.openConnection(out)
  end
end
```

__3. subclass EventsEngine__:
You need to subclass EventsEngine class, register your new engine and implement _send_event_ and _stop_ methods
```ruby
class NewCoolWebSockets < EventsEngine
	register_engine EventsEngineTypes::WEBSOCKET2
	def stop
	end
	def send_event(body, target=nil)
	end
end
```

__4. add engine on the client side__
```coffee
  $(document).ready -> 
  	if Configuration.EventEngine=="WS2"
  		Dashing.source= -> 
  			.... create your own engine...
```
> Please note that client side uses the value of the EventsEngineType's constant, not its name
