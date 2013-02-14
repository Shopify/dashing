# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name        = 'dashing'
  s.version     = '1.0.4'
  s.date        = '2013-02-13'
  s.executables << 'dashing'


  s.summary     = "The exceptionally handsome dashboard framework."
  s.description = "This framework lets you build & easily layout dashboards with your own custom widgets. Use it to make a status boards for your ops team, or use it to track signups, conversion rates, or whatever else metrics you'd like to see in one spot. Included with the framework are ready-made widgets for you to use or customize. All of this code was extracted out of a project at Shopify that displays dashboards on TVs around the office."
  s.author      = "Daniel Beauchamp"
  s.email       = 'daniel.beauchamp@shopify.com'
  s.files       = ["lib/Dashing.rb"]
  s.homepage    = 'http://shopify.github.com/dashing'

  s.files = Dir['README.md', 'javascripts/**/*', 'templates/**/*','templates/**/.[a-z]*', 'lib/**/*']

  s.add_dependency('sass')
  s.add_dependency('coffee-script')
  s.add_dependency('sinatra')
  s.add_dependency('sinatra-contrib')
  s.add_dependency('thin')
  s.add_dependency('rufus-scheduler')
  s.add_dependency('thor')
  s.add_dependency('sprockets')
  s.add_dependency('rack')

end