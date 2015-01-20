require 'sinatra'
require 'dashing/constants'

get '/events', provides: 'text/event-stream' do
  protected!
  response.headers['X-Accel-Buffering'] = 'no' # Disable buffering for nginx
  stream :keep_open do |out|
  	settings.eventsengine.openConnection(out)
  end
end

class EventsEngine
  @@subclasses = { }
  attr_reader :type
  def self.create type
    c = @@subclasses[type]
    if c
      c.new(type)
    else
      raise "Bad events engine type: #{type}"
    end
  end
  def self.register_engine name
    @@subclasses[name] = self
  end
  def send_event(body,target=nil)
  	raise "EventsEngine is abstract. send_event is not implemented."
  end
  def stop
  	raise "EventsEngine is abstract. stop is not implemented."
  end
end

class ServerSentEvents < EventsEngine
	register_engine EventsEngineTypes::SSE
	def initialize(type)
		@type=type
		@connections=[]
		@history_json={}
	end
	def openConnection(out)
		@connections << out
			latest_events=@history_json.inject("") do |str,(id,body)| 
				str << format_event(body.to_json)
			end
    	out << latest_events
    	out.callback { onclose(out) }
	end	
	def format_event(body, name=nil)
	  str = ""
	  str << "event: #{name}\n" if name
	  str << "data: #{body}\n\n"
	end
	def store_event(body,target=nil)
		return body if target=='dashboards'
	  id=body[:id]
	  @history_json[id].merge!(body) unless @history_json[id].nil?
	  @history_json[id]=body if @history_json[id].nil?
	  body=@history_json[id]
	end
	def send_event(id, body, target=nil)
	  body[:id] = id
	  body[:updatedAt] ||= (Time.now.to_f * 1000).ceil
	  body=store_event(body,target)
	  send(body,target)
	end
	def send(body,target=nil)
		event = format_event(body.to_json, target)
		@connections.each { |out| out << event }
	end
	def stop
		@connections.dup.each(&:close)
	end
	def onclose(conn)
		@connections.delete(conn)
	end
end 