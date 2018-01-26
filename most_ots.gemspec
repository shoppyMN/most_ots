lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'most_ots/version'

Gem::Specification.new do |spec|
  spec.name = 'most_ots'
  spec.version = MostOts::VERSION
  spec.authors = ['Gundsambuu Natsagdorj']
  spec.email = ['ssxenon01@gmail.com']

  spec.summary = 'Most Money External Protocol'
  # spec.description = 'TODO: Write a longer description or delete this line.'
  spec.homepage = 'https://github.com/ssxenon01/most_ots'
  spec.license = 'MIT'
  spec.required_ruby_version = '>= 2.0'
  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  # if spec.respond_to?(:metadata)
  #   spec.metadata['allowed_push_host'] = "TODO: Set to 'http://mygemserver.com'"
  # else
  #   raise 'RubyGems 2.0 or newer is required to protect against public gem pushes.'
  # end

  spec.files = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir = 'exe'
  spec.executables = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_runtime_dependency 'httparty', '>= 0', '>= 0'
  spec.add_runtime_dependency 'openssl', '>= 0', '>= 0'

  spec.add_development_dependency 'bundler', '~> 1.16'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
end
