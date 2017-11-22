require 'spec_helper'
require 'rspec/support/spec/shell_out'

SingleCov.covered!

describe LambdaDeployment::Client do
  include RSpec::Support::ShellOut

  let(:client) { described_class.new('us-east-1') }

  it 'builds a client for kms' do
    expect(client.kms_client).to be_a(Aws::KMS::Client)
  end

  it 'builds a client for lambda' do
    expect(client.lambda_client).to be_a(Aws::Lambda::Client)
  end

  it 'builds a client for s3' do
    expect(client.s3_client).to be_a(Aws::S3::Client)
  end

  it 'builds a client with roles when given' do
    expect(Aws::AssumeRoleCredentials).to receive(:new).and_return('Foo')
    with_env 'LAMBDA_ASSUME_ROLE' => 'some-role' do
      expect(client.send(:config)[:credentials]).to eq('Foo')
    end
  end
end
