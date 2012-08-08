require 'dashing'

configure do
  set :auth_token, 'YOUR_AUTH_TOKEN'
end

run Sinatra::Application