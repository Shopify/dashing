HTTParty.post('http://ADDRESS/widgets/karma',
  :body => { auth_token: "YOUR_AUTH_TOKEN", current: 1000}.to_json)
