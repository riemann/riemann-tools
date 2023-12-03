# frozen_string_literal: true

require 'riemann/tools/haproxy'

RSpec.describe Riemann::Tools::Haproxy do
  context('#tick') do
    before do
      ARGV.replace(['--stats-url', 'http://localhost'])

      allow(subject).to receive(:body).and_return(<<~DATA)
        # pxname,svname,qcur,qmax,scur,smax,slim,stot,bin,bout,dreq,dresp,ereq,econ,eresp,wretr,wredis,status,weight,act,bck,chkfail,chkdown,lastchg,downtime,qlimit,pid,iid,sid,throttle,lbtot,tracked,type,rate,rate_lim,rate_max,check_status,check_code,check_duration,hrsp_1xx,hrsp_2xx,hrsp_3xx,hrsp_4xx,hrsp_5xx,hrsp_other,hanafail,req_rate,req_rate_max,req_tot,cli_abrt,srv_abrt,comp_in,comp_out,comp_byp,comp_rsp,lastsess,last_chk,last_agt,qtime,ctime,rtime,ttime,agent_status,agent_code,agent_duration,check_desc,agent_desc,check_rise,check_fall,check_health,agent_rise,agent_fall,agent_health,addr,cookie,mode,algo,conn_rate,conn_rate_max,conn_tot,intercepted,dcon,dses,wrew,connect,reuse,cache_lookups,cache_hits,srv_icur,src_ilim,qtime_max,ctime_max,rtime_max,ttime_max,eint,idle_conn_cur,safe_conn_cur,used_conn_cur,need_conn_est,
        ft-http,FRONTEND,,,0,24,8000,911,225427,282808,0,0,142,,,,,OPEN,,,,,,,,,1,2,0,,,,0,0,0,18,,,,0,0,86,142,1076,0,,0,46,1304,,,0,0,0,0,,,,,,,,,,,,,,,,,,,,,http,,0,18,911,0,0,0,0,,,0,0,,,,,,,0,,,,,
        ft-https,FRONTEND,,,4,23,8000,442138,1437985213,6885481212,0,0,49,,,,,OPEN,,,,,,,,,1,3,0,,,,0,2,0,41,,,,,,,,,,,0,0,0,,,0,0,0,0,,,,,,,,,,,,,,,,,,,,,tcp,,2,41,442138,,0,0,0,,,,,,,,,,,0,,,,,
        stats,FRONTEND,,,1,1,8000,15939,3235327,99009201,0,0,0,,,,,OPEN,,,,,,,,,1,4,0,,,,0,1,0,1,,,,0,15938,0,0,0,0,,1,1,15939,,,0,0,0,0,,,,,,,,,,,,,,,,,,,,,http,,1,1,15939,15939,0,0,0,,,0,0,,,,,,,0,,,,,
      DATA
    end

    it 'reports ok state' do
      allow(subject).to receive(:report)
      subject.tick
      expect(subject).to have_received(:report).exactly(294).times
    end
  end
end
