require 'lambda_deployment'

module LambdaDeployment
  class CLI
    def run(args)
      parse_args(args)
      case @action
      when 'deploy'
        deploy
      when 'release'
        release
      else
        raise 'Action must be either deploy or release'
      end
    end

    private

    def config
      @config ||= LambdaDeployment::Configuration.new
    end

    def deploy
      LambdaDeployment::Lambda::Deploy.new(config).run
    end

    def release
      LambdaDeployment::Lambda::Release.new(config).run
    end

    def parse_args(args)
      config_file = 'lambda_deploy.yml'
      OptionParser.new do |opts|
        opts.banner = 'Usage: lambda_deploy [-c FILE] deploy|release'
        opts.version = LambdaDeployment::VERSION
        opts.on('-c', '--config [FILE]', 'Use specified config file') { |c| config_file = c }
      end.parse!(args)
      @action = args.shift
      config.load_config(config_file)
    end
  end
end
