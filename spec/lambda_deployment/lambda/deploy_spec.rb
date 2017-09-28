require 'spec_helper'

SingleCov.covered!

describe LambdaDeployment::Lambda::Deploy do
  context 'works without a tag alias' do
    before do
      @config = LambdaDeployment::Configuration.new
      @config.load_config('examples/lambda/lambda_deploy_dev.yml')
    end

    it 'uploads a new version' do
      stub_s3_put('latest')
      stub_update_function('latest')
      described_class.new(@config).run
    end
  end

  context 'works with a tag alias' do
    around { |t| with_env(TAG: 'v123', &t) }

    before do
      @config = LambdaDeployment::Configuration.new
      @config.load_config('examples/lambda/lambda_deploy_dev.yml')
    end

    it 'uploads a new version and creates an alias' do
      stub_s3_put('v123')
      stub_update_function('v123')
      expect_any_instance_of(Aws::Lambda::Client).to receive(:publish_version).with(
        function_name: 'lambda-deploy'
      ).and_return(OpenStruct.new(version: 1))
      expect_any_instance_of(Aws::Lambda::Client).to receive(:create_alias).with(
        function_name: 'lambda-deploy',
        name: '123',
        function_version: 1
      ).and_return(nil)
      described_class.new(@config).run
    end

    it 'updates the alias if it already exists' do
      stub_s3_put('v123')
      stub_update_function('v123')
      expect_any_instance_of(Aws::Lambda::Client).to receive(:publish_version).with(
        function_name: 'lambda-deploy'
      ).and_return(OpenStruct.new(version: 1))
      expect_any_instance_of(Aws::Lambda::Client).to receive(:create_alias).with(
        function_name: 'lambda-deploy',
        name: '123',
        function_version: 1
      ).and_raise(Aws::Lambda::Errors::ResourceConflictException.new(1, 2))
      expect_any_instance_of(Aws::Lambda::Client).to receive(:update_alias).with(
        function_name: 'lambda-deploy',
        name: '123',
        function_version: 1
      )
      described_class.new(@config).run
    end

    it 'uploads a new version and creates an alias with removed characters' do
      with_env TAG: 'v1.2.3' do
        @config = LambdaDeployment::Configuration.new
        @config.load_config('examples/lambda/lambda_deploy_dev.yml')
        stub_s3_put('v1.2.3')
        stub_update_function('v1.2.3')
        expect_any_instance_of(Aws::Lambda::Client).to receive(:publish_version).with(
          function_name: 'lambda-deploy'
        ).and_return(OpenStruct.new(version: 1))
        expect_any_instance_of(Aws::Lambda::Client).to receive(:create_alias).with(
          function_name: 'lambda-deploy',
          name: '123',
          function_version: 1
        ).and_return(nil)
        described_class.new(@config).run
      end
    end
  end
end
