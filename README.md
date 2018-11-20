# lambda_deployment
Ruby gem for deploying lambda functions in AWS with Samson or another tool.
**This gem is used to update the function code only** - the resources must
already be provisioned using another tool (or manually).

[![Build Status](https://travis-ci.org/zendesk/lambda_deployment.svg?branch=master)](https://travis-ci.org/zendesk/lambda_deployment)

## Usage
This gem provides a binary called `lambda_deploy` which will deploy a zip or
jar file to lambda, version it, and promote it to production (release).
Usage:
```
lambda_deploy [-c path/to/configuration.yml] deploy|release
```

### Deploy action
The deploy action will optionally upload the function to S3 if a zip/jar file is configured.
If no file is provided then the script will assume that it was already uploaded to S3 by some
other mean (GCR build for instance) and proceed with the update. It will then update the
function to use the new code. If the environmental variable `TAG` is set it will also
create a version and link that version to an alias named `TAG`.

### Release action
The release action will link the `production` alias to the version referenced
by the `TAG` alias. **If `TAG` is not set this action is only required if the
`production` alias is not already pointing to `$LATEST`.**

## Environmental variables
The configuration file is intentionally small with the option to override
environmental variables. The default action is to fetch values from the
environment to ensure consistency within a given environment. These variables
should be set within the deploy tool or using the configuration file.

### AWS_REGION (required)
Region in AWS where resources are located.

### LAMBDA_ASSUME_ROLE (optional)
STS assume role to use if resources are in another account.

### LAMBDA_S3_BUCKET (required)
Name of S3 bucket to upload function to. Buckets can be provisioned per project
or per environment.

### LAMBDA_S3_SSE (optional)
Type of encryption to use with S3.

### TAG (optional)
Version of the function being uploaded (e.g. git tag).

## Quickstart Guide
See the `examples/lambda` directory for a sample project layout.

### Add the gem to your project
Add the following line to your `Gemfile` and run `bundle install`:
```
gem 'lambda_deployment'
```

### Create a lambda_deploy.yml configuration file
The only required fields are the project name (the function name in AWS), and
the zip or jar file to upload (containing at least the script named after the
lambda_function).

Here is an example:
```
file_name: lambda/foobar.zip  # required: zip or jar of lambda function and dependencies
project: my-dev-lambda-name   # required: name of lambda function
region: us-east-1             # optional: specify AWS region (will override $AWS_REGION)
s3_bucket: my-test-bucket     # optional: specify s3 bucket (will override $LAMBDA_S3_BUCKET)
s3_sse: AES256                # optional: set server side encryption on s3 objects (will override $LAMBDA_S3_SSE)
concurrency:                  # optional: set reserved concurrency limit (-1 to delete)
environment:
  FOO: bar                    # optional: set some env vars for your Lambda
```

* *file_name* is the key that will be used to store the code archive on S3. If the code needs to be uploaded
as part of the deploy process, the file_name needs to be the path relative to the configuration file
* *project* must match the function name in the AWS console (the last value in
the following example):
```
arn:aws:lambda:<region>:<account_id>:function:<project>
```

### Create lambda function and s3 bucket
The lambda function and s3 buckets must already exist to use this gem. If you
are creating actions for your lambda make sure they execute the `production`
alias (see below). To do this append `:production` to the end of the ARN
associated with your lambda function.

### Create `production` alias for lambda function
In the lambda console chose *Create alias* from the *Actions* drop down. The
name should be `production` and version should point to `$LATEST`.
