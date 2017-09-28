require 'spec_helper'

SingleCov.covered!

describe LambdaDeployment::Lambda::Release do
  context 'works without a tag alias' do
    before do
      @config = LambdaDeployment::Configuration.new
      @config.load_config('examples/lambda/lambda_deploy_dev.yml')
    end

    it 'updates the production alias to $LATEST' do
      stub_update_alias(function_name: 'lambda-deploy', function_version: '$LATEST', name: 'production')
      described_class.new(@config).run
    end
  end

  context 'works with a tag alias' do
    around { |t| with_env(TAG: 'v123', &t) }
    before do
      @config = LambdaDeployment::Configuration.new
      @config.load_config('examples/lambda/lambda_deploy_dev.yml')
    end

    it 'updates the production alias to the specified tag' do
      expect_any_instance_of(Aws::Lambda::Client).to receive(:get_alias).with(
        function_name: 'lambda-deploy',
        name: 'v123'
      ).and_return(OpenStruct.new(function_version: 1))
      stub_update_alias(function_name: 'lambda-deploy', name: 'production', function_version: 1)
      described_class.new(@config).run
    end
  end
end
