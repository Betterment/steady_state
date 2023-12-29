$LOAD_PATH.push File.expand_path('lib', __dir__)

require 'steady_state/version'

Gem::Specification.new do |s|
  s.name = 'steady_state'
  s.version = SteadyState::VERSION
  s.authors = ['Nathan Griffith']
  s.email = ['nathan@betterment.com']
  s.summary = 'Minimalist state management via "an enum with guard rails"'
  s.description = <<~DESC
    A minimalist approach to managing object state,
    perhaps best described as "an enum with guard rails."
    Designed to work with `ActiveRecord` and `ActiveModel` classes,
    or anywhere where Rails validations are used.
  DESC
  s.metadata = {
    'rubygems_mfa_required' => 'true',
  }

  s.files = Dir['{app,config,db,lib}/**/*', 'LICENSE', 'Rakefile', 'README.md']
  s.test_files = Dir['spec/**/*']

  s.required_ruby_version = '>= 3.0'

  s.add_dependency 'activemodel', '>= 5.2'
  s.add_dependency 'activesupport', '>= 5.2'

  s.add_development_dependency 'appraisal'
  s.add_development_dependency 'betterlint'
  s.add_development_dependency 'rake'
  s.add_development_dependency 'rspec'
end
