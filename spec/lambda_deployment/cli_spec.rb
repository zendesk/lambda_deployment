require 'spec_helper'

SingleCov.covered!

describe LambdaDeployment::CLI do
  context 'with a specified config file' do
    before do
      stub_config('examples/lambda/lambda_deploy_dev.yml')
    end

    it 'works with the deploy action' do
      stub_deploy
      described_class.new.run(['-c', 'examples/lambda/lambda_deploy_dev.yml', 'deploy'])
    end

    it 'works with the release action' do
      stub_release
      described_class.new.run(['-c', 'examples/lambda/lambda_deploy_dev.yml', 'release'])
    end

    it 'raises an exception with another action' do
      stub_run_error(['-c', 'examples/lambda/lambda_deploy_dev.yml', 'foobar'])
    end
  end

  context 'without a specified config file' do
    before do
      stub_config('lambda_deploy.yml')
    end

    it 'works with the deploy action' do
      stub_deploy
      described_class.new.run(['deploy'])
    end

    it 'works with the release action' do
      stub_release
      described_class.new.run(['release'])
    end

    it 'raises an exception with another action' do
      stub_run_error(['foobar'])
    end
  end
end
