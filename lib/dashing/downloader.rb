require 'net/http'
require 'open-uri'
require 'json'

module Dashing
  module Downloader
    extend self

    def get_gist(gist_id)
      get_json("https://api.github.com/gists/#{gist_id}")
    end

    def get_json(url)
      response = open(url).read
      JSON.parse(response)
    end
  end
end
