require 'garb'

Garb::Session.login("GOOGLE EMAIL", "GOOGLE PASSWORD")
profile = Garb::Management::Profile.all.detect {|p| p.web_property_id == 'UA-XXXXXXXXX-X'}

class Stats
  extend Garb::Model

  metrics :pageviews, :visitors
end

SCHEDULER.every '60s' do
  stat = Stats.results(profile, :start_date => Time.now()).to_a[0]
  send_event('analytics_page_views', { current: stat.pageviews.to_i })
  send_event('analytics_visitors', { current: stat.visitors.to_i })
end
