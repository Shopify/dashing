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
