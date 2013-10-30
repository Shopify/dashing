require 'sinatra'
require 'sprockets'
require 'sinatra/content_for'
require 'rufus/scheduler'
require 'coffee-script'
require 'sass'
require 'json'
require 'yaml'

SCHEDULER = Rufus::Scheduler.start_new

set :root, Dir.pwd

set :sprockets,     Sprockets::Environment.new(settings.root)
set :assets_prefix, '/assets'
set :digest_assets, false
['assets/javascripts', 'assets/stylesheets', 'assets/fonts', 'assets/images', 'widgets', File.expand_path('../../javascripts', __FILE__)]. each do |path|
  settings.sprockets.append_path path
end

set server: 'thin', connections: [], history_file: 'history.yml'

# Persist history in tmp file at exit
at_exit do
  File.open(settings.history_file, 'w') do |f|
    f.puts settings.history.to_yaml
  end
end

if File.exists?(settings.history_file)
  set history: YAML.load_file(settings.history_file)
else
  set history: {}
end

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
  response.headers['X-Accel-Buffering'] = 'no' # Disable buffering for nginx
  stream :keep_open do |out|
    settings.connections << out
    out << latest_events
    out.callback { settings.connections.delete(out) }
  end
end

get '/' do
  protected!
  begin
  redirect "/" + (settings.default_dashboard || first_dashboard).to_s
  rescue NoMethodError => e
    raise Exception.new("There are no dashboards in your dashboard directory.")
  end
end

get '/:dashboard' do
  protected!
  tilt_html_engines.each do |suffix, _|
    file = File.join(settings.views, "#{params[:dashboard]}.#{suffix}")
    return render(suffix.to_sym, params[:dashboard].to_sym) if File.exist? file
  end

  halt 404
end

get '/views/:widget?.html' do
  protected!
  tilt_html_engines.each do |suffix, engines|
    file = File.join(settings.root, "widgets", params[:widget], "#{params[:widget]}.#{suffix}")
    return engines.first.new(file).render if File.exist? file
  end
end

post '/dashboards/:id' do
  request.body.rewind
  body = JSON.parse(request.body.read)
  body['dashboard'] ||= params['id']
  auth_token = body.delete("auth_token")
  if !settings.auth_token || settings.auth_token == auth_token
    send_event(params['id'], body, 'dashboards')
    204 # response without entity body
  else
    status 401
    "Invalid API key\n"
  end
end

post '/widgets/:id' do
  request.body.rewind
  body = JSON.parse(request.body.read)
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

def send_event(id, body, target=nil)
  body[:id] = id
  body[:updatedAt] ||= Time.now.to_i
  event = format_event(body.to_json, target)
  Sinatra::Application.settings.history[id] = event unless target == 'dashboards'
  Sinatra::Application.settings.connections.each { |out| out << event }
end

def format_event(body, name=nil)
  str = ""
  str << "event: #{name}\n" if name
  str << "data: #{body}\n\n"
end

def latest_events
  settings.history.inject("") do |str, (id, body)|
    str << body
  end
end

def first_dashboard
  files = Dir[File.join(settings.views, '*')].collect { |f| File.basename(f, '.*') }
  files -= ['layout']
  files.sort.first
end

def tilt_html_engines
  Tilt.mappings.select do |_, engines|
    default_mime_type = engines.first.default_mime_type
    default_mime_type.nil? || default_mime_type == 'text/html'
  end
end

settings_file = File.join(settings.root, 'config/settings.rb')
if (File.exists?(settings_file))
  require settings_file
end

Dir[File.join(settings.root, 'lib', '**', '*.rb')].each {|file| require file }
{}.to_json # Forces your json codec to initialize (in the event that it is lazily loaded). Does this before job threads start.

job_path = ENV["JOB_PATH"] || 'jobs'
files = Dir[File.join(settings.root, job_path, '**', '/*.rb')]
files.each { |job| require(job) }
