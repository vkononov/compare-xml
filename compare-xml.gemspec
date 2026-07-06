require_relative 'lib/compare-xml/version'

Gem::Specification.new do |spec|
  spec.name = 'compare-xml'
  spec.version = CompareXML::VERSION
  spec.authors = ['Vadim Kononov']
  spec.email = ['vadim@konoson.com']

  spec.summary = 'A customizable tool that compares two instances of Nokogiri::XML::Node for equality or equivalency.'
  spec.description = 'CompareXML is a fast, lightweight and feature-rich tool that will solve your XML/HTML comparison or diffing needs. its purpose is to compare two instances of Nokogiri::XML::Node or Nokogiri::XML::NodeSet for equality or equivalency.'
  spec.homepage = 'https://github.com/vkononov/compare-xml'
  spec.license = 'MIT'
  spec.required_ruby_version = '>= 2.4.0'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage
  spec.metadata['changelog_uri'] = "#{spec.homepage}/releases"

  # Ship only what the gem needs at runtime: the library code plus the license
  # and readme. Using an allowlist keeps tests, tooling, CI config, and images
  # out of the package even as new development files are added over time.
  root_files = %w[LICENSE.txt README.md]
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).select do |f|
      f.start_with?('lib/') || root_files.include?(f)
    end
  end
  spec.bindir = 'exe'
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  # Uncomment to register a new dependency of your gem
  spec.add_dependency 'nokogiri', '>= 1.6'

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
  spec.metadata['rubygems_mfa_required'] = 'true'
end
