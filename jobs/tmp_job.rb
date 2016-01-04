# :first_in sets how long it takes before the job is first run. In this case, it is run immediately

SCHEDULER.every '1m', :first_in => 0 do |job|

HTTParty.post('http://http://agile-tundra-7117.herokuapp.com/widgets/karma',
  :body => { auth_token: "A3AEAF95-B123-4EB2-AA2A-1EB803809D23", current: 1000 }.to_json)

end
