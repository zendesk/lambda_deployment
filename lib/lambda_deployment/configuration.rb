module LambdaDeployment
  class Configuration
    attr_reader :file_path, :project, :region, :s3_bucket, :s3_key, :s3_sse

    def load_config(config_file)
      config = YAML.load_file(config_file)
      @project = config.fetch('project')
      @region = config.fetch('region', ENV.fetch('AWS_REGION', nil))
      @file_path = File.expand_path(config.fetch('file_name'), File.dirname(config_file))
      raise "File not found: #{@file_path}" unless File.exist?(@file_path)

      @s3_bucket = config.fetch('s3_bucket', ENV.fetch('LAMBDA_S3_BUCKET', nil))
      @s3_key = s3_key_name(config.fetch('file_name'))
      @s3_sse = config.fetch('s3_sse', ENV.fetch('LAMBDA_S3_SSE', nil))
    end

    def alias_name
      # lambda aliases only allow select characters in the name so this strips them out
      # Member must satisfy regular expression pattern: (?!^[0-9]+$)([a-zA-Z0-9-_]+)
      ENV['TAG'].to_s.gsub(/[^\da-zA-Z\-_]/, '')[/([0-9]+)([a-zA-Z0-9\-_]+)/]
    end

    private

    def s3_key_name(file_name)
      basename = File.basename(file_name, '.*')
      extension = File.extname(file_name)
      "#{basename}-#{ENV.fetch('TAG', 'latest')}#{extension}"
    end
  end
end
