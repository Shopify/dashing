require 'sinatra'
require 'sinatra/content_for'
require 'rufus/scheduler'
require 'coffee-script'
require 'sass'
require 'json'

Dir[File.join(Dir.pwd, 'lib/**/*.rb')].each {|file| require file }

SCHEDULER = Rufus::Scheduler.start_new

set server: 'thin', connections: [], history: {}
helpers Sinatra::ContentFor

def configure(&block)
  set :public_folder, Dir.pwd + '/public'
  set :views, Dir.pwd + '/dashboards'
  set :default_dashboard, nil
  instance_eval(&block)
end

helpers do
  def protected!
    # override with auth logic
  end
end

get '/events', provides: 'text/event-stream' do
  protected!
  stream :keep_open do |out|
    settings.connections << out
    out << latest_events
    out.callback { settings.connections.delete(out) }
  end
end

get '/' do
  begin
  redirect "/" + (settings.default_dashboard || first_dashboard).to_s
  rescue NoMethodError => e
    raise Exception.new("There are no dashboards in your dashboard directory.")
  end
end

get '/:dashboard' do
  protected!
  erb params[:dashboard].to_sym
end

get '/views/:widget?.html' do
  protected!
  widget = params[:widget]
  send_file File.join(Dir.pwd, "widgets/#{widget}/#{widget}.html")
end

post '/widgets/:id' do
  request.body.rewind
  body =  JSON.parse(request.body.read)
  auth_token = body.delete("auth_token")
  if auth_token == settings.auth_token
    send_event(params['id'], body)
    204 # response without entity body
  else
    status 401
    "Invalid API key\n"
  end
end

def framework_javascripts
  ['jquery.js', 'es5-shim.js', 'batman.js', 'batman.jquery.js', 'application.coffee', 'widget.coffee'].collect do |f|
    File.join(File.expand_path("../../vendor/javascripts", __FILE__), f)
  end
end

def widget_javascripts
  asset_paths("/widgets/**/*.coffee")
end

def javascripts
  (framework_javascripts + widget_javascripts).collect do |f|
    if File.extname(f) == ".coffee"
      begin
      CoffeeScript.compile(File.read(f))
      rescue ExecJS::ProgramError => e
        message = e.message + ": in #{f}"
        raise ExecJS::ProgramError.new(message)
      end
    else
      File.read(f)
    end
  end.join("\n")
end

def stylesheets
  asset_paths("/public/**/*.scss", "/widgets/**/*.scss").collect do |f|
    Sass.compile File.read(f)
  end.join("\n")
end

def asset_paths(*paths)
  paths.inject([]) { |arr, path| arr + Dir[File.join(Dir.pwd, path)] }
end

def send_event(id, body)
  body["id"] = id
  event = format_event(JSON.unparse(body))
  settings.history[id] = event
  settings.connections.each { |out| out << event }
end

def format_event(body)
  "data: #{body}\n\n"
end

def latest_events
  settings.history.inject("") do |str, (id, body)|
    str << body
  end
end

def first_dashboard
  files = Dir[settings.views  + "/*.erb"].collect { |f| f.match(/(\w*).erb/)[1] }
  files -= ['layout']
  files.first
end

job_path = ENV["JOB_PATH"] || 'jobs'
files = Dir[Dir.pwd + "/#{job_path}/*.rb"]
files.each { |job| require(job) } 