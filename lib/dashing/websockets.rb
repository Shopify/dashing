require 'sinatra'
require 'sinatra-websocket'
require 'dashing/constants'
require 'dashing/serversentevents'


WS_SUPPORTED_SERVER = ['thin']

get '/websocket/connection' do
	halt 400,"Accepting only websocket connections" unless request.websocket?
	halt 400,"Websockets are disabled in server the configuration" unless settings.eventsengine==EventsEngines::WS
	halt 500,"Invalid server configuration" unless WS_SUPPORTED_SERVER.include? settings.server
	request.websocket do |ws|
		ws.onopen do
			ws.send('{"type":"ack","data":{"result":"ok"}}')
			engine.websockets << ws
		end
		ws.onmessage do |msg|
			begin
				message=JSON.parse(msg)
				case message.type
					when 'subscribe'
						engine.openConnection(ws,message)
						engine.openConnection()
					when 'event'
			rescue Exception => e
				logger.warn(e.message)
				logger.warn(e.backtrace.inspect)
			end 
			print settings.websockets[0].inspect + "\n"

			EM.next_tick { settings.websockets.each{|s| s.send(msg) } }
		end
		ws.onclose do
			warn("websocket closed")
			settings.websockets.delete(ws)
		end
	end
end		

class WebSocketEvents < ServerSentEvents
	def initialize
		super
		@subscription={}
	end
	def openConnection(out,message)
		message.data.events.each do |id| 
			@subscription[id]=[] if @subscription[id].nil?
			@subscription[id] << out
		end
		lastevents=@history_json.select { |key,val| @subscriptions.include? key }.values.to_json
		out.send('{"type":"subscribe", "data":{"result":"ok"}}')
		out.send('{"type":"event","data": [#{lastevents}}]')
	end
	def format_event(body,target=nil)
		'{"type":"event","data":#{body.to_json}}'
	end
	def send(body,target=nil)
		@subscription[body[:id]].each { |out| out.send(format_event(body)) }
	end