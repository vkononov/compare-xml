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

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_runtime_dependency 'nokogiri', '~> 1.8'
end
