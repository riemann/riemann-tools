# frozen_string_literal: true

require 'riemann/tools'

module Riemann
  module Tools
    module AWS
      class S3List
        include Riemann::Tools
        require 'fog/aws'
        require 'time'

        opt :fog_credentials_file, 'Fog credentials file', type: String
        opt :fog_credential, 'Fog credentials to use', type: String
        opt :access_key, 'AWS Access Key', type: String
        opt :secret_key, 'AWS Secret Key', type: String
        opt :region, 'AWS Region', type: String, default: 'eu-west-1'
        opt :buckets, 'Buckets to pull metrics from, multi=true, can have a prefix like mybucket/prefix', type: String,
                                                                                                          multi: true, required: true
        opt :max_objects, 'Max number of objects to list before stopping to save bandwidth', default: -1

        def tick
          if options[:fog_credentials_file]
            Fog.credentials_path = options[:fog_credentials_file]
            Fog.credential = options[:fog_credential].to_sym
            connection = Fog::Storage.new
          else
            connection = if options[:access_key] && options[:secret_key]
                           Fog::Storage.new({
                                              provider: 'AWS',
                                              aws_access_key_id: options[:access_key],
                                              aws_secret_access_key: options[:secret_key],
                                              region: options[:region],
                                            })
                         else
                           Fog::Storage.new({
                                              provider: 'AWS',
                                              use_iam_profile: true,
                                              region: options[:region],
                                            })
                         end
          end

          options[:buckets].each do |url|
            split = url.split('/')
            bucket = split[0]
            prefix = ''
            prefix = url[(split[0].length + 1)..] if split[1]
            count = 0
            connection.directories.get(bucket, prefix: prefix).files.map do |_file|
              count += 1
              break if options[:max_objects].positive? && count > options[:max_objects]
            end
            event = if options[:max_objects].positive? && count > options[:max_objects]
                      event(
                        url, 'objectCount', count, "count was bigger than threshold #{options[:max_objects]}",
                        'warning',
                      )
                    else
                      event(url, 'objectCount', count, "All objects counted, threshold=#{options[:max_objects]}", 'ok')
                    end
            report(event)
          end
        end

        private

        def event(bucket, label, metric, description, severity)
          {
            host: "bucket_#{bucket}",
            service: "s3.#{label}",
            ttl: 300,
            description: "#{bucket} #{description}",
            tags: ['s3_metrics'],
            metric: metric,
            state: severity,
          }
        end
      end
    end
  end
end
