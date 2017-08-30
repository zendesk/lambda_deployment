module LambdaDeployment
  class Client
    def initialize(region)
      @region = region
    end

    def lambda_client
      @lambda_client ||= Aws::Lambda::Client.new(config)
    end

    def s3_client
      @s3_client ||= Aws::S3::Client.new(config)
    end

    private

    def config
      config = { region: @region }
      if role_arn
        config[:credentials] = Aws::AssumeRoleCredentials.new(
          role_arn: role_arn,
          role_session_name: SecureRandom.hex(10)
        )
      end
      config
    end

    def role_arn
      ENV.fetch('LAMBDA_ASSUME_ROLE', false)
    end
  end
end
