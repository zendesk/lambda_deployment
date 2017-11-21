require 'spec_helper'

SingleCov.covered!

describe LambdaDeployment::Configuration do
  context 'it loads all configuration from a file' do
    before do
      @config = described_class.new
      @config.load_config('examples/lambda/lambda_deploy_dev.yml')
    end

    it 'sets the project name' do
      expect(@config.project).to eq('lambda-deploy')
    end

    it 'sets the correct file path' do
      expect(@config.file_path).to eq(
        File.expand_path('example.zip', File.dirname('examples/lambda/lambda_deploy_dev.yml'))
      )
    end

    it 'sets the region specified' do
      expect(@config.region).to eq('us-west-2')
    end

    it 'sets the s3 bucket' do
      expect(@config.s3_bucket).to eq('my-test-bucket')
    end

    it 'sets the s3 key to latest' do
      expect(@config.s3_key).to eq('example-latest.zip')
    end

    it 'configures server side encryption' do
      expect(@config.s3_sse).to eq('AES256')
    end

    it 'loads the environment variables' do
      expect(@config.environment).to eq('FOO' => 'bar')
    end
  end

  context 'it loads the configuration from env' do
    around do |t|
      with_env(
        AWS_REGION: 'us-west-2',
        LAMBDA_S3_BUCKET: 'my-test-bucket-2',
        LAMBDA_S3_SSE: 'AES256',
        TAG: 'v123',
        &t
      )
    end

    before do
      @config = described_class.new
      @config.load_config('examples/lambda/lambda_deploy.yml')
    end

    it 'sets the project name' do
      expect(@config.project).to eq('lambda-deploy')
    end

    it 'sets the correct file path' do
      expect(@config.file_path).to eq(
        File.expand_path('example.zip', File.dirname('examples/lambda/lambda_deploy_dev.yml'))
      )
    end

    it 'sets the region from env' do
      expect(@config.region).to eq('us-west-2')
    end

    it 'sets the s3 bucket from env' do
      expect(@config.s3_bucket).to eq('my-test-bucket-2')
    end

    it 'sets the s3 key to the tag' do
      expect(@config.s3_key).to eq('example-v123.zip')
    end

    it 'configures server side encryption' do
      expect(@config.s3_sse).to eq('AES256')
    end
  end

  context 'it loads environment vars from .env files' do
    before do
      File.open('.env.test', 'w') do |file|
        file.write 'BAZ=qux'
      end
      @config = described_class.new
      @config.load_config('examples/lambda/lambda_deploy_dev.yml')
    end

    after do
      File.delete '.env.test'
    end

    it 'loads the environment from both YAML and .env' do
      expect(@config.environment).to eq('FOO' => 'bar', 'BAZ' => 'qux')
    end
  end

  context 'it is missing required parameters' do
    it 'raises an error when the project is not specified' do
      config_file = create_temp_config("file_name: foo.zip\n")
      expect { described_class.new.load_config(config_file) }.to raise_error(
        KeyError,
        'key not found: "project"'
      )
    end

    it 'raises an error when the file does not exist' do
      config_file = create_temp_config("project: my-lambda-name\nfile_name: foo.zip\n")
      expect { described_class.new.load_config(config_file) }.to raise_error(
        RuntimeError,
        "File not found: #{File.expand_path('foo.zip', File.dirname(config_file))}"
      )
    end
  end

  describe '#alias_name' do
    def name(tag)
      with_env TAG: tag do
        LambdaDeployment::Configuration.new.alias_name
      end
    end

    it 'ignores unset' do
      expect(name(nil)).to eq nil
    end

    it 'leaves nice names alone' do
      expect(name('foo')).to eq 'foo'
    end

    it 'coverts pure numbers' do
      expect(name('~212')).to eq 'v212'
    end

    it 'leaves names with numbers' do
      expect(name('V1.2.3.beta')).to eq 'V123beta'
    end
  end
end
