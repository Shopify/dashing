require 'net/http'
require 'json'

video_id = "QH2-TGUlwu4"


SCHEDULER.every '10s', :first_in => 0 do |job|
  http = Net::HTTP.new('gdata.youtube.com')
  response = http.request(Net::HTTP::Get.new("/feeds/api/videos/#{video_id}?v=2&alt=json"))
  infos = JSON.parse(response.body)
  if infos
    send_event('youtube_views', current: infos["entry"]["yt$statistics"]["viewCount"].to_i)
  end
end
