# frozen_string_literal: true

require 'riemann/tools'

module Riemann
  module Tools
    module Aws
      class ElbMetrics
        include Riemann::Tools
        require 'fog/aws'
        require 'time'

        opt :fog_credentials_file, 'Fog credentials file', type: String
        opt :fog_credential, 'Fog credentials to use', type: String
        opt :access_key, 'AWS Access Key', type: String
        opt :secret_key, 'AWS Secret Key', type: String
        opt :region, 'AWS Region', type: String, default: 'eu-west-1'
        opt :azs, 'List of AZs to aggregate against', type: :strings, default: ['all_az']
        opt :elbs, 'List of ELBs to pull metrics from', type: :strings, required: true

        def standard_metrics
          # ELB metric types, from:
          # http://docs.aws.amazon.com/AmazonCloudWatch/latest/DeveloperGuide/CW_Support_For_AWS.html#elb-metricscollected
          {
            'Latency'              => {
              'Unit'       => 'Seconds',
              'Statistics' => %w[Maximum Minimum Average],
            },
            'RequestCount'         => {
              'Unit'       => 'Count',
              'Statistics' => ['Sum'],
            },
            'HealthyHostCount'     => {
              'Units'      => 'Count',
              'Statistics' => %w[Minimum Maximum Average],
            },
            'UnHealthyHostCount'   => {
              'Units'      => 'Count',
              'Statistics' => %w[Minimum Maximum Average],
            },
            'HTTPCode_ELB_4XX'     => {
              'Units'      => 'Count',
              'Statistics' => ['Sum'],
            },
            'HTTPCode_ELB_5XX'     => {
              'Units'      => 'Count',
              'Statistics' => ['Sum'],
            },
            'HTTPCode_Backend_2XX' => {
              'Units'      => 'Count',
              'Statistics' => ['Sum'],
            },
            'HTTPCode_Backend_3XX' => {
              'Units'      => 'Count',
              'Statistics' => ['Sum'],
            },
            'HTTPCode_Backend_4XX' => {
              'Units'      => 'Count',
              'Statistics' => ['Sum'],
            },
            'HTTPCode_Backend_5XX' => {
              'Units'      => 'Count',
              'Statistics' => ['Sum'],
            },
          }
        end

        def base_metrics
          # get last 60 seconds
          start_time = (Time.now.utc - 60).iso8601
          end_time = Time.now.utc.iso8601

          # The base query that all metrics would get
          {
            'Namespace' => 'AWS/ELB',
            'StartTime' => start_time,
            'EndTime'   => end_time,
            'Period'    => 60,
          }
        end

        def tick
          if options[:fog_credentials_file]
            Fog.credentials_path = options[:fog_credentials_file]
            Fog.credential = options[:fog_credential].to_sym
            connection = Fog::AWS::CloudWatch.new
          else
            connection = if options[:access_key] && options[:secret_key]
                           Fog::AWS::CloudWatch.new({
                                                      aws_access_key_id: options[:access_key],
                                                      aws_secret_access_key: options[:secret_key],
                                                      region: options[:region],
                                                    })
                         else
                           Fog::AWS::CloudWatch.new({
                                                      use_iam_profile: true,
                                                      region: options[:region],
                                                    })
                         end
          end

          options[:elbs].each do |lb|
            metric_options = standard_metrics
            metric_base_options = base_metrics

            options[:azs].each do |az|
              metric_options.keys.sort.each do |metric_type|
                merged_options = metric_base_options.merge(metric_options[metric_type])
                merged_options['MetricName'] = metric_type
                merged_options['Dimensions'] = if az == 'all_az'
                                                 [{ 'Name' => 'LoadBalancerName', 'Value' => lb }]
                                               else
                                                 [
                                                   { 'Name' => 'LoadBalancerName', 'Value' => lb },
                                                   { 'Name' => 'AvailabilityZone', 'Value' => az },
                                                 ]
                                               end

                result = connection.get_metric_statistics(merged_options)

                # "If no response codes in the category 2XX-5XX range are sent to clients within
                # the given time period, values for these metrics will not be recorded in CloudWatch"
                # next if result.body["GetMetricStatisticsResult"]["Datapoints"].empty? && metric_type =~ /[2345]XX/
                #
                if result.body['GetMetricStatisticsResult']['Datapoints'].empty?
                  standard_metrics[metric_type]['Statistics'].each do |stat_type|
                    event = event(lb, az, metric_type, stat_type, 0.0)
                    report(event)
                  end
                  next
                end

                # We should only ever have a single data point
                result.body['GetMetricStatisticsResult']['Datapoints'][0].keys.sort.each do |stat_type|
                  next if stat_type == 'Unit'
                  next if stat_type == 'Timestamp'

                  unit = result.body['GetMetricStatisticsResult']['Datapoints'][0]['Unit']
                  metric = result.body['GetMetricStatisticsResult']['Datapoints'][0][stat_type]
                  event = event(lb, az, metric_type, stat_type, metric, unit)
                  report(event)
                end
              end
            end
          end
        end

        private

        def event(lb, az, metric_type, stat_type, metric, unit = nil)
          {
            host: lb,
            service: "elb.#{az}.#{metric_type}.#{stat_type}",
            ttl: 60,
            description: "#{lb} #{metric_type} #{stat_type} (#{unit})",
            tags: ['elb_metrics'],
            metric: metric,
          }
        end
      end
    end
  end
end
