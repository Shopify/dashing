# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name        = 'dashing'
  s.version     = '1.3.7'
  s.date        = '2016-04-11'
  s.executables = %w(dashing)


  s.summary     = "The exceptionally handsome dashboard framework."
  s.description = "This framework lets you build & easily layout dashboards with your own custom widgets. Use it to make a status boards for your ops team, or use it to track signups, conversion rates, or whatever else metrics you'd like to see in one spot. Included with the framework are ready-made widgets for you to use or customize. All of this code was extracted out of a project at Shopify that displays dashboards on TVs around the office."
  s.author      = "Daniel Beauchamp"
  s.email       = 'daniel.beauchamp@shopify.com'
  s.homepage    = 'http://shopify.github.com/dashing'
  s.license     = "MIT"

  s.files = Dir['README.md', 'javascripts/**/*', 'templates/**/*','templates/**/.[a-z]*', 'lib/**/*']

  s.add_dependency('sass', '~> 3.2.12')
  s.add_dependency('coffee-script', '~> 2.2.0')
  s.add_dependency('execjs', '~> 2.0.2')
  s.add_dependency('sinatra', '~> 1.4.4')
  s.add_dependency('sinatra-contrib', '~> 1.4.2')
  s.add_dependency('thin', '~> 1.6.1')
  s.add_dependency('rufus-scheduler', '~> 2.0.24')
  s.add_dependency('thor', '> 0.18.1')
  s.add_dependency('sprockets', '~> 2.10.1')
  s.add_dependency('rack', '~> 1.5.4')

  s.add_development_dependency('rake', '~> 10.1.0')
  s.add_development_dependency('haml', '~> 4.0.4')
  s.add_development_dependency('minitest', '~> 5.2.0')
  s.add_development_dependency('mocha', '~> 0.14.0')
  s.add_development_dependency('fakeweb', '~> 1.3.0')
  s.add_development_dependency('simplecov', '~> 0.8.2')
end
