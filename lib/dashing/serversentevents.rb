require 'sinatra'

get '/events', provides: 'text/event-stream' do
  protected!
  response.headers['X-Accel-Buffering'] = 'no' # Disable buffering for nginx
  stream :keep_open do |out|
  	engine.openConnection(out)
  end
end

class ServerSentEvents
	def initialize
		@connections=[]
		@history_json=[]
	def openConnection(out)
		@connections << out
			latest_events=@history_json.inject("") do |str,(id,body)| 
				str << format_event(body.to_json)
			end
    	out << latest_events
    	out.callback { @connections.delete(out) }
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
	  body[:updatedAt] ||= Time.now.to_i
	  body=store_event(body,target)
	  send(body,target)
	end
	def send(body,target=nil)
		event = format_event(body.to_json, target)
		@connections.each { |out| out << event }
	end
end 