
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'wetransfer/version'

Gem::Specification.new do |spec|
  spec.name          = 'wetransfer'
  spec.version       = WeTransfer::VERSION
  spec.authors       = ['Noah Berman']
  spec.email         = ['noah@wetransfer.com']

  spec.summary       = "A Ruby SDK for WeTransfer's Public API"
  spec.description   = "Ruby bindings for using WeTransfer's Public API."
  spec.homepage      = 'https://wetransfer.github.io'
  spec.license       = 'MIT'

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = 'https://rubygems.org'
  else
    raise 'RubyGems 2.0 or newer is required to protect against ' \
      'public gem pushes.'
  end

  spec.files = `git ls-files -z`.split("\x0").reject do |f|
    # Make sure large fixture files are not packaged with the gem every time
    f.match(%r{^spec/fixtures/})
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'faraday', '~> 0.13'

  spec.add_development_dependency 'bundler', '~> 1.16'
  spec.add_development_dependency 'pry', '~> 0.11'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'simplecov', '~> 0.15'
  spec.add_development_dependency 'wetransfer_style', '0.5.0'
end
