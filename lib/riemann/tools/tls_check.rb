# frozen_string_literal: true

require 'net/http'
require 'resolv'

require 'riemann/tools'
require 'riemann/tools/utils'

module URI
  {
    'IMAP'     => 143,
    'IMAPS'    => 993,
    'MYSQL'    => 3306,
    'POSTGRES' => 5432,
  }.each do |scheme, port|
    klass = Class.new(Generic)
    klass.const_set('DEFAULT_PORT', port)

    if Gem::Version.new(RUBY_VERSION.dup) < Gem::Version.new('3.1.0')
      @@schemes[scheme] = klass
    else
      register_scheme(scheme, klass)
    end
  end
end

module Riemann
  module Tools
    class TLSCheck
      include Riemann::Tools

      # Ruby OpenSSL does not expose ERR_error_string(3), and depending on the
      # version of OpenSSL the available values change.  Build a local list of
      # mappings from include/openssl/x509_vfy.h.in and crypto/x509/x509_txt.c
      # for lookups.
      OPENSSL_ERROR_STRINGS = [
        'ok',
        'unspecified certificate verification error',
        'unable to get issuer certificate',
        'unable to get certificate CRL',
        "unable to decrypt certificate's signature",
        "unable to decrypt CRL's signature",
        'unable to decode issuer public key',
        'certificate signature failure',
        'CRL signature failure',
        'certificate is not yet valid',
        'certificate has expired',
        'CRL is not yet valid',
        'CRL has expired',
        "format error in certificate's notBefore field",
        "format error in certificate's notAfter field",
        "format error in CRL's lastUpdate field",
        "format error in CRL's nextUpdate field",
        'out of memory',
        'self-signed certificate',
        'self-signed certificate in certificate chain',
        'unable to get local issuer certificate',
        'unable to verify the first certificate',
        'certificate chain too long',
        'certificate revoked',
        "issuer certificate doesn't have a public key",
        'path length constraint exceeded',
        'unsuitable certificate purpose',
        'certificate not trusted',
        'certificate rejected',
      ].freeze

      class TLSCheckResult
        include Riemann::Tools::Utils

        attr_reader :uri, :address, :tls_socket

        def initialize(uri, address, tls_socket, checker)
          @uri = uri
          @address = address
          @tls_socket = tls_socket
          @checker = checker
        end

        def peer_cert
          tls_socket.peer_cert
        end

        def peer_cert_chain
          tls_socket.peer_cert_chain
        end

        def exception
          tls_socket.exception if tls_socket.respond_to?(:exception)
        end

        def valid_identity?
          OpenSSL::SSL.verify_certificate_identity(peer_cert, uri.host)
        end

        def acceptable_identities
          res = []

          peer_cert.extensions.each do |ext|
            next unless ext.oid == 'subjectAltName'

            ostr = OpenSSL::ASN1.decode(ext.to_der).value.last
            sequence = OpenSSL::ASN1.decode(ostr.value)
            res = sequence.value.map(&:value)
          end

          res << peer_cert.subject.to_s unless res.any?

          res
        end

        def not_valid_yet?
          now < not_before
        end

        def not_after
          peer_cert.not_after
        end

        def not_after_ago
          not_after - now
        end

        def not_after_ago_in_words
          when_from_now(not_after)
        end

        def not_before
          peer_cert.not_before
        end

        def not_before_away
          now - not_before
        end

        def not_before_away_in_words
          when_from_now(not_before)
        end

        def validity_duration
          not_after - not_before
        end

        def renewal_duration
          [validity_duration * @checker.opts[:renewal_duration_ratio], @checker.opts[:renewal_duration_days] * 3600 * 24].min
        end

        def expired_or_expire_soon?
          now + renewal_duration / 3 > not_after
        end

        def expire_soonish?
          now + 2 * renewal_duration / 3 > not_after
        end

        def expired?
          now > not_after
        end

        def verify_result
          tls_socket.verify_result
        end

        def trusted?
          verify_result == OpenSSL::X509::V_OK
        end

        def ocsp_status
          @ocsp_status ||= check_ocsp_status
        end

        def ocsp?
          !ocsp_status.empty?
        end

        def valid_ocsp?
          ocsp_status == 'successful'
        end

        def check_ocsp_status
          subject = peer_cert
          issuer = peer_cert_chain[1]

          return '' unless issuer

          digest = OpenSSL::Digest.new('SHA1')
          certificate_id = OpenSSL::OCSP::CertificateId.new(subject, issuer, digest)

          request = OpenSSL::OCSP::Request.new
          request.add_certid(certificate_id)

          request.add_nonce

          authority_info_access = subject.extensions.find do |extension|
            extension.oid == 'authorityInfoAccess'
          end

          return '' unless authority_info_access

          descriptions = authority_info_access.value.split("\n")
          ocsp = descriptions.find do |description|
            description.start_with? 'OCSP'
          end

          ocsp_uri = URI(ocsp[/URI:(.*)/, 1])

          http_response = ::Net::HTTP.start(ocsp_uri.hostname, ocsp_uri.port) do |http|
            ocsp_uri.path = '/' if ocsp_uri.path.empty?
            http.post(ocsp_uri.path, request.to_der, 'content-type' => 'application/ocsp-request')
          end

          response = OpenSSL::OCSP::Response.new http_response.body
          response_basic = response.basic

          return '' unless response_basic&.verify([issuer], @checker.store)

          response.status_string
        end
      end

      opt :uri, 'URI to check', short: :none, type: :strings
      opt :checks, 'A list of checks to run.', short: :none, type: :strings, default: %w[identity not-after not-before ocsp trust]

      opt :renewal_duration_days, 'Number of days before certificate expiration it is considered renewalable', short: :none, type: :integer, default: 90
      opt :renewal_duration_ratio, 'Portion of the certificate lifespan it is considered renewalable', short: :none, type: :float, default: 1.0 / 3

      opt :trust, 'Additionnal CA to trust', short: :none, type: :strings, default: []

      opt :resolvers, 'Run this number of resolver threads', short: :none, type: :integer, default: 5
      opt :workers, 'Run this number of worker threads', short: :none, type: :integer, default: 20

      def initialize
        @resolve_queue = Queue.new
        @work_queue = Queue.new

        opts[:resolvers].times do
          Thread.new do
            loop do
              uri = @resolve_queue.pop
              host = uri.host

              addresses = if host == 'localhost'
                            Socket.ip_address_list.select { |address| address.ipv6_loopback? || address.ipv4_loopback? }.map(&:ip_address)
                          else
                            Resolv::DNS.new.getaddresses(host)
                          end
              if addresses.empty?
                host = host[1...-1] if host[0] == '[' && host[-1] == ']'
                begin
                  addresses << IPAddr.new(host)
                rescue IPAddr::InvalidAddressError
                  # Ignore
                end
              end

              @work_queue.push([uri, addresses])
            end
          end
        end

        opts[:workers].times do
          Thread.new do
            loop do
              uri, addresses = @work_queue.pop
              test_uri_addresses(uri, addresses)
            end
          end
        end

        super
      end

      def tick
        report(
          service: 'riemann tls-check resolvers utilization',
          metric: (opts[:resolvers].to_f - @resolve_queue.num_waiting) / opts[:resolvers],
          state: @resolve_queue.num_waiting.positive? ? 'ok' : 'critical',
          tags: %w[riemann],
        )
        report(
          service: 'riemann tls-check resolvers saturation',
          metric: @resolve_queue.length,
          state: @resolve_queue.empty? ? 'ok' : 'critical',
          tags: %w[riemann],
        )
        report(
          service: 'riemann tls-check workers utilization',
          metric: (opts[:workers].to_f - @work_queue.num_waiting) / opts[:workers],
          state: @work_queue.num_waiting.positive? ? 'ok' : 'critical',
          tags: %w[riemann],
        )
        report(
          service: 'riemann tls-check workers saturation',
          metric: @work_queue.length,
          state: @work_queue.empty? ? 'ok' : 'critical',
          tags: %w[riemann],
        )

        opts[:uri].each do |uri|
          @resolve_queue.push(URI(uri))
        end
      end

      def test_uri_addresses(uri, addresses)
        addresses.each do |address|
          test_uri_address(uri, address.to_s)
        end
      end

      def test_uri_address(uri, address)
        socket = tls_socket(uri, address)
        tls_check_result = TLSCheckResult.new(uri, address, socket, self)
        report_availability(tls_check_result)
        return unless socket.peer_cert

        report_not_before(tls_check_result) if opts[:checks].include?('not-before')
        report_not_after(tls_check_result) if opts[:checks].include?('not-after')
        report_identity(tls_check_result) if opts[:checks].include?('identity')
        report_trust(tls_check_result) if opts[:checks].include?('trust')
        report_ocsp(tls_check_result) if opts[:checks].include?('ocsp')
      rescue Errno::ECONNREFUSED => e
        report_unavailability(uri, address, e)
      end

      def report_availability(tls_check_result)
        if tls_check_result.exception
          report(
            service: "#{tls_endpoint_name(tls_check_result)} availability",
            state: 'critical',
            description: tls_check_result.exception.message,
          )
        else
          issues = []

          issues << 'Certificate is not valid yet' if tls_check_result.not_valid_yet?
          issues << 'Certificate has expired' if tls_check_result.expired?
          issues << 'Certificate identity could not be verified' unless tls_check_result.valid_identity?
          issues << 'Certificate is not trusted' unless tls_check_result.trusted?
          issues << 'Certificate OCSP verification failed' if tls_check_result.ocsp? && !tls_check_result.valid_ocsp?

          report(
            service: "#{tls_endpoint_name(tls_check_result)} availability",
            state: issues.empty? ? 'ok' : 'critical',
            description: issues.join("\n"),
          )
        end
      end

      def report_unavailability(uri, address, exception)
        report(
          service: "#{tls_endpoint_name2(uri, address)} availability",
          state: 'critical',
          description: exception.message,
        )
      end

      def report_not_after(tls_check_result)
        report(
          service: "#{tls_endpoint_name(tls_check_result)} not after",
          state: not_after_state(tls_check_result),
          metric: tls_check_result.not_after_ago,
          description: tls_check_result.not_after_ago_in_words,
        )
      end

      def report_not_before(tls_check_result)
        report(
          service: "#{tls_endpoint_name(tls_check_result)} not before",
          state: not_before_state(tls_check_result),
          metric: tls_check_result.not_before_away,
          description: tls_check_result.not_before_away_in_words,
        )
      end

      def report_identity(tls_check_result)
        report(
          service: "#{tls_endpoint_name(tls_check_result)} identity",
          state: tls_check_result.valid_identity? ? 'ok' : 'critical',
          description: "Valid for:\n#{tls_check_result.acceptable_identities.join("\n")}",
        )
      end

      def report_trust(tls_check_result)
        commont_attrs = {
          service: "#{tls_endpoint_name(tls_check_result)} trust",
        }
        extra_attrs = if tls_check_result.exception
                        {
                          state: 'critical',
                          description: tls_check_result.exception.message,
                        }
                      else
                        {
                          state: tls_check_result.trusted? ? 'ok' : 'critical',
                          description: if OPENSSL_ERROR_STRINGS[tls_check_result.verify_result]
                                         format('%<code>d - %<msg>s', code: tls_check_result.verify_result, msg: OPENSSL_ERROR_STRINGS[tls_check_result.verify_result])
                                       else
                                         tls_check_result.verify_result.to_s
                                       end,
                        }
                      end
        report(commont_attrs.merge(extra_attrs))
      end

      def report_ocsp(tls_check_result)
        return unless tls_check_result.ocsp?

        report(
          service: "#{tls_endpoint_name(tls_check_result)} OCSP status",
          state: tls_check_result.valid_ocsp? ? 'ok' : 'critical',
          description: tls_check_result.ocsp_status,
        )
      end

      #      not_before                      not_after
      #          |<----------------------------->|         validity_duration
      # …ccccccccoooooooooooooooooooooooooooooooooooooo…   not_before_state
      #
      #       time --->>>>
      def not_before_state(tls_check_result)
        tls_check_result.not_valid_yet? ? 'critical' : 'ok'
      end

      #      not_before                      not_after
      #          |<----------------------------->|         validity_duration
      #                              |<--------->|         renewal_duration
      #                              | ⅓ | ⅓ | ⅓ |
      # …oooooooooooooooooooooooooooooooowwwwcccccccccc…   not_after_state
      #
      #       time --->>>>
      def not_after_state(tls_check_result)
        if tls_check_result.expired_or_expire_soon?
          'critical'
        elsif tls_check_result.expire_soonish?
          'warning'
        else
          'ok'
        end
      end

      def tls_socket(uri, address)
        case uri.scheme
        when 'smtp'
          smtp_tls_socket(uri, address)
        when 'imap'
          imap_tls_socket(uri, address)
        when 'ldap'
          ldap_tls_socket(uri, address)
        when 'mysql'
          mysql_tls_socket(uri, address)
        when 'postgres'
          postgres_tls_socket(uri, address)
        else
          raw_tls_socket(uri, address)
        end
      end

      def mysql_tls_socket(uri, address)
        socket = TCPSocket.new(address, uri.port)
        length = "#{socket.read(3)}\0".unpack1('L*')
        _sequence = socket.read(1)
        body = socket.read(length)
        initial_handshake_packet = body.unpack('cZ*La8aScSS')

        capabilities = initial_handshake_packet[5] | (initial_handshake_packet[8] << 16)

        ssl_flag = 1 << 11
        raise 'No TLS support' if (capabilities & ssl_flag).zero?

        socket.write(['2000000185ae7f0000000001210000000000000000000000000000000000000000000000'].pack('H*'))
        tls_handshake(socket, uri.host)
      end

      def postgres_tls_socket(uri, address)
        socket = TCPSocket.new(address, uri.port)
        socket.write(['0000000804d2162f'].pack('H*'))
        raise 'Unexpected reply' unless socket.read(1) == 'S'

        tls_handshake(socket, uri.host)
      end

      def smtp_tls_socket(uri, address)
        socket = TCPSocket.new(address, uri.port)
        until socket.gets =~ /^220 /
        end
        socket.puts("EHLO #{my_hostname}")
        until socket.gets =~ /^250 /
        end
        socket.puts('STARTTLS')
        socket.gets

        tls_handshake(socket, uri.host)
      end

      def my_hostname
        Addrinfo.tcp(Socket.gethostname, 8023).getnameinfo.first
      rescue SocketError
        Socket.gethostname
      end

      def imap_tls_socket(uri, address)
        socket = TCPSocket.new(address, uri.port)
        until socket.gets =~ /^\* OK/
        end
        socket.puts('. CAPABILITY')
        until socket.gets =~ /^\. OK/
        end
        socket.puts('. STARTTLS')
        until socket.gets =~ /^\. OK/
        end

        tls_handshake(socket, uri.host)
      end

      def ldap_tls_socket(uri, address)
        socket = TCPSocket.new(address, uri.port)
        socket.write(['301d02010177188016312e332e362e312e342e312e313436362e3230303337'].pack('H*'))
        expected_res = ['300c02010178070a010004000400'].pack('H*')
        res = socket.read(expected_res.length)

        return nil unless res == expected_res

        tls_handshake(socket, uri.host)
      end

      def raw_tls_socket(uri, address)
        raise "No default port for #{uri.scheme} scheme" unless uri.port

        socket = TCPSocket.new(address, uri.port)
        tls_handshake(socket, uri.host)
      end

      def tls_handshake(raw_socket, hostname)
        tls_socket = OpenSSL::SSL::SSLSocket.new(raw_socket, ssl_context)
        tls_socket.hostname = hostname
        begin
          tls_socket.connect
        rescue OpenSSL::SSL::SSLError => e
          # This may fail for example if a client certificate is required but
          # not provided. In this case, the remote certificate is available and
          # we can ignore this issue. In other cases, the remote certificate is
          # not available, in this case we want to stop and report the issue
          # (e.g. connecting to a host with a SNI for a name not handled by
          # that host).
          tls_socket.define_singleton_method(:exception) do
            e
          end
        end
        tls_socket
      end

      def ssl_context
        @ssl_context ||= begin
          ctx = OpenSSL::SSL::SSLContext.new
          ctx.cert_store = store
          ctx.verify_hostname = false
          ctx.verify_mode = OpenSSL::SSL::VERIFY_NONE
          ctx
        end
      end

      def store
        @store ||= begin
          store = OpenSSL::X509::Store.new
          store.set_default_paths
          opts[:trust].each do |path|
            if File.directory?(path)
              store.add_path(path)
            else
              store.add_file(path)
            end
          end
          store
        end
      end

      def tls_endpoint_name(tls_check_result)
        tls_endpoint_name2(tls_check_result.uri, tls_check_result.address)
      end

      def tls_endpoint_name2(uri, address)
        "TLS certificate #{uri} #{endpoint_name(IPAddr.new(address), uri.port)}"
      end
    end
  end
end
