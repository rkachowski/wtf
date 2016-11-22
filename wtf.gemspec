# -*- encoding: utf-8 -*-

require File.dirname(__FILE__) + "/lib/wtf/version"

Gem::Specification.new do |gem|
  gem.name          = "wooga_wtf"
  gem.version       = Wtf::VERSION
  gem.summary       = "Test tool for wooget unity projects"
  gem.description   = "Generates projects, builds + deploys them and collates the results"
  gem.authors       = ["Donald Hutchison"]
  gem.email         = ["donald.hutchison@wooga.net"]
  gem.homepage      = "https://github.com/wooga/wtf"
  gem.license       = "MIT"

  gem.files         = Dir["{**/}{.*,*}"].select{ |path| File.file?(path) && path !~ /^[pkg|scrap]/ }
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.required_ruby_version = "~> 2.0"
  gem.add_runtime_dependency "thor", "~> 0.19"
  gem.add_runtime_dependency "rake","~> 10.5"
  gem.add_runtime_dependency "wooga_wooget"
  gem.add_runtime_dependency "waitutil"
  gem.add_runtime_dependency "CFPropertyList", "2.2.8"
  gem.add_runtime_dependency "nokogiri"
  gem.add_runtime_dependency "rubyzip"
  gem.add_runtime_dependency "pry-byebug", "3.1.0"
  gem.add_runtime_dependency "httpclient", "~> 2.8"

gem.add_runtime_dependency 'activesupport-json_encoder'

  gem.add_development_dependency "rake", "10.5.0"
  gem.add_development_dependency "octokit"
  gem.add_development_dependency "minitest"


  gem.metadata['allowed_push_host'] = 'http://gem.sdk.wooga.com'
  gem.required_ruby_version = "~> 2.0"
  gem.post_install_message = Wtf::POST_INSTALL
end

