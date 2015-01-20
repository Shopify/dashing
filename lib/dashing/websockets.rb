require 'sinatra'
require 'sinatra-websocket'
require 'dashing/constants'
require 'dashing/serversentevents'


WS_SUPPORTED_SERVER = ['thin']

get '/websocket/connection' do
	halt 400,"Accepting only websocket connections" unless request.websocket?
	halt 400,"Websockets are disabled in server the configuration" unless settings.eventsengine.type==EventsEngineTypes::WS
	halt 500,"Invalid server configuration" unless WS_SUPPORTED_SERVER.include? settings.server
	request.websocket do |ws|
		ws.onopen do
			ws.send({type:"ack",data:{result:"ok"}}.to_json)
			#settings.engine.websockets << ws
		end
		ws.onmessage do |msg|
			begin
				message=JSON.parse(msg)
				case message['type']
					when 'subscribe'
						settings.eventsengine.openConnection(ws,message)
					when 'event'
						logger.warn("events from clients are not supported")
					end
			rescue Exception => e
				logger.warn(e.message)
				logger.warn(e.backtrace.inspect)
			end 
		end
		ws.onclose do
			logger.warn("websocket closed")
			settings.eventsengine.onclose(ws)
		end
	end
end		

class WebSocketEvents < ServerSentEvents
	register_engine EventsEngineTypes::WS
	def initialize(type)
		super(type)
		@subscription={}
	end
	def openConnection(out,message=nil)
		if message.nil? then 
			out <<  "data: incorrect subscription event"
			return
		end
		@connections << out
		message['data']['events'].each do |id| 
			@subscription[id]=[] if @subscription[id].nil?
			@subscription[id] << out
		end
		lastevents=@history_json.select { |key,val| @subscription.key?(key) }.values
		out.send({type:"subscribe", data:{result:"ok"}}.to_json)
		out.send({type:"event",data: lastevents}.to_json)
	end
	def format_event(body,target=nil)
		evttype= target.nil? ? "event" : target
		{type:evttype,data: body}.to_json
	end
	def send(body,target=nil)
		if target=='dashboards'
			@connections.each { |ws| ws.send(format_event(body,target)) }
		end
		@subscription[body[:id]].each { |out| out.send(format_event(body)) } unless @subscription[body[:id]].nil?
	end
	def onclose(socket)
		super(socket)
		@subscription.each {|id,connlist| connlist.delete(socket) }
	end
end