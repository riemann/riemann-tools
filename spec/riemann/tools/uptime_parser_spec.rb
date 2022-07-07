# frozen_string_literal: true

require 'riemann/tools/uptime_parser.tab'

RSpec.describe Riemann::Tools::UptimeParser do
  {
    # FreeBSD 13
    "11:10  up  3:40, 1 user, load averages: 0,25 0,67 0,68\n"              => {
      uptime: 13_200,
      users: 1,
      load_averages: {
        1  => 0.25,
        5  => 0.67,
        15 => 0.68,
      },
    },
    "11:30AM  up 4 hrs, 1 user, load averages: 0.45, 0.53, 0.54\n"          => {
      uptime: 14_400,
      users: 1,
      load_averages: {
        1  => 0.45,
        5  => 0.53,
        15 => 0.54,
      },
    },
    "11:46  up 38 days, 22:21, 2 users, load averages: 1,76 1,24 0,94\n"    => {
      uptime: 3_363_660,
      users: 2,
      load_averages: {
        1  => 1.76,
        5  => 1.24,
        15 => 0.94,
      },
    },
    # CentOS 7
    " 10:40:21 up 1 day, 18:51,  1 user,  load average: 0,46, 1,45, 2,00\n" => {
      uptime: 154_260,
      users: 1,
      load_averages: {
        1  => 0.46,
        5  => 1.45,
        15 => 2.00,
      },
    },
    " 11:50:17 up 1 day, 20:01,  1 user,  load average: 1.66, 1.69, 1.38\n" => {
      uptime: 158_460,
      users: 1,
      load_averages: {
        1  => 1.66,
        5  => 1.69,
        15 => 1.38,
      },
    },
  }.each do |uptime, expected_data|
    describe(uptime) do
      let(:text) { uptime }

      it 'parses correct values' do
        res = subject.parse(text)

        expect(res).to eq(expected_data)
      end
    end
  end
end
