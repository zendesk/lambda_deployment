require 'spec_helper'

SingleCov.covered! uncovered: 3

describe LambdaDeployment::Lambda::Deploy do
  context 'works without a tag alias' do
    before do
      @config = LambdaDeployment::Configuration.new
      @config.load_config('examples/lambda/lambda_deploy_dev.yml')
    end

    it 'uploads a new version' do
      stub_s3_put('latest')
      stub_update_function('latest')
      stub_update_function_configuration('FOO' => 'bar')
      described_class.new(@config).run
    end
  end

  context 'works with a tag alias' do
    around { |t| with_env(TAG: 'v123', &t) }

    before do
      @config = LambdaDeployment::Configuration.new
      @config.load_config('examples/lambda/lambda_deploy_dev.yml')
      stub_update_function_configuration('FOO' => 'bar')
    end

    it 'uploads a new version and creates an alias' do
      stub_s3_put('v123')
      stub_update_function('v123')
      expect_any_instance_of(Aws::Lambda::Client).to receive(:publish_version).with(
        function_name: 'lambda-deploy'
      ).and_return(OpenStruct.new(version: 1))
      expect_any_instance_of(Aws::Lambda::Client).to receive(:create_alias).with(
        function_name: 'lambda-deploy',
        name: 'v123',
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
        name: 'v123',
        function_version: 1
      ).and_raise(Aws::Lambda::Errors::ResourceConflictException.new(1, 2))
      expect_any_instance_of(Aws::Lambda::Client).to receive(:update_alias).with(
        function_name: 'lambda-deploy',
        name: 'v123',
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
          name: 'v123',
          function_version: 1
        ).and_return(nil)
        described_class.new(@config).run
      end
    end
  end

  context 'with a specified kms key' do
    around { |t| with_env(LAMBDA_KMS_KEY_ARN: 'foobar-key-123', &t) }

    it 'encrypts environment variables' do
      @config = LambdaDeployment::Configuration.new
      @config.load_config('examples/lambda/lambda_deploy_dev.yml')
      stub_s3_put('latest')
      stub_update_function('latest')
      expect_any_instance_of(Aws::KMS::Client).to receive(:encrypt).with(
        key_id: 'foobar-key-123',
        plaintext: 'bar'
      ).and_return(OpenStruct.new(ciphertext_blob: 'bar-encrypted'))
      expect(Base64).to receive(:encode64).with('bar-encrypted').and_return('bar-encoded')
      stub_update_function_configuration({ 'FOO' => 'bar' }, 'foobar-key-123')
      described_class.new(@config).run
    end
  end
end
