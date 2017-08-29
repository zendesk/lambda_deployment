Gem::Specification.new do |s|
  s.name        = 'lambda_deployment'
  s.version     = '0.1.0'
  s.summary     = 'Lambda Deployment Library'
  s.authors     = ['Zendesk CloudOps']
  s.email       = 'cloudops@zendesk.com'
  s.files       = Dir.glob('{bin,lib}/**/*') + ['README.md']
  s.executables = ['lambda_deploy']

  s.add_runtime_dependency 'aws-sdk-core'

  s.add_development_dependency 'rspec'
  s.add_development_dependency 'rubocop'
  s.add_development_dependency 'single_cov'
end
