$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "planner_kansa/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "planner_kansa"
  s.version     = PlannerKansa::VERSION
  s.authors     = ['Henry Balen', 'Ruth Leibig', 'Ian Stockdale']
  s.email       = ['info@grenadine.co']
  s.licenses    = ['Apache']
  s.homepage    = 'http://www.myconferenceplanning.org'
  s.summary     = 'Integration with the W75 Kansa membership system.'
  s.description = 'Integration with the W75 Kansa membership system.'

  s.files       = Dir['{app,config,db,lib}/**/*'] + %w(LICENSE Rakefile)
  s.platform    = Gem::Platform::RUBY
  s.test_files = Dir["spec/**/*"]

  s.add_dependency "rails", "~> 3.2.22.5"
  s.add_dependency "globalize", "~> 3.1.0"
  s.add_dependency 'planner-core'

  s.add_development_dependency "sqlite3"
end
