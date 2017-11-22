require 'dotenv'

module LambdaDeployment
  class Configuration
    attr_reader :kms_key_arn, :file_path, :project, :region, :s3_bucket, :s3_key, :s3_sse

    def load_config(config_file)
      config = YAML.load_file(config_file)
      @project = config.fetch('project')
      @region = config.fetch('region', ENV.fetch('AWS_REGION', nil))
      @file_path = File.expand_path(config.fetch('file_name'), File.dirname(config_file))
      raise "File not found: #{@file_path}" unless File.exist?(@file_path)

      @s3_bucket = config.fetch('s3_bucket', ENV.fetch('LAMBDA_S3_BUCKET', nil))
      @s3_key = s3_key_name(config.fetch('file_name'))
      @s3_sse = config.fetch('s3_sse', ENV.fetch('LAMBDA_S3_SSE', nil))

      @config_env = config.fetch('environment', {})
      @kms_key_arn = config.fetch('kms_key_arn', ENV.fetch('LAMBDA_KMS_KEY_ARN', nil))
    end

    # lambda aliases must satisfy (?!^[0-9]+$)([a-zA-Z0-9-_]+)
    def alias_name
      tag = ENV['TAG'].to_s.gsub(/[^a-zA-Z0-9\-_]/, '')
      return nil if tag.empty?
      tag.prepend 'v' if tag =~ /^[0-9]+$/ # just a number like 123 so lets turn it into v123
      tag
    end

    def environment
      @environment_cache ||= Dir.glob('.env*').reduce({}) do |cache, filename|
        cache.merge Dotenv::Environment.new(filename)
      end.merge(@config_env)
    end

    private

    def s3_key_name(file_name)
      basename = File.basename(file_name, '.*')
      extension = File.extname(file_name)
      "#{basename}-#{ENV.fetch('TAG', 'latest')}#{extension}"
    end
  end
end
