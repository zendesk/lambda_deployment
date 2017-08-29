# Examples
Here you will find some examples to get started with the `lambda_deployment`
gem.

## Lambda
In this directory there is a minimal configuration file as well as one with all
accepted parameters. There is also a sample function packaged in a zip and the
python source code. After modifying `lambda_deploy.yml` to point to a valid S3
bucket you can deploy the function using the following commands:
```
bundle install
bundle exec lambda_deploy deploy
```

## Stacks
Here you will find [SparkleFormation](https://github.com/sparkleformation/sparkle_formation)
templates and parameters that can be used to create the resources needed to try
out the example configuration and lambda. This example is using a gem called
[StackMaster](https://github.com/envato/stack_master) to send the template and
parameters to CloudFormation. Simply edit `parameters/lambda_example.yml` and
add a valid name for the `s3_bucket` parameter then deploy it with the
following commands:
```
bundle install
bundle exec stack_master apply
```
