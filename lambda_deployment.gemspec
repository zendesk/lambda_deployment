require_relative 'lib/lambda_deployment/version'

Gem::Specification.new do |s|
  s.name        = 'lambda_deployment'
  s.version     = LambdaDeployment::VERSION
  s.summary     = 'Lambda Deployment Library'
  s.authors     = ['Zendesk CloudOps']
  s.files       = Dir.glob('{bin,lib}/**/*') + ['README.md']
  s.homepage    = 'https://github.com/zendesk/lambda_deployment'
  s.licenses    = ['Apache-2.0']
  s.executables = ['lambda_deploy']

  s.add_runtime_dependency 'aws-sdk-core', '~> 2'
  s.add_runtime_dependency 'dotenv', '~> 2'

  s.add_development_dependency 'rspec'
  s.add_development_dependency 'rubocop'
  s.add_development_dependency 'single_cov'
  s.add_development_dependency 'bump'
  s.add_development_dependency 'forking_test_runner'
end
