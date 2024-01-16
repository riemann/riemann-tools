# frozen_string_literal: true

require 'active_support'
require 'active_support/core_ext/numeric'

require 'riemann/tools/tls_check'

def gen_certificate(not_before = Time.now, validity_duration_days = 90)
  certificate = OpenSSL::X509::Certificate.new
  certificate.not_before = not_before
  certificate.not_after = certificate.not_before + validity_duration_days.days
  certificate
end

RSpec.describe Riemann::Tools::TLSCheck::TLSCheckResult do
  let(:tls_check_result) do
    res = described_class.new(uri, address, tls_socket, checker)
    allow(res).to receive(:peer_cert).and_return(certificate)
    res
  end

  let(:uri) do
    URI('https://example.com')
  end

  let(:address) do
    IPAddr.new('::1')
  end

  let(:tls_socket) do
    double
  end

  let(:checker) do
    res = double
    allow(res).to receive(:opts).and_return(
      renewal_duration_ratio: 1.0 / 3,
      renewal_duration_days: 90,
    )
    res
  end

  let(:certificate) do
    gen_certificate(not_before, validity_duration_days)
  end

  let(:not_before) { Time.now }
  let(:validity_duration_days) { 90 }

  describe('#validity_duration') do
    subject { tls_check_result.validity_duration }

    it { is_expected.to eq(90.days) }
  end

  describe('#renewal_duration') do
    subject { tls_check_result.renewal_duration }

    context 'with short-lived certificates' do
      it { is_expected.to eq(30.days) }
    end

    context 'with short-lived certificates' do
      let(:validity_duration_days) { 730 }

      it { is_expected.to eq(90.days) }
    end
  end
end
