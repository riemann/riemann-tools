# frozen_string_literal: true

require 'riemann/tools'

module Riemann
  module Tools
    module AWS
      class RDSStatus
        include Riemann::Tools
        require 'fog/aws'
        require 'date'
        require 'time'
        require 'json'

        opt :access_key, 'AWS access key', type: String
        opt :secret_key, 'Secret access key', type: String
        opt :region, 'AWS region', type: String, default: 'eu-west-1'
        opt :dbinstance_identifier, 'DBInstanceIdentifier', type: String
        def initialize
          abort 'FATAL: specify a DB instance name, see --help for usage' unless opts[:dbinstance_identifier]
          creds = if opts[:access_key] && opts[:secret_key]
                    {
                      aws_access_key_id: opts[:access_key],
                      aws_secret_access_key: opts[:secret_key],
                    }
                  else
                    { use_iam_profile: true }
                  end
          creds['region'] = opts[:region]
          @cloudwatch = Fog::AWS::CloudWatch.new(creds)
        end

        def tick
          time = Time.new
          %w[DatabaseConnections FreeableMemory FreeStorageSpace NetworkReceiveThroughput
             NetworkTransmitThroughput ReadThroughput CPUUtilization].each do |metric|
            result = @cloudwatch.get_metric_statistics(
              'Namespace'  => 'AWS/RDS',
              'MetricName' => metric.to_s,
              'Statistics' => 'Average',
              'Dimensions' => [{ 'Name' => 'DBInstanceIdentifier', 'Value' => opts[:dbinstance_identifier].to_s }],
              'StartTime'  => (time - 120).to_time.iso8601,
              'EndTime'    => time.to_time.iso8601, 'Period' => 60,
            )
            metrics_result = result.data[:body]['GetMetricStatisticsResult']
            next unless metrics_result['Datapoints'].length.positive?

            datapoint = metrics_result['Datapoints'][0]
            ev = {
              metric: datapoint['Average'],
              service: "#{opts[:dbinstance_identifier]}.#{metric} (#{datapoint['Unit']})",
              description: JSON.dump(metrics_result),
              state: 'ok',
              ttl: 300,
            }

            report ev
          end
        end
      end
    end
  end
end
