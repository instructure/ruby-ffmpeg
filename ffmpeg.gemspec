# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift lib unless $LOAD_PATH.include?(lib)

require 'ffmpeg/version'

Gem::Specification.new do |s|
  s.name        = 'ffmpeg'
  s.version     = FFMPEG::VERSION
  s.authors     = ['Instructure']
  s.email       = ['support@instructure.com']
  s.homepage    = 'https://github.com/instructure/ffmpeg'
  s.summary     = 'Wraps ffmpeg to read metadata and transcodes videos.'

  s.required_ruby_version = '>= 3.0'

  s.add_dependency('multi_json', '~> 1.8')

  s.add_development_dependency('rake', '~> 13.2')
  s.add_development_dependency('rspec', '~> 3.13')
  s.add_development_dependency('rubocop', '~> 1.63')
  s.add_development_dependency('simplecov', '~> 0.22')
  s.add_development_dependency('webmock', '~> 3.23')
  s.add_development_dependency('webrick', '~> 1.8')

  s.files = Dir.glob('lib/**/*') + %w[README.md LICENSE CHANGELOG]
  s.metadata['rubygems_mfa_required'] = 'true'
end
