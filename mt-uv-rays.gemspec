require File.expand_path("../lib/mt-uv-rays/version", __FILE__)

Gem::Specification.new do |gem|
    gem.name          = "mt-uv-rays"
    gem.version       = MTUV::VERSION
    gem.license       = 'MIT'
    gem.authors       = ["Giallombardo Nathan"]
    gem.email         = ["nathan.giallombardo@mapotempo.com"]
    gem.homepage      = "https://github.com/mapotempo/mt-uv-rays"
    gem.summary       = "Abstractions for working with Libuv"
    gem.description   = "Opinionated abstractions for Libuv"

    gem.required_ruby_version = '>= 2.0.0'
    gem.require_paths = ["lib"]

    gem.add_runtime_dependency     'mt-libuv', '~> 4.1', '>= 4.1.02' # Evented IO
    gem.add_runtime_dependency     'bisect', '~> 0.1'                # Sorted insertion
    gem.add_runtime_dependency     'tzinfo', '~> 1.2'                # Ruby timezones info
    gem.add_runtime_dependency     'cookiejar', '~> 0.3'             # HTTP cookies
    gem.add_runtime_dependency     'ipaddress', '~> 0.8'             # IP address validation
    gem.add_runtime_dependency     'parse-cron', '~> 0.1'            # CRON calculations
    gem.add_runtime_dependency     'addressable', '~> 2.4'           # URI parser
    gem.add_runtime_dependency     'http-parser', '~> 1.2'           # HTTP tokeniser
    gem.add_runtime_dependency     'activesupport', '>= 4', '< 6'

    # HTTP authentication helpers
    gem.add_runtime_dependency     'rubyntlm', '~> 0.6'
    gem.add_runtime_dependency     'net-http-digest_auth', '~> 1.4'

    gem.add_development_dependency 'rspec', '~> 3.5'
    gem.add_development_dependency 'rake', '~> 11.2'
    gem.add_development_dependency 'yard', '~> 0.9'
    gem.add_development_dependency 'httpi', '~> 2.4.2'

    gem.files = Dir["{lib}/**/*"] + %w(Rakefile mt-uv-rays.gemspec README.md LICENSE)
    gem.test_files = Dir["spec/**/*"]
    gem.extra_rdoc_files = ["README.md"]
end
