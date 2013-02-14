require 'sinatra'
require 'sprockets'
require 'sinatra/content_for'
require 'rufus/scheduler'
require 'coffee-script'
require 'sass'
require 'json'

SCHEDULER = Rufus::Scheduler.start_new

set :root, Dir.pwd

set :sprockets,     Sprockets::Environment.new(settings.root)
set :assets_prefix, '/assets'
set :digest_assets, false
['assets/javascripts', 'assets/stylesheets', 'assets/fonts', 'assets/images', 'widgets', File.expand_path('../../javascripts', __FILE__)]. each do |path|
  settings.sprockets.append_path path
end

set server: 'thin', connections: [], history: {}
set :public_folder, File.join(settings.root, 'public')
set :views, File.join(settings.root, 'dashboards')
set :default_dashboard, nil
set :auth_token, nil

helpers Sinatra::ContentFor
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
  if File.exist? File.join(settings.views, "#{params[:dashboard]}.erb")
    erb params[:dashboard].to_sym
  else
    halt 404
  end
end

get '/views/:widget?.html' do
  protected!
  widget = params[:widget]
  send_file File.join(settings.root, 'widgets', widget, "#{widget}.html")
end

post '/widgets/:id' do
  request.body.rewind
  body =  JSON.parse(request.body.read)
  auth_token = body.delete("auth_token")
  if !settings.auth_token || settings.auth_token == auth_token
    send_event(params['id'], body)
    204 # response without entity body
  else
    status 401
    "Invalid API key\n"
  end
end

not_found do
  send_file File.join(settings.public_folder, '404.html')
end

def development?
  ENV['RACK_ENV'] == 'development'
end

def production?
  ENV['RACK_ENV'] == 'production'
end

def send_event(id, body)
  body[:id] = id
  body[:updatedAt] ||= Time.now.to_i
  event = format_event(body.to_json)
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
  files = Dir[File.join(settings.views, '*.erb')].collect { |f| f.match(/(\w*).erb/)[1] }
  files -= ['layout']
  files.first
end

Dir[File.join(settings.root, 'lib', '**', '*.rb')].each {|file| require file }
{}.to_json # Forces your json codec to initialize (in the event that it is lazily loaded). Does this before job threads start.

job_path = ENV["JOB_PATH"] || 'jobs'
files = Dir[File.join(settings.root, job_path, '/*.rb')]
files.each { |job| require(job) } 
