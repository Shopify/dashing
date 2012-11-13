require 'net/http'
require 'xmlsimple'

# Get a WOEID (Where On Earth ID)
# for your location from here:
# http://woeid.rosselliot.co.nz/
woe_id = 3369

# Temerature format:
# 'c' for Celcius
# 'f' for Fahrenheit
format = 'c'

SCHEDULER.every '15m', :first_in => 0 do |job|
  http = Net::HTTP.new('weather.yahooapis.com')
  response = http.request(Net::HTTP::Get.new("/forecastrss?w=#{woe_id}&u=#{format}"))
  weather_data = XmlSimple.xml_in(response.body, { 'ForceArray' => false })['channel']['item']['condition']
  send_event('weather', { :temp => "#{weather_data['temp']}&deg;#{format.upcase}", :condition => weather_data['text'] })
end