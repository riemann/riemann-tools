# frozen_string_literal: true

require 'riemann/tools'

module Riemann
  module Tools
    module Aws
      class Billing
        include Riemann::Tools
        require 'fog/aws'

        opt :fog_credentials_file, 'Fog credentials file', type: String
        opt :fog_credential, 'Fog credentials to use', type: String

        opt :access_key, 'AWS access key', type: String
        opt :secret_key, 'Secret access key', type: String
        opt :services, 'AWS services: AmazonEC2  AmazonS3  AWSDataTransfer', type: :strings, multi: true,
          default: %w[AmazonEC2 AmazonS3 AWSDataTransfer]

        opt :time_start, 'Start time in seconds of the metrics period (2hrs ago default)', type: Integer, default: 7200
        opt :time_end, 'End time in seconds of the metrics period ', type: Integer, default: 60

        def initialize
          if opts[:fog_credentials_file]
            Fog.credentials_path = opts[:fog_credentials_file]
            Fog.credential = opts[:fog_credential].to_sym
            @cloudwatch = Fog::AWS::CloudWatch.new
          else
            creds = if opts.key?('secret_key') && opts.key?('access_key')
                      {
                        aws_secret_access_key: opts[:secret_key],
                        aws_access_key_id: opts[:access_key],
                      }
                    else
                      { use_iam_profile: true }
                    end
            @cloudwatch = Fog::AWS::CloudWatch.new(creds)
          end
          @start_time = (Time.now.utc - opts[:time_start]).iso8601
          @end_time = (Time.now.utc - opts[:time_end]).iso8601
        end

        def tick
          opts[:services].each do |service|
            data = @cloudwatch.get_metric_statistics({
                                                       'Statistics' => ['Maximum'],
                                                       'StartTime'  => @start_time,
                                                       'EndTime'    => @end_time,
                                                       'Period'     => 3600,
                                                       'Unit'       => 'None',
                                                       'MetricName' => 'EstimatedCharges',
                                                       'Namespace'  => 'AWS/Billing',
                                                       'Dimensions' => [
                                                         {
                                                           'Name'  => 'ServiceName',
                                                           'Value' => service,
                                                         },
                                                         {
                                                           'Name'  => 'Currency',
                                                           'Value' => 'USD',
                                                         },
                                                       ],
                                                     }).body['GetMetricStatisticsResult']['Datapoints']

            data.each do |metrics|
              name = "AWScloudwatch.Billing.#{service}"
              value = metrics['Maximum']
              timestamp = metrics['Timestamp'].to_i

              event = {
                host: nil,
                service: name,
                time: timestamp,
                description: "AWS Estimate Charges for #{service}",
                tags: ['aws_billing'],
                state: 'ok',
                metric: value,
              }

              report event
            end
          end
        end
      end
    end
  end
end
