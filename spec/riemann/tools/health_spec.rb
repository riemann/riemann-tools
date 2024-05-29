# frozen_string_literal: true

require 'riemann/tools/health'

RSpec.describe Riemann::Tools::Health do
  describe('#human_size_to_number') do
    subject { described_class.new.human_size_to_number(input) }

    {
      '512' => 512,
      '1k'  => 1024,
      '2K'  => 2048,
      '42m' => 44_040_192,
    }.each do |input, expected_output|
      context %(when passed #{input.inspect}) do
        let(:input) { input }

        it { is_expected.to eq(expected_output) }
      end
    end
  end

  describe('#number_to_human_size') do
    subject { described_class.new.number_to_human_size(input, rounding) }

    {
      0                 => %w[0 0 0],
      1024              => ['1.0kiB', '1.0kiB', '1.0kiB'],
      2047              => ['1.9kiB', '2.0kiB', '2.0kiB'],
      2048              => ['2.0kiB', '2.0kiB', '2.0kiB'],
      2049              => ['2.0kiB', '2.0kiB', '2.1kiB'],
      44_040_192        => ['42.0MiB', '42.0MiB', '42.0MiB'],
      1_155_301_638_144 => ['1.0TiB', '1.1TiB', '1.1TiB'],
    }.each do |input, expected_output|
      context %(when passed #{input.inspect}) do
        let(:input) { input }

        context 'when rounding lower' do
          let(:rounding) { :floor }

          it { is_expected.to eq(expected_output[0]) }
        end

        context 'when rounding to nearest' do
          let(:rounding) { :round }

          it { is_expected.to eq(expected_output[1]) }
        end

        context 'when rounding above' do
          let(:rounding) { :ceil }

          it { is_expected.to eq(expected_output[2]) }
        end
      end
    end
  end

  describe '#linux_running_in_container?' do
    before do
      allow(File).to receive(:readlink).with('/proc/self/ns/pid').and_return(pid_namespace)
    end

    context 'when running on the host' do
      let(:pid_namespace) { 'pid:[4026531836]' }

      it 'returns the expected value' do
        expect(subject).not_to be_linux_running_in_container
      end
    end

    context 'when running in a container' do
      let(:pid_namespace) { 'pid:[4026532474]' }

      it 'returns the expected value' do
        expect(subject).to be_linux_running_in_container
      end
    end
  end

  describe '#linux_zfs_arc_evictable_memory' do
    before do
      allow(subject).to receive(:linux_running_in_container?).and_return(false)
      allow(File).to receive(:readlines).with('/proc/spl/kstat/zfs/arcstats').and_return(<<~OUTPUT.split("\n"))
        12 1 0x01 123 33456 16771914747167 65909736923948
        name                            type data
        hits                            4    4194887
        misses                          4    10500
        demand_data_hits                4    107986
        demand_data_misses              4    2
        demand_metadata_hits            4    4058473
        demand_metadata_misses          4    9216
        prefetch_data_hits              4    28396
        prefetch_data_misses            4    1207
        prefetch_metadata_hits          4    32
        prefetch_metadata_misses        4    75
        mru_hits                        4    882890
        mru_ghost_hits                  4    7737
        mfu_hits                        4    3311966
        mfu_ghost_hits                  4    2306
        deleted                         4    42072676
        mutex_miss                      4    1771
        access_skip                     4    0
        evict_skip                      4    1004
        evict_not_enough                4    68
        evict_l2_cached                 4    0
        evict_l2_eligible               4    5516808656384
        evict_l2_eligible_mfu           4    216467456
        evict_l2_eligible_mru           4    5516592188928
        evict_l2_ineligible             4    6029312
        evict_l2_skip                   4    0
        hash_elements                   4    124644
        hash_elements_max               4    158917
        hash_collisions                 4    1256052
        hash_chains                     4    1793
        hash_chain_max                  4    4
        p                               4    8383553536
        c                               4    16767066112
        c_min                           4    1047941632
        c_max                           4    16767066112
        size                            4    16791717984
        compressed_size                 4    16052915712
        uncompressed_size               4    16066757120
        overhead_size                   4    685315584
        hdr_size                        4    40836960
        data_size                       4    16724525056
        metadata_size                   4    13706240
        dbuf_size                       4    3017856
        dnode_size                      4    8890304
        bonus_size                      4    734400
        anon_size                       4    205520896
        anon_evictable_data             4    0
        anon_evictable_metadata         4    0
        mru_size                        4    16532327936
        mru_evictable_data              4    15577382912
        mru_evictable_metadata          4    2461696
        mru_ghost_size                  4    225443840
        mru_ghost_evictable_data        4    52822016
        mru_ghost_evictable_metadata    4    172621824
        mfu_size                        4    382464
        mfu_evictable_data              4    0
        mfu_evictable_metadata          4    0
        mfu_ghost_size                  4    18432
        mfu_ghost_evictable_data        4    0
        mfu_ghost_evictable_metadata    4    18432
        l2_hits                         4    0
        l2_misses                       4    0
        l2_prefetch_asize               4    0
        l2_mru_asize                    4    0
        l2_mfu_asize                    4    0
        l2_bufc_data_asize              4    0
        l2_bufc_metadata_asize          4    0
        l2_feeds                        4    0
        l2_rw_clash                     4    0
        l2_read_bytes                   4    0
        l2_write_bytes                  4    0
        l2_writes_sent                  4    0
        l2_writes_done                  4    0
        l2_writes_error                 4    0
        l2_writes_lock_retry            4    0
        l2_evict_lock_retry             4    0
        l2_evict_reading                4    0
        l2_evict_l1cached               4    0
        l2_free_on_write                4    0
        l2_abort_lowmem                 4    0
        l2_cksum_bad                    4    0
        l2_io_error                     4    0
        l2_size                         4    0
        l2_asize                        4    0
        l2_hdr_size                     4    0
        l2_log_blk_writes               4    0
        l2_log_blk_avg_asize            4    0
        l2_log_blk_asize                4    0
        l2_log_blk_count                4    0
        l2_data_to_meta_ratio           4    0
        l2_rebuild_success              4    0
        l2_rebuild_unsupported          4    0
        l2_rebuild_io_errors            4    0
        l2_rebuild_dh_errors            4    0
        l2_rebuild_cksum_lb_errors      4    0
        l2_rebuild_lowmem               4    0
        l2_rebuild_size                 4    0
        l2_rebuild_asize                4    0
        l2_rebuild_bufs                 4    0
        l2_rebuild_bufs_precached       4    0
        l2_rebuild_log_blks             4    0
        memory_throttle_count           4    0
        memory_direct_count             4    0
        memory_indirect_count           4    0
        memory_all_bytes                4    33534132224
        memory_free_bytes               4    14101360640
        memory_available_bytes          3    12877639168
        arc_no_grow                     4    0
        arc_tempreserve                 4    132096
        arc_loaned_bytes                4    0
        arc_prune                       4    0
        arc_meta_used                   4    65964976
        arc_meta_limit                  4    12575299584
        arc_dnode_limit                 4    1257529958
        arc_meta_max                    4    129330864
        arc_meta_min                    4    16777216
        async_upgrade_sync              4    2597
        demand_hit_predictive_prefetch  4    907
        demand_hit_prescient_prefetch   4    0
        arc_need_free                   4    0
        arc_sys_free                    4    1223721472
        arc_raw_size                    4    0
        cached_only_in_progress         4    0
        abd_chunk_waste_size            4    7168
      OUTPUT
    end

    it 'return the expected size' do
      expect(subject.linux_zfs_arc_evictable_memory).to eq(15_214_692)
    end
  end

  describe('#disks') do
    before do
      allow(subject).to receive(:df).and_return(<<~OUTPUT)
        Filesystem                        1024-blocks       Used      Avail Capacity  Mounted on
        zroot/ROOT/13.1                     321563824   23105468  298458356     7%    /
        zroot/var/audit                     298458444         88  298458356     0%    /var/audit
        zroot/var/mail                      298459708       1352  298458356     0%    /var/mail
        zroot/tmp                           298499732      41376  298458356     0%    /tmp
        zroot                               298458444         88  298458356     0%    /zroot
        zroot/var/crash                     298458444         88  298458356     0%    /var/crash
        zroot/usr/src                       298458444         88  298458356     0%    /usr/src
        zroot/usr/home                      445963996  147505640  298458356    33%    /usr/home
        zroot/var/tmp                       298458476        120  298458356     0%    /var/tmp
        zroot/var/log                       298464488       6132  298458356     0%    /var/log
        192.168.42.5:/volume1/tank/Medias  3745681248 1494770996 2250910252    40%    /usr/home/romain/Medias
      OUTPUT
    end

    it 'reports all zfs filesystems' do
      allow(subject).to receive(:alert).with('disk /', :ok, 0.07185344331519083, '7% used, 284.6GiB free')
      allow(subject).to receive(:alert).with('disk /var/audit', :ok, 2.9484841782529697e-07, '0% used, 284.6GiB free')
      allow(subject).to receive(:alert).with('disk /var/mail', :ok, 4.529924689197913e-06, '0% used, 284.6GiB free')
      allow(subject).to receive(:alert).with('disk /tmp', :ok, 0.0001386131897766662, '0% used, 284.6GiB free')
      allow(subject).to receive(:alert).with('disk /zroot', :ok, 2.9484841782529697e-07, '0% used, 284.6GiB free')
      allow(subject).to receive(:alert).with('disk /var/crash', :ok, 2.9484841782529697e-07, '0% used, 284.6GiB free')
      allow(subject).to receive(:alert).with('disk /usr/src', :ok, 2.9484841782529697e-07, '0% used, 284.6GiB free')
      allow(subject).to receive(:alert).with('disk /usr/home', :ok, 0.33075683535672684, '33% used, 284.6GiB free')
      allow(subject).to receive(:alert).with('disk /var/tmp', :ok, 4.02065981198671e-07, '0% used, 284.6GiB free')
      allow(subject).to receive(:alert).with('disk /var/log', :ok, 2.0545157787749945e-05, '0% used, 284.6GiB free')
      allow(subject).to receive(:alert).with('disk /usr/home/romain/Medias', :ok, 0.39906518922242257, '40% used, 2.0TiB free')
      subject.disk
      expect(subject).to have_received(:alert).with('disk /', :ok, 0.07185344331519083, '7% used, 284.6GiB free')
      expect(subject).to have_received(:alert).with('disk /var/audit', :ok, 2.9484841782529697e-07, '0% used, 284.6GiB free')
      expect(subject).to have_received(:alert).with('disk /var/mail', :ok, 4.529924689197913e-06, '0% used, 284.6GiB free')
      expect(subject).to have_received(:alert).with('disk /tmp', :ok, 0.0001386131897766662, '0% used, 284.6GiB free')
      expect(subject).to have_received(:alert).with('disk /zroot', :ok, 2.9484841782529697e-07, '0% used, 284.6GiB free')
      expect(subject).to have_received(:alert).with('disk /var/crash', :ok, 2.9484841782529697e-07, '0% used, 284.6GiB free')
      expect(subject).to have_received(:alert).with('disk /usr/src', :ok, 2.9484841782529697e-07, '0% used, 284.6GiB free')
      expect(subject).to have_received(:alert).with('disk /usr/home', :ok, 0.33075683535672684, '33% used, 284.6GiB free')
      expect(subject).to have_received(:alert).with('disk /var/tmp', :ok, 4.02065981198671e-07, '0% used, 284.6GiB free')
      expect(subject).to have_received(:alert).with('disk /var/log', :ok, 2.0545157787749945e-05, '0% used, 284.6GiB free')
      expect(subject).to have_received(:alert).with('disk /usr/home/romain/Medias', :ok, 0.39906518922242257, '40% used, 2.0TiB free')
    end

    context 'with a foreign locale' do
      before do
        allow(subject).to receive(:df).and_return(<<~OUTPUT)
          Sys. de fichiers blocs de 1024  Utilisé Disponible Capacité Monté sur
          /dev/md1              20026172 11898676    7087168      63% /
          /dev/md2              94569252 19758048   69984228      23% /home
        OUTPUT
      end

      it 'reports all zfs filesystems' do
        allow(subject).to receive(:alert).with('disk /', :ok, 0.6267130394624543, '63% used, 6.7GiB free')
        allow(subject).to receive(:alert).with('disk /home', :ok, 0.22016432923987797, '23% used, 66.7GiB free')
        subject.disk
        expect(subject).to have_received(:alert).with('disk /', :ok, 0.6267130394624543, '63% used, 6.7GiB free')
        expect(subject).to have_received(:alert).with('disk /home', :ok, 0.22016432923987797, '23% used, 66.7GiB free')
      end
    end

    context 'with huge disks and a lot of free space' do
      before do
        allow(subject).to receive(:df).and_return(<<~OUTPUT)
          Filesystem     1024-blocks        Used  Available Capacity Mounted on
          tank           11311939200 10183714944 1128224256      91% /tank
        OUTPUT
      end

      it 'reports a correct lenient state' do
        allow(subject).to receive(:alert).with('disk /tank', :ok, 0.9002625247490722, '91% used, 1.0TiB free')
        subject.disk
        expect(subject).to have_received(:alert).with('disk /tank', :ok, 0.9002625247490722, '91% used, 1.0TiB free')
      end
    end
  end

  describe '#bsd_swap' do
    context 'with swap devices' do
      before do
        allow(subject).to receive(:`).with('swapinfo').and_return(<<~OUTPUT)
          Device         1024-blocks     Used    Avail Capacity
          /dev/da0p2         2097152  1347904   749248    64%
          /dev/ggate0           1024        0     1024     0%
          Total              2098176  1347904   750272    64%
        OUTPUT
      end

      it 'reports correct values' do
        allow(subject).to receive(:report_pct).with(:swap, 0.6424170326988775, 'used')
        subject.bsd_swap
        expect(subject).to have_received(:report_pct).with(:swap, 0.6424170326988775, 'used')
      end
    end

    context 'without swap devices' do
      before do
        allow(subject).to receive(:`).with('swapinfo').and_return(<<~OUTPUT)
          Device         1024-blocks     Used    Avail Capacity
        OUTPUT
      end

      it 'reports no value' do
        allow(subject).to receive(:report_pct)
        subject.bsd_swap
        expect(subject).not_to have_received(:report_pct)
      end
    end
  end

  describe '#linux_swap' do
    context 'with swap devices' do
      before do
        allow(File).to receive(:read).with('/proc/swaps').and_return(<<~OUTPUT)
          Filename				Type		Size		Used		Priority
          /dev/sdb4                               partition	4193276		2848268		-2
          /dev/sda4                               partition	4193276		0		-3
        OUTPUT
      end

      it 'reports correct values' do
        allow(subject).to receive(:report_pct).with(:swap, 0.339623244451355, 'used')
        subject.linux_swap
        expect(subject).to have_received(:report_pct).with(:swap, 0.339623244451355, 'used')
      end
    end

    context 'without swap devices' do
      before do
        allow(File).to receive(:read).with('/proc/swaps').and_return(<<~OUTPUT)
          Filename				Type		Size		Used		Priority
        OUTPUT
      end

      it 'reports no value' do
        allow(subject).to receive(:report_pct)
        subject.linux_swap
        expect(subject).not_to have_received(:report_pct)
      end
    end
  end

  describe '#bsd_uptime' do
    context 'when given unexpected data' do
      before do
        allow(subject).to receive(:`).with('uptime').and_return(<<~DOCUMENT)
          10:27:42 up 20:05,  load averages: 0.79, 0.50, 0.44
        DOCUMENT
      end

      it 'reports critical state' do
        allow(subject).to receive(:report)
        subject.bsd_uptime
        expect(subject).to have_received(:report).with(service: 'uptime', description: <<~DESCRIPTION.chomp, state: 'critical')
          Error parsing uptime: parse error on value "load averages:" (LOAD_AVERAGES) on line 1:
          10:27:42 up 20:05,  load averages: 0.79, 0.50, 0.44
                              ^~~~~~~~~~~~~~
        DESCRIPTION
      end
    end

    context 'when given malformed data' do
      before do
        allow(subject).to receive(:`).with('uptime').and_return(<<~DOCUMENT)
          10:27:42 up 20:05,  1 user,  load average: 0.79, 0.50, 0.44 [IO: 0.15, 0.12, 0.08 CPU: 0.64, 0.38, 0.35]
        DOCUMENT
      end

      it 'reports critical state' do
        allow(subject).to receive(:report)
        subject.bsd_uptime
        expect(subject).to have_received(:report).with(service: 'uptime', description: <<~DESCRIPTION.chomp, state: 'critical')
          Error parsing uptime: unexpected data on line 1:
          10:27:42 up 20:05,  1 user,  load average: 0.79, 0.50, 0.44 [IO: 0.15, 0.12, 0.08 CPU: 0.64, 0.38, 0.35]
                                                                      ^
        DESCRIPTION
      end
    end
  end
end
