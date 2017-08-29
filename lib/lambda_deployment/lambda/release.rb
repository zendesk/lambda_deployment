module LambdaDeployment
  module Lambda
    class Release
      def initialize(config)
        @config = config
        @client = LambdaDeployment::Client.new(config.region)
      end

      def run
        version = version_for_tag
        update_production_alias(version)
      end

      private

      def version_for_tag
        if @config.alias_name
          @client.lambda_client.get_alias(
            function_name: @config.project,
            name: @config.alias_name
          ).function_version
        else
          '$LATEST'
        end
      end

      def update_production_alias(version)
        @client.lambda_client.update_alias(
          function_name: @config.project,
          function_version: version,
          name: 'production'
        )
      end
    end
  end
end
