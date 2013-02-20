module Riemann
  module Tools
    require 'rubygems'
    require 'trollop'
    require 'riemann/client'

    def self.included(base)
      base.instance_eval do
        def run
          new.run
        end

        def opt(*a)
          a.unshift :opt
          @opts ||= []
          @opts << a
        end

        def options
          p = Trollop::Parser.new
          @opts.each do |o|
            p.send *o
          end
          Trollop::with_standard_exception_handling(p) do
            p.parse ARGV
          end
        end
        
        opt :host, "Riemann host", :default => '127.0.0.1'
        opt :port, "Riemann port", :default => 5555
        opt :event_host, "Event hostname", :type => String
        opt :interval, "Seconds between updates", :default => 5
        opt :tag, "Tag to add to events", :type => String, :multi => true
        opt :ttl, "TTL for events", :type => Integer
      end
    end

    def initialize
      super
    end

    def tool_options
      {}
    end

    # Returns parsed options (cached) from command line.
    def options
      @options ||= self.class.options
    end
    alias :opts :options

    # Add a new command line option
    def opt(*a)
      @option_parser.opt *a
    end

    def report(event)
      if options[:tag]
        event[:tags] = options[:tag]
      end
      
      if options[:ttl]
        event[:ttl] = options[:ttl]
      end

      if options[:event_host]
        event[:host] = options[:event_host]
      end

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
      t0 = Time.now
      loop do
        begin
          tick
        rescue => e
          $stderr.puts "#{e.class} #{e}\n#{e.backtrace.join "\n"}"
        end

        # Sleep. 
        sleep(options[:interval] - ((Time.now - t0) % options[:interval]))
      end
    end

    def tick
    end
  end
end
