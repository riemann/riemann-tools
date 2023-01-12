# frozen_string_literal: true

require 'riemann/tools'
require 'riemann/tools/version'
require 'socket'
require 'net/http'
require 'uri'
require 'json'

# Reports service and node status to riemann
module Riemann
  module Tools
    class ConsulHealth
      include Riemann::Tools

      opt :consul_host, 'Consul API Host (default to localhost)', default: 'localhost'
      opt :consul_port, 'Consul API Host (default to 8500)', default: '8500'
      opt :prefix, 'prefix to use for all service names when reporting', default: 'consul '
      opt :minimum_services_per_node, 'minimum services per node (default: 0)', default: 0
      opt :user_agent, 'User-Agent header for HTTP requests', short: :none, default: "#{File.basename($PROGRAM_NAME)}/#{Riemann::Tools::VERSION} (+https://github.com/riemann/riemann-tools)"

      def initialize
        @hostname = opts[:consul_host]
        @prefix = opts[:prefix]
        @minimum_services_per_node = opts[:minimum_services_per_node]
        @underlying_ip = IPSocket.getaddress(@hostname)
        @consul_leader_url = URI.parse("http://#{opts[:consul_host]}:#{opts[:consul_port]}/v1/status/leader")
        @consul_services_url = URI.parse("http://#{opts[:consul_host]}:#{opts[:consul_port]}/v1/catalog/services")
        @consul_nodes_url = URI.parse("http://#{opts[:consul_host]}:#{opts[:consul_port]}/v1/catalog/nodes")
        @consul_health_url_prefix = "http://#{opts[:consul_host]}:#{opts[:consul_port]}/v1/health/service/"

        @last_services_read = {}
      end

      def alert(hostname, service, state, metric, description)
        opts = {
          host: hostname,
          service: service.to_s,
          state: state.to_s,
          metric: metric,
          description: description,
        }

        report(opts)
      end

      def get(url)
        ::Net::HTTP.new(url.host, url.port).get(url, { 'user-agent' => opts[:user_agent] }).body
      end

      def tick
        leader = JSON.parse(get(@consul_leader_url))
        leader_hostname = URI.parse("http://#{leader}").hostname

        return unless leader_hostname == @underlying_ip

        nodes = JSON.parse(get(@consul_nodes_url))
        services = JSON.parse(get(@consul_services_url))
        services_by_nodes = {}

        nodes.each do |node|
          node_name = node['Node']
          services_by_nodes[node_name] = 0
        end

        # For every service
        services.each do |service|
          service_name = service[0]
          health_url = URI.parse(@consul_health_url_prefix + service_name)
          health_nodes = JSON.parse(get(health_url))

          total_count = 0
          ok_count = 0

          health_nodes.each do |node|
            hostname = node['Node']['Node']
            ok = node['Checks'].all? { |check| check['Status'] == 'passing' }
            alert(hostname, "#{@prefix}#{service_name}", ok ? :ok : :critical, ok ? 1 : 0, JSON.generate(node))
            total_count += 1
            ok_count += ok ? 1 : 0

            last_services_by_nodes = services_by_nodes[hostname].to_i
            services_by_nodes[hostname] = last_services_by_nodes + 1
          end

          unless @last_services_read[service_name].nil?
            last_ok = @last_services_read[service_name]
            if last_ok != ok_count
              alert(
                'total', "#{@prefix}#{service_name}-count", ok_count >= last_ok ? :ok : :critical, ok_count,
                "Number of passing #{service_name} is: #{ok_count}/#{total_count}, Last time it was: #{last_ok}",
              )
            end
          end

          @last_services_read[service_name] = ok_count
        end

        # For every node
        services_by_nodes.each do |node, count|
          alert(
            node, "#{@prefix}total-services", count >= @minimum_services_per_node ? :ok : :critical, count,
            "#{count} services in the specified node",
          )
        end
      end
    end
  end
end
