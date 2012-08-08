Gem::Specification.new do |s|
  s.name        = 'dashing'
  s.version     = '0.1.0'
  s.date        = '2012-07-24'
  s.executables << 'dashing'


  s.summary     = "A simple & flexible framework for creating dashboards."
  s.description = "An elegant, simple, beautiful, & flexible framework for creating dashboards."
  s.authors     = ["Daniel Beauchamp"]
  s.email       = 'daniel.beauchamp@shopify.com'
  s.files       = ["lib/Dashing.rb"]
  s.homepage    = 'http://Dashing.shopify.com'

  s.files = Dir['README.md', 'vendor/**/*', 'templates/**/*','templates/**/.[a-z]*', 'lib/**/*']

  s.add_dependency('sass')
  s.add_dependency('coffee-script')
  s.add_dependency('sinatra')
  s.add_dependency('sinatra-contrib')
  s.add_dependency('thin')
  s.add_dependency('rufus-scheduler')
  s.add_dependency('thor')

end