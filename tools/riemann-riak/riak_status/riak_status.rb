#!/usr/bin/env ruby
# frozen_string_literal: true

Process.setproctitle($PROGRAM_NAME)

$LOAD_PATH.unshift File.expand_path("#{File.dirname(__FILE__)}/../vodpod-common/lib")
require 'rubygems'
require 'vodpod-common'
require 'vodpod/alerts'
require 'vodpod/starling'
require 'net/http'
require 'yajl/json_gem'

class RiakStatus
  PORT = 8098
  PATH = '/stats'
  INTERVAL = 10

  FSM_LIMITS = {
    get: {
      50 => 1000,
      95 => 2000,
      99 => 10_000
    },
    put: {
      50 => 1000,
      95 => 2000,
      99 => 10_000
    }
  }.freeze

  def initialize(opts = {})
    @host = opts[:host] || `hostname`.chomp
    @port = opts[:port] || PORT
    @path = opts[:path] || PATH
  end

  def alert(subservice, state, metric, description)
    Vodpod.alert(
      service: "riak #{subservice}",
      state: state,
      metric: metric,
      description: description
    )
  end

  def check_ring
    str = %x(#{__dir__}/ringready.erl riak@#{`hostname`}).chomp
    if str =~ /^TRUE/
      alert 'ring', :ok, nil, str
    else
      alert 'ring', :warning, nil, str
    end
  end

  def check_keys
    keys = %x(#{__dir__}/key_count.erl riak@#{`hostname`}).chomp
    if keys =~ /^\d+$/
      alert 'keys', :ok, keys.to_i, keys
    else
      alert 'keys', :error, nil, keys
    end
  end

  def check_disk
    gb = `du -s /var/lib/riak/bitcask/`.split(/\s+/).first.to_i / (1024.0**2)
    alert 'disk', :ok, gb, "#{gb} GB in bitcask"
  end

  # Returns the riak stat for the given fsm type and percentile.
  def fsm_stat(type, percentile)
    "node_#{type}_fsm_time_#{percentile == 50 ? 'median' : percentile}"
  end

  # Returns the alerts state for the given fsm.
  def fsm_state(type, percentile, val)
    limit = FSM_LIMITS[type][percentile]
    case val
    when 0..limit
      :ok
    when limit..limit * 2
      :warning
    else
      :critical
    end
  end

  def check_stats
    begin
      res = Net::HTTP.start(@host, @port) do |http|
        http.get('/stats')
      end
    rescue StandardError => e
      Vodpod.alert(
        service: 'riak',
        state: :critical,
        description: "error fetching /stats: #{e.class}, #{e.message}"
      )
      return
    end

    if res.code.to_i == 200
      stats = JSON.parse(res.body)
    else
      Vodpod.alert(
        service: 'riak',
        state: :critical,
        description: "stats returned HTTP #{res.code}:\n\n#{res.body}"
      )
      return
    end

    Vodpod.alert(
      service: 'riak',
      state: :ok
    )

    # Gets/puts/rr
    %w[
      vnode_gets
      vnode_puts
      node_gets
      node_puts
      read_repairs
    ].each do |s|
      alert s, :ok, stats[s] / 60.0, "#{stats[s] / 60.0}/sec"
    end

    # FSMs
    %i[get put].each do |type|
      [50, 95, 99].each do |percentile|
        val = stats[fsm_stat(type, percentile)] || 0
        val = 0 if val == 'undefined'
        val /= 1000.0 # Convert us to ms
        state = fsm_state(type, percentile, val)
        alert "#{type} #{percentile}", state, val, "#{val} ms"
      end
    end
  end

  def run
    loop do
      #      check_keys
      check_stats
      check_ring
      check_disk
      sleep INTERVAL
    end
  end
end

RiakStatus.new.run if $PROGRAM_NAME == __FILE__
