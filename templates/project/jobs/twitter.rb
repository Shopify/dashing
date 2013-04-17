require 'twitter'
require 'net/http'
require 'json'

Twitter.configure do |config|
  config.consumer_key = 'YOUR_CONSUMER_KEY'
  config.consumer_secret = 'YOUR_CONSUMER_SECRET'
  config.oauth_token = 'YOUR_OAUTH_TOKEN'
  config.oauth_token_secret = 'YOUR_OAUTH_TOKEN_SECRET'
end

search_term = URI::encode('#todayilearned')

SCHEDULER.every '10m', :first_in => 0 do |job|
  tweets = Twitter.search("#{search_term}").results
  if tweets
    tweets.map! do |tweet|
      { name: tweet.user.name, body: tweet.text, avatar: tweet.user.profile_image_url_https }
    end
    send_event('twitter_mentions', comments: tweets)
  end
end