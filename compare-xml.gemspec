lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'compare-xml/version'

Gem::Specification.new do |spec|
  spec.name          = 'compare-xml'
  spec.version       = CompareXML::VERSION
  spec.authors       = ['Vadim Kononov']
  spec.email         = ['vadim@poetic.com']

  spec.summary       = 'A customizable tool that compares two instances of Nokogiri::XML::Node for equality or equivalency.'
  spec.description   = 'CompareXML is a fast, lightweight and feature-rich tool that will solve your XML/HTML comparison or diffing needs. its purpose is to compare two instances of Nokogiri::XML::Node or Nokogiri::XML::NodeSet for equality or equivalency.'
  spec.homepage      = 'https://github.com/vkononov/compare-xml'
  spec.license       = 'MIT'
  spec.required_ruby_version = Gem::Requirement.new('>= 2.4.0')

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(example|test|spec|features)/}) }
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'minitest'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rubocop'
  spec.add_development_dependency 'rubocop-md'
  spec.add_development_dependency 'rubocop-minitest'
  spec.add_development_dependency 'rubocop-performance'
  spec.add_development_dependency 'rubocop-rake'

  spec.add_runtime_dependency 'nokogiri'

  spec.metadata = {
    'rubygems_mfa_required' => 'true'
  }
end
