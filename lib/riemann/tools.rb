module Riemann
  module Tools
    require 'trollop'
    require 'riemann/client'

    def self.included(base)
      base.instance_eval do
        def run
          new.run
        end
      end
    end

    def tool_options
      {}
    end

    def global_options
      Trollop.options do
        opt :host, "Riemann host", :default => '127.0.0.1'
        opt :port, "Riemann port", :default => 5555
        opt :interval, "Seconds between updates", :default => 5
      end
    end

    def options
      @options ||= global_options.merge(tool_options)
    end
    alias :opts :options

    def report(event)
      riemann << event
    end

    def riemann
      @riemann ||= Riemann::Client.new(
        :host => options[:host],
        :port => options[:port]
      )
    end
    alias :r :riemann

    def run
      loop do
        begin
          tick
        rescue => e
          $stderr.puts "#{e.class} #{e}\n#{e.backtrace.join "\n"}"
        end

        sleep options[:interval]
      end
    end

    def tick
    end
  end
end
