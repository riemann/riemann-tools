# frozen_string_literal: true

require 'riemann/tools'

module Riemann
  module Tools
    class Elasticsearch
      include Riemann::Tools
      require 'faraday'
      require 'json'
      require 'uri'

      opt :read_timeout, 'Faraday read timeout', type: :int, default: 2
      opt :open_timeout, 'Faraday open timeout', type: :int, default: 1
      opt :path_prefix,
          'Elasticsearch path prefix for proxied installations e.g. "els" for target http://localhost/els/_cluster/health', default: '/'.dup
      opt :es_host, 'Elasticsearch host', default: 'localhost'
      opt :es_port, 'Elasticsearch port', type: :int, default: 9200
      opt :es_search_index, 'Elasticsearch index to fetch search statistics for', default: '_all'

      # Handles HTTP connections and GET requests safely
      def safe_get(uri)
        # Handle connection timeouts
        response = nil
        begin
          connection = Faraday.new(uri)
          response = connection.get do |req|
            req.options[:timeout] = options[:read_timeout]
            req.options[:open_timeout] = options[:open_timeout]
          end
        rescue StandardError => e
          report(
            host: uri.host,
            service: 'elasticsearch health',
            state: 'critical',
            description: "HTTP connection error: #{e.class} - #{e.message}",
          )
        end
        response
      end

      def make_es_url(path)
        path_prefix = options[:path_prefix]
        path_prefix[0] = '' if path_prefix[0] == '/'
        path_prefix[path_prefix.length - 1] = '' if path_prefix[path_prefix.length - 1] == '/'
        "http://#{options[:es_host]}:#{options[:es_port]}#{path_prefix.length.positive? ? '/' : ''}#{path_prefix}/#{path}"
      end

      def health_url
        make_es_url('_cluster/health')
      end

      def indices_url
        make_es_url('_stats/store')
      end

      def search_url
        es_search_index = options[:es_search_index]
        make_es_url("#{es_search_index}/_stats/search")
      end

      def bad?(response, uri)
        if response.success?
          false
        else
          report(
            host: uri.host,
            service: 'elasticsearch health',
            state: 'critical',
            description: response.nil? ? 'HTTP response is empty!' : "HTTP connection error: #{response.status} - #{response.body}",
          )
        end
      end

      def tick_indices
        uri = URI(indices_url)
        response = safe_get(uri)

        return if bad?(response, uri)

        # Assuming that a 200 will give json
        json = JSON.parse(response.body)

        json['indices'].each_pair do |k, v|
          report(
            host: uri.host,
            service: "elasticsearch index/#{k}/primaries/size_in_bytes",
            metric: v['primaries']['store']['size_in_bytes'],
          )
          report(
            host: uri.host,
            service: "elasticsearch index/#{k}/total/size_in_bytes",
            metric: v['total']['store']['size_in_bytes'],
          )
        end
      end

      def tick_search
        uri = URI(search_url)
        response = safe_get(uri)

        return if bad?(response, uri)

        es_search_index = options[:es_search_index]
        # Assuming that a 200 will give json
        json = JSON.parse(response.body)

        json['_all'].each_pair do |_type, data|
          query = data['search']['query_time_in_millis'].to_f / data['search']['query_total']
          fetch = data['search']['fetch_time_in_millis'].to_f / data['search']['fetch_total']

          report(
            host: uri.host,
            service: "elasticsearch search/#{es_search_index}/query",
            metric: query,
          )
          report(
            host: uri.host,
            service: "elasticsearch search/#{es_search_index}/fetch",
            metric: fetch,
          )
        end
      end

      def tick
        begin
          tick_indices
          tick_search
        rescue StandardError => e
          report(
            host: options[:es_host],
            service: 'elasticsearch error',
            state: 'critical',
            description: "Elasticsearch cluster error: #{e.message}",
          )
        end
        uri = URI(health_url)
        response = safe_get(uri)

        return if bad?(response, uri)

        # Assuming that a 200 will give json
        json = JSON.parse(response.body)
        cluster_name = json.delete('cluster_name')
        cluster_status = json.delete('status')
        state = {
          'green'  => 'ok',
          'yellow' => 'warning',
          'red'    => 'critical',
        }[cluster_status]

        report(
          host: uri.host,
          service: 'elasticsearch health',
          state: state,
          description: "Elasticsearch cluster: #{cluster_name} - #{cluster_status}",
        )

        json.each_pair do |k, v|
          report(
            host: uri.host,
            service: "elasticsearch #{k}",
            metric: v,
            description: "Elasticsearch cluster #{k}",
          )
        end
      end
    end
  end
end
