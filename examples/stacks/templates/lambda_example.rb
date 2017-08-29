SparkleFormation.new(:lambda_example) do
  parameters do
    function_name { Type 'String' }
    s3_bucket { Type 'String' }
  end

  resources do
    bucket do
      Type 'AWS::S3::Bucket'
      Properties do
        AccessControl 'Private'
        BucketName ref!(:s3_bucket)
        NotificationConfiguration do
          LambdaConfigurations [
            {
              Event: 's3:ObjectCreated:*',
              Function: ref!(:lambda_alias)
            },
            {
              Event: 's3:ObjectRemoved:*',
              Function: ref!(:lambda_alias)
            }
          ]
        end
        Tags tags!(
          name: ref!(:s3_bucket)
        )
      end
    end

    bucket_policy do
      Type 'AWS::S3::BucketPolicy'
      Properties do
        Bucket ref!(:bucket)
        PolicyDocument do
          Version '2012-10-17'
          Statement [
            {
              Action: [
                's3:*'
              ],
              Effect: 'Allow',
              Principal: {
                AWS: account_id!
              },
              Resource: [
                join!('arn:aws:s3:::', ref!(:s3_bucket)),
                join!('arn:aws:s3:::', ref!(:s3_bucket), '/*')
              ]
            }
          ]
        end
      end
    end

    lambda_role do
      Type 'AWS::IAM::Role'
      Properties do
        AssumeRolePolicyDocument do
          Version '2012-10-17'
          Statement [
            {
              Effect: 'Allow',
              Principal: {
                Service: [
                  'lambda.amazonaws.com'
                ]
              },
              Action: [
                'sts:AssumeRole'
              ]
            }
          ]
        end
        Path '/'
        Policies [
          {
            PolicyName: 'AllowLambdaPolicy',
            PolicyDocument: {
              Version: '2012-10-17',
              Statement: [
                {
                  Effect: 'Allow',
                  Action: [
                    'logs:CreateLogGroup',
                    'logs:CreateLogStream',
                    'logs:PutLogEvents'
                  ],
                  Resource: 'arn:aws:logs:*:*:*'
                }
              ]
            }
          }
        ]
      end
    end

    lambda_function do
      Type 'AWS::Lambda::Function'
      Properties do
        FunctionName ref!(:function_name)
        Handler 'example.lambda_handler'
        Timeout 3
        Role attr!(:lambda_role, :arn)
        Runtime 'python2.7'
        Code do
          ZipFile IO.read('../lambda/example.py')
        end
      end
    end

    lambda_alias do
      Type 'AWS::Lambda::Alias'
      Properties do
        FunctionName ref!(:lambda_function)
        FunctionVersion '$LATEST'
        Name 'production'
      end
    end

    lambda_permissions do
      Type 'AWS::Lambda::Permission'
      Properties do
        FunctionName ref!(:lambda_alias)
        Action 'lambda:InvokeFunction'
        Principal 's3.amazonaws.com'
        SourceArn join!('arn:aws:s3:::', ref!(:s3_bucket))
      end
    end
  end
end
