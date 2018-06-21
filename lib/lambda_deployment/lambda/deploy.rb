module LambdaDeployment
  module Lambda
    class Deploy
      def initialize(config)
        @config = config
        @client = LambdaDeployment::Client.new(config.region)
      end

      def run
        upload_to_s3
        update_function_code
        update_environment
        update_concurrency
        return unless @config.alias_name
        version = publish_version
        begin
          create_alias(version)
        rescue Aws::Lambda::Errors::ResourceConflictException
          update_alias(version)
        end
      end

      private

      def upload_to_s3
        @client.s3_client.put_object(
          body: File.read(@config.file_path),
          bucket: @config.s3_bucket,
          key: @config.s3_key,
          server_side_encryption: @config.s3_sse
        )
      end

      def update_function_code
        @client.lambda_client.update_function_code(
          function_name: @config.project,
          s3_bucket: @config.s3_bucket,
          s3_key: @config.s3_key
        )
      end

      def update_concurrency
        return unless @config.concurrency
        # Allow a value of -1 to remove concurrency limit
        if @config.concurrency == -1
          @client.delete_function_concurrency(function_name: @config.project)
        else
          @client.put_function_concurrency(
            function_name: @config.project,
            reserved_concurrent_executions: @config.concurrency
          )
        end
      end

      def update_environment
        environment = {}
        @config.environment.map { |k, v| environment[k] = encrypt(v) }
        @client.lambda_client.update_function_configuration(
          function_name: @config.project,
          kms_key_arn: @config.kms_key_arn,
          environment: {
            variables: environment
          }
        )
      end

      def encrypt(value)
        return value unless @config.kms_key_arn
        Base64.encode64(
          @client.kms_client.encrypt(
            key_id: @config.kms_key_arn,
            plaintext: value
          ).ciphertext_blob
        )
      end

      def publish_version
        @client.lambda_client.publish_version(
          function_name: @config.project
        ).version
      end

      def create_alias(version)
        @client.lambda_client.create_alias(alias_params(version))
      end

      def update_alias(version)
        @client.lambda_client.update_alias(alias_params(version))
      end

      def alias_params(version)
        {
          function_name: @config.project,
          name: @config.alias_name,
          function_version: version
        }
      end
    end
  end
end
