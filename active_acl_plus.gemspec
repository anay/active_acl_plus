$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "active_acl_plus/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "active_acl_plus"
  s.version     = ActiveAclPlus::VERSION
  s.authors     = ["Peter Schrammel", "Gregor Melhorn"]
  s.email       = ["peter.schrammel@gmx.de"]
  s.homepage    = "http://activeaclplus.rubyforge.org/"
  s.summary     = "A new Version of ActiveAclPlus is available."
  s.description = "A flexible, fast and easy to use generic access control system."

  s.files = Dir["{app,config,db,lib}/**/*"] + ["MIT-LICENSE", "Rakefile", "README.rdoc"]
  s.test_files = Dir["test/**/*"]

  s.add_dependency "has_many_polymorphs"

  s.add_dependency "rails", "~> 3.2.13"

  s.add_development_dependency "sqlite3"
end
