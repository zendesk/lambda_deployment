require 'bundler/setup'

require 'single_cov'
SingleCov.setup :rspec

require 'lambda_deployment'
require 'tempfile'

module HelperMethods
  def create_temp_config(content)
    config_file = Tempfile.new('lambda_deploy_spec')
    File.write config_file.path, content
    config_file.path
  end

  def stub_config(file)
    expect_any_instance_of(LambdaDeployment::Configuration).to receive(:load_config).with(file).and_return(nil)
  end

  def stub_deploy
    expect_any_instance_of(LambdaDeployment::Lambda::Deploy).to receive(:run).and_return(nil)
  end

  def stub_release
    expect_any_instance_of(LambdaDeployment::Lambda::Release).to receive(:run).and_return(nil)
  end

  def stub_run_error(args)
    expect { described_class.new.run(args) }.to raise_error(RuntimeError, 'Action must be either deploy or release')
  end

  def stub_s3_put(version)
    expect_any_instance_of(Aws::S3::Client).to receive(:put_object).with(
      body: File.read('examples/lambda/example.zip'),
      bucket: 'my-test-bucket',
      key: "example-#{version}.zip",
      server_side_encryption: 'AES256'
    ).and_return(nil)
  end

  def stub_update_alias(options)
    expect_any_instance_of(Aws::Lambda::Client).to receive(:update_alias).with(options).and_return(nil)
  end

  def stub_update_function(version)
    expect_any_instance_of(Aws::Lambda::Client).to receive(:update_function_code).with(
      function_name: 'lambda-deploy',
      s3_bucket: 'my-test-bucket',
      s3_key: "example-#{version}.zip"
    ).and_return(nil)
  end

  def with_env(env)
    old = ENV.to_h
    env.each { |k, v| ENV[k.to_s] = v }
    yield
  ensure
    ENV.replace(old)
  end
end

RSpec.configure do |c|
  c.default_formatter = 'documentation'
  c.include HelperMethods
end
