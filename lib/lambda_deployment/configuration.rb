module LambdaDeployment
  class Configuration
    attr_reader :file_path, :project, :region, :s3_bucket, :s3_key, :s3_sse

    # https://github.com/bkeepers/dotenv/blob/a47020f6c414e0a577680b324e61876a690d2200/lib/dotenv/parser.rb#L14
    LINE_RE = /
      \A
      \s*
      (?:export\s+)?    # optional export
      ([\w\.]+)         # key
      (?:\s*=\s*|:\s+?) # separator
      (                 # optional value begin
        '(?:\'|[^'])*'  #   single quoted value
        |               #   or
        "(?:\"|[^"])*"  #   double quoted value
        |               #   or
        [^#\n]+         #   unquoted value
      )?                # value end
      \s*
      (?:\#.*)?         # optional comment
      \z
    /x

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
    end

    # lambda aliases must satisfy (?!^[0-9]+$)([a-zA-Z0-9-_]+)
    def alias_name
      tag = ENV['TAG'].to_s.gsub(/[^a-zA-Z0-9\-_]/, '')
      return nil if tag.empty?
      tag.prepend 'v' if tag =~ /^[0-9]+$/ # just a number like 123 so lets turn it into v123
      tag
    end

    def environment
      @environment ||= calculate_environment_vars
    end

    private

    def s3_key_name(file_name)
      basename = File.basename(file_name, '.*')
      extension = File.extname(file_name)
      "#{basename}-#{ENV.fetch('TAG', 'latest')}#{extension}"
    end

    def calculate_environment_vars
      Dir.glob('.env.*') do |filename|
        File.open(filename).each do |line|
          if (match = line.match(LINE_RE))
            key, value = match.captures
            @config_env[key] = value.strip
          end
        end
      end
      @config_env
    end
  end
end
