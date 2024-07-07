# Changelog

## [v1.11.0](https://github.com/riemann/riemann-tools/tree/v1.11.0) (2024-07-07)

[Full Changelog](https://github.com/riemann/riemann-tools/compare/v1.10.0...v1.11.0)

**Implemented enhancements:**

- Add a new `riemann-hwmon` tool for harware monitors [\#297](https://github.com/riemann/riemann-tools/pull/297) ([smortex](https://github.com/smortex))
- Add support for ignoring IPs by ASN in `riemann-http` [\#295](https://github.com/riemann/riemann-tools/pull/295) ([smortex](https://github.com/smortex))
- Add support for a minimum TTL for events [\#294](https://github.com/riemann/riemann-tools/pull/294) ([smortex](https://github.com/smortex))
- Detect and report stray arguments [\#293](https://github.com/riemann/riemann-tools/pull/293) ([smortex](https://github.com/smortex))
- Add leniency to disk thresholds of `riemann-health` [\#282](https://github.com/riemann/riemann-tools/pull/282) ([smortex](https://github.com/smortex))
- Add `riemann-tls-check` to monitor TLS certificates [\#253](https://github.com/riemann/riemann-tools/pull/253) ([smortex](https://github.com/smortex))

**Fixed bugs:**

- Minor `riemann-hwmon` improvements [\#298](https://github.com/riemann/riemann-tools/pull/298) ([smortex](https://github.com/smortex))
- Fix `riemann-nginx` checks selection [\#292](https://github.com/riemann/riemann-tools/pull/292) ([smortex](https://github.com/smortex))
- Fix `riemann-health` memory reporting when using ZFS on Linux [\#289](https://github.com/riemann/riemann-tools/pull/289) ([smortex](https://github.com/smortex))

**Closed issues:**

- RFC: `riemann-domain-check` to monitor domain name expiration date [\#249](https://github.com/riemann/riemann-tools/issues/249)

## [v1.10.0](https://github.com/riemann/riemann-tools/tree/v1.10.0) (2024-01-13)

[Full Changelog](https://github.com/riemann/riemann-tools/compare/v1.9.1...v1.10.0)

**Implemented enhancements:**

- Add support for options with spaces to `riemann-wrapper` [\#280](https://github.com/riemann/riemann-tools/pull/280) ([smortex](https://github.com/smortex))

## [v1.9.1](https://github.com/riemann/riemann-tools/tree/v1.9.1) (2023-12-08)

[Full Changelog](https://github.com/riemann/riemann-tools/compare/v1.9.0...v1.9.1)

**Fixed bugs:**

- Fix `riemann-haproxy` NoMethodError [\#275](https://github.com/riemann/riemann-tools/pull/275) ([smortex](https://github.com/smortex))

## [v1.9.0](https://github.com/riemann/riemann-tools/tree/v1.9.0) (2023-12-08)

[Full Changelog](https://github.com/riemann/riemann-tools/compare/v1.8.2...v1.9.0)

**Implemented enhancements:**

- Use truncated exponential backoff for reconnection [\#272](https://github.com/riemann/riemann-tools/pull/272) ([smortex](https://github.com/smortex))
- Add redirect support to `riemann-http-check` [\#270](https://github.com/riemann/riemann-tools/pull/270) ([smortex](https://github.com/smortex))

**Fixed bugs:**

- Fix `riemann-haproxy` with Ruby 3.0+ [\#273](https://github.com/riemann/riemann-tools/pull/273) ([smortex](https://github.com/smortex))

## [v1.8.2](https://github.com/riemann/riemann-tools/tree/v1.8.2) (2023-05-22)

[Full Changelog](https://github.com/riemann/riemann-tools/compare/v1.8.1...v1.8.2)

**Fixed bugs:**

- Gracefully handle all communication errors [\#268](https://github.com/riemann/riemann-tools/pull/268) ([smortex](https://github.com/smortex))

## [v1.8.1](https://github.com/riemann/riemann-tools/tree/v1.8.1) (2023-02-28)

[Full Changelog](https://github.com/riemann/riemann-tools/compare/v1.8.0...v1.8.1)

**Fixed bugs:**

- Improve event sending thread lifecycle management [\#265](https://github.com/riemann/riemann-tools/pull/265) ([smortex](https://github.com/smortex))
- Make sure all events are send before terminating [\#264](https://github.com/riemann/riemann-tools/pull/264) ([smortex](https://github.com/smortex))

## [v1.8.0](https://github.com/riemann/riemann-tools/tree/v1.8.0) (2023-02-02)

[Full Changelog](https://github.com/riemann/riemann-tools/compare/v1.7.1...v1.8.0)

**Implemented enhancements:**

- Send events in bulk when they are stacking [\#261](https://github.com/riemann/riemann-tools/pull/261) ([smortex](https://github.com/smortex))

## [v1.7.1](https://github.com/riemann/riemann-tools/tree/v1.7.1) (2023-01-12)

[Full Changelog](https://github.com/riemann/riemann-tools/compare/v1.7.0...v1.7.1)

**Fixed bugs:**

- Fix uninitialized constant Riemann::Tools::VERSION \(NameError\) [\#259](https://github.com/riemann/riemann-tools/pull/259) ([smortex](https://github.com/smortex))

## [v1.7.0](https://github.com/riemann/riemann-tools/tree/v1.7.0) (2023-01-11)

[Full Changelog](https://github.com/riemann/riemann-tools/compare/v1.6.0...v1.7.0)

**Implemented enhancements:**

- Override default HTTP User-Agent and make it tuneable [\#257](https://github.com/riemann/riemann-tools/pull/257) ([smortex](https://github.com/smortex))
- Allow opting out of `riemann-http-check` latency state [\#255](https://github.com/riemann/riemann-tools/pull/255) ([smortex](https://github.com/smortex))
- Speed-up `riemann-http-check` with resolver and worker threads [\#254](https://github.com/riemann/riemann-tools/pull/254) ([smortex](https://github.com/smortex))
- Allow mdstat device filtering [\#252](https://github.com/riemann/riemann-tools/pull/252) ([smortex](https://github.com/smortex))
- Report mdstat health by device [\#251](https://github.com/riemann/riemann-tools/pull/251) ([smortex](https://github.com/smortex))

**Fixed bugs:**

- Fix `riemann-http-check` with unresolvable domains [\#256](https://github.com/riemann/riemann-tools/pull/256) ([smortex](https://github.com/smortex))

## [v1.6.0](https://github.com/riemann/riemann-tools/tree/v1.6.0) (2022-11-04)

[Full Changelog](https://github.com/riemann/riemann-tools/compare/v1.5.0...v1.6.0)

**Implemented enhancements:**

- Add `riemann-http-check` to monitor HTTP\(S\) resources [\#248](https://github.com/riemann/riemann-tools/pull/248) ([smortex](https://github.com/smortex))
- Add FreeBSD support to `riemann-net` [\#247](https://github.com/riemann/riemann-tools/pull/247) ([smortex](https://github.com/smortex))

**Fixed bugs:**

- Fix `riemann-health` detection of `df` header [\#246](https://github.com/riemann/riemann-tools/pull/246) ([smortex](https://github.com/smortex))
- Fix/Improve `riemann-md` mdstat parser [\#245](https://github.com/riemann/riemann-tools/pull/245) ([smortex](https://github.com/smortex))

## [v1.5.0](https://github.com/riemann/riemann-tools/tree/v1.5.0) (2022-09-08)

[Full Changelog](https://github.com/riemann/riemann-tools/compare/v1.4.0...v1.5.0)

**Implemented enhancements:**

- Improve error reporting on parse error [\#242](https://github.com/riemann/riemann-tools/pull/242) ([smortex](https://github.com/smortex))

**Fixed bugs:**

- Fix `riemann-haproxy` HTTP response processing [\#243](https://github.com/riemann/riemann-tools/pull/243) ([ahoetker-deca](https://github.com/ahoetker-deca))
- Fix `riemann-md` parsing of mdstat when device is being checked [\#241](https://github.com/riemann/riemann-tools/pull/241) ([smortex](https://github.com/smortex))

## [v1.4.0](https://github.com/riemann/riemann-tools/tree/v1.4.0) (2022-08-30)

[Full Changelog](https://github.com/riemann/riemann-tools/compare/v1.3.0...v1.4.0)

**Implemented enhancements:**

- Improve zpool state reporting [\#239](https://github.com/riemann/riemann-tools/pull/239) ([smortex](https://github.com/smortex))

**Fixed bugs:**

- Fix zpool/md informational messages reporting [\#238](https://github.com/riemann/riemann-tools/pull/238) ([smortex](https://github.com/smortex))
- Fix detection of degraded zpool [\#237](https://github.com/riemann/riemann-tools/pull/237) ([smortex](https://github.com/smortex))

## [v1.3.0](https://github.com/riemann/riemann-tools/tree/v1.3.0) (2022-08-29)

[Full Changelog](https://github.com/riemann/riemann-tools/compare/v1.2.0...v1.3.0)

**Implemented enhancements:**

- Add support for a configuration file to `riemann-wrapper` [\#235](https://github.com/riemann/riemann-tools/pull/235) ([smortex](https://github.com/smortex))
- Add `riemann-md` to monitor Linux RAID/md health [\#232](https://github.com/riemann/riemann-tools/pull/232) ([smortex](https://github.com/smortex))
- Add `riemann-zpool` to monitor zpool health [\#231](https://github.com/riemann/riemann-tools/pull/231) ([smortex](https://github.com/smortex))

**Fixed bugs:**

- Fix race condition in riemann-wrapper [\#233](https://github.com/riemann/riemann-tools/pull/233) ([smortex](https://github.com/smortex))

**Closed issues:**

- There is some kind of race condition in riemann-wrapper [\#230](https://github.com/riemann/riemann-tools/issues/230)

**Merged pull requests:**

- Stop riemann-wrapper if a tool raise an error [\#234](https://github.com/riemann/riemann-tools/pull/234) ([smortex](https://github.com/smortex))

## [v1.2.0](https://github.com/riemann/riemann-tools/tree/v1.2.0) (2022-08-17)

[Full Changelog](https://github.com/riemann/riemann-tools/compare/v1.1.1...v1.2.0)

**Implemented enhancements:**

- Add users monitoring to riemann-health [\#226](https://github.com/riemann/riemann-tools/pull/226) ([smortex](https://github.com/smortex))
- Add a wrapper to run multiple tools in a single process [\#225](https://github.com/riemann/riemann-tools/pull/225) ([smortex](https://github.com/smortex))
- Add swap monitoring to riemann-health [\#222](https://github.com/riemann/riemann-tools/pull/222) ([smortex](https://github.com/smortex))
- Add uptime monitoring to riemann-health [\#218](https://github.com/riemann/riemann-tools/pull/218) ([smortex](https://github.com/smortex))

**Fixed bugs:**

- Ignore squashfs from disks usage reporting [\#228](https://github.com/riemann/riemann-tools/pull/228) ([smortex](https://github.com/smortex))
- Fix service name mismatch for rx/tx drop in riemann-net [\#217](https://github.com/riemann/riemann-tools/pull/217) ([smortex](https://github.com/smortex))

**Merged pull requests:**

- Normalize class names [\#224](https://github.com/riemann/riemann-tools/pull/224) ([smortex](https://github.com/smortex))
- Move all extra tool classes in dedicated files [\#223](https://github.com/riemann/riemann-tools/pull/223) ([smortex](https://github.com/smortex))
- Removed travis [\#220](https://github.com/riemann/riemann-tools/pull/220) ([jamtur01](https://github.com/jamtur01))
- Move all base tool classes in dedicated files [\#219](https://github.com/riemann/riemann-tools/pull/219) ([smortex](https://github.com/smortex))

## [v1.1.1](https://github.com/riemann/riemann-tools/tree/v1.1.1) (2022-07-02)

[Full Changelog](https://github.com/riemann/riemann-tools/compare/v1.1.0...v1.1.1)

**Fixed bugs:**

- Ignore overlay filesystems by default [\#215](https://github.com/riemann/riemann-tools/pull/215) ([smortex](https://github.com/smortex))

## [v1.1.0](https://github.com/riemann/riemann-tools/tree/v1.1.0) (2022-07-01)

[Full Changelog](https://github.com/riemann/riemann-tools/compare/v1.0.0...v1.1.0)

**Implemented enhancements:**

- Report computed disk metric [\#213](https://github.com/riemann/riemann-tools/pull/213) ([smortex](https://github.com/smortex))
- Add support for FreeBSD system fd monitoring [\#204](https://github.com/riemann/riemann-tools/pull/204) ([smortex](https://github.com/smortex))
- Improve interface matching flexibility [\#203](https://github.com/riemann/riemann-tools/pull/203) ([smortex](https://github.com/smortex))
- Improve disk usage reporting [\#200](https://github.com/riemann/riemann-tools/pull/200) ([smortex](https://github.com/smortex))

**Fixed bugs:**

- Revert tmpfs as an ignored filesystem by default [\#206](https://github.com/riemann/riemann-tools/pull/206) ([smortex](https://github.com/smortex))
- Fix network interfaces reporting [\#202](https://github.com/riemann/riemann-tools/pull/202) ([smortex](https://github.com/smortex))
- Fix setting custom load thresholds [\#201](https://github.com/riemann/riemann-tools/pull/201) ([smortex](https://github.com/smortex))

**Closed issues:**

- Disk usage resolution is coarse [\#212](https://github.com/riemann/riemann-tools/issues/212)
- Load warning/critical doesn't work [\#182](https://github.com/riemann/riemann-tools/issues/182)

**Merged pull requests:**

- Modernized riemann-ntp and included warning for macOS [\#211](https://github.com/riemann/riemann-tools/pull/211) ([jamtur01](https://github.com/jamtur01))
- Create dependabot.yml [\#209](https://github.com/riemann/riemann-tools/pull/209) ([jamtur01](https://github.com/jamtur01))
- Create codeql-analysis.yml [\#208](https://github.com/riemann/riemann-tools/pull/208) ([jamtur01](https://github.com/jamtur01))
- Setup Rubocop [\#205](https://github.com/riemann/riemann-tools/pull/205) ([smortex](https://github.com/smortex))

## [v1.0.0](https://github.com/riemann/riemann-tools/tree/v1.0.0) (2022-06-22)

[Full Changelog](https://github.com/riemann/riemann-tools/compare/0.2.14...v1.0.0)

**Implemented enhancements:**

- Add support for TLS [\#196](https://github.com/riemann/riemann-tools/pull/196) ([smortex](https://github.com/smortex))
- Hide riemann-tools parameters from process table [\#188](https://github.com/riemann/riemann-tools/pull/188) ([dch](https://github.com/dch))

**Fixed bugs:**

- Fix cpu and memory usage sorting [\#198](https://github.com/riemann/riemann-tools/pull/198) ([smortex](https://github.com/smortex))
- Exclude NFS from df [\#193](https://github.com/riemann/riemann-tools/pull/193) ([sheremetyev](https://github.com/sheremetyev))
- Fix df --exclude-type on alpine [\#192](https://github.com/riemann/riemann-tools/pull/192) ([Beanow](https://github.com/Beanow))

**Closed issues:**

- Official docker image\(s\) [\#189](https://github.com/riemann/riemann-tools/issues/189)
- Could not set docker-host via CLI [\#184](https://github.com/riemann/riemann-tools/issues/184)
- No support for TLS [\#142](https://github.com/riemann/riemann-tools/issues/142)

**Merged pull requests:**

- Implement automated docker builds of included tools. [\#190](https://github.com/riemann/riemann-tools/pull/190) ([Beanow](https://github.com/Beanow))

## [0.2.14](https://github.com/riemann/riemann-tools/tree/0.2.14) (2018-09-14)

[Full Changelog](https://github.com/riemann/riemann-tools/compare/0.2.13...0.2.14)

**Closed issues:**

- Trollop gem replaced by optimist [\#186](https://github.com/riemann/riemann-tools/issues/186)
- Regex format to check multiple processes [\#181](https://github.com/riemann/riemann-tools/issues/181)
- riemann-health - full command support [\#180](https://github.com/riemann/riemann-tools/issues/180)

## [0.2.13](https://github.com/riemann/riemann-tools/tree/0.2.13) (2018-01-17)

[Full Changelog](https://github.com/riemann/riemann-tools/compare/0.2.12...0.2.13)

**Closed issues:**

- riemann-net: Non-zero drop/error always mapped to warning state [\#177](https://github.com/riemann/riemann-tools/issues/177)
- riemann-consul: incorrect treatment of return value for leader query [\#175](https://github.com/riemann/riemann-tools/issues/175)
- Riemann-aws fails to use instance profile with error regarding required aws keys [\#169](https://github.com/riemann/riemann-tools/issues/169)
- riemann-zookeeper fails silently on zookeeper 3.3.x and below [\#98](https://github.com/riemann/riemann-tools/issues/98)
- Riemann riak tools spins up 2 erlang vms with the same node name simulataneously, causing one to fail [\#71](https://github.com/riemann/riemann-tools/issues/71)
- Service scripts [\#40](https://github.com/riemann/riemann-tools/issues/40)

**Merged pull requests:**

- riemann-net: Warn only on non-zero drop/error delta [\#183](https://github.com/riemann/riemann-tools/pull/183) ([sslavic](https://github.com/sslavic))
- Fix for riemann/riemann-tools/issues/175 [\#176](https://github.com/riemann/riemann-tools/pull/176) ([pieterbreed](https://github.com/pieterbreed))
- support prefixes for AWS S3 list [\#173](https://github.com/riemann/riemann-tools/pull/173) ([peterneubauer](https://github.com/peterneubauer))
- Add OpenBSD and Illumos \(sunos in uname -s\) to riemann-health [\#172](https://github.com/riemann/riemann-tools/pull/172) ([telser](https://github.com/telser))
- Fixing initialization failure when fog credentials are specified. [\#171](https://github.com/riemann/riemann-tools/pull/171) ([derekslager](https://github.com/derekslager))
- Add riemann-portcheck [\#170](https://github.com/riemann/riemann-tools/pull/170) ([sdx23](https://github.com/sdx23))
- \_stats/index/store isn't supported anymore in ES 5 but it looks like … [\#168](https://github.com/riemann/riemann-tools/pull/168) ([looprock](https://github.com/looprock))

## [0.2.12](https://github.com/riemann/riemann-tools/tree/0.2.12) (2017-01-22)

[Full Changelog](https://github.com/riemann/riemann-tools/compare/0.2.11...0.2.12)

**Closed issues:**

- riemann-elasticsearch: needs exception handling [\#166](https://github.com/riemann/riemann-tools/issues/166)
- Is riemann-docker not support disk I/O and net I/O monitoring? [\#162](https://github.com/riemann/riemann-tools/issues/162)

**Merged pull requests:**

- Add exception handling [\#167](https://github.com/riemann/riemann-tools/pull/167) ([rogeruiz](https://github.com/rogeruiz))
- Update riemann-proc [\#165](https://github.com/riemann/riemann-tools/pull/165) ([knackjax](https://github.com/knackjax))
- JSON dependency version set to ~\> 1.8 [\#163](https://github.com/riemann/riemann-tools/pull/163) ([markdingram](https://github.com/markdingram))

## [0.2.11](https://github.com/riemann/riemann-tools/tree/0.2.11) (2016-12-04)

[Full Changelog](https://github.com/riemann/riemann-tools/compare/0.2.10...0.2.11)

**Closed issues:**

- Docker image to run riemann-tools [\#164](https://github.com/riemann/riemann-tools/issues/164)
- riemann-varnish error [\#158](https://github.com/riemann/riemann-tools/issues/158)

**Merged pull requests:**

- Corrected kvm running instance count [\#161](https://github.com/riemann/riemann-tools/pull/161) ([TheBigfoot](https://github.com/TheBigfoot))
- fix typo [\#160](https://github.com/riemann/riemann-tools/pull/160) ([david-resnick](https://github.com/david-resnick))
- Adding basic s3 bucket metrics [\#159](https://github.com/riemann/riemann-tools/pull/159) ([peterneubauer](https://github.com/peterneubauer))
- Modified aws-rds-status and aws-sqs-status to default to IAM profile … [\#157](https://github.com/riemann/riemann-tools/pull/157) ([gorandev](https://github.com/gorandev))
- Create riemann-chronos based on riemann-marathon [\#156](https://github.com/riemann/riemann-tools/pull/156) ([pdericson](https://github.com/pdericson))
- Riemann Aws ELB: send 0 metric on empty result [\#155](https://github.com/riemann/riemann-tools/pull/155) ([krakatoa](https://github.com/krakatoa))
- Make riemann-docker multithreaded [\#154](https://github.com/riemann/riemann-tools/pull/154) ([gfv](https://github.com/gfv))

## [0.2.10](https://github.com/riemann/riemann-tools/tree/0.2.10) (2016-03-01)

[Full Changelog](https://github.com/riemann/riemann-tools/compare/0.2.9...0.2.10)

**Closed issues:**

- Riemann health stopped updating disk usage [\#148](https://github.com/riemann/riemann-tools/issues/148)
- Load average on AWS does not divide by number of cores [\#97](https://github.com/riemann/riemann-tools/issues/97)

**Merged pull requests:**

- Fixed issue with static disk monitoring [\#153](https://github.com/riemann/riemann-tools/pull/153) ([jamtur01](https://github.com/jamtur01))
- correctly call is\_bad? method [\#151](https://github.com/riemann/riemann-tools/pull/151) ([anho](https://github.com/anho))

## [0.2.9](https://github.com/riemann/riemann-tools/tree/0.2.9) (2016-02-20)

[Full Changelog](https://github.com/riemann/riemann-tools/compare/0.2.8...0.2.9)

**Closed issues:**

- Build a new gem file and publish [\#139](https://github.com/riemann/riemann-tools/issues/139)
- Dependency net-ssh \>= 3 requires ruby 2.0 [\#126](https://github.com/riemann/riemann-tools/issues/126)

**Merged pull requests:**

- Create ISSUE\_TEMPLATE.md [\#149](https://github.com/riemann/riemann-tools/pull/149) ([jamtur01](https://github.com/jamtur01))
- Improved riemann-proc [\#147](https://github.com/riemann/riemann-tools/pull/147) ([ktf](https://github.com/ktf))
- gather some simple metrics on query and fetch time [\#144](https://github.com/riemann/riemann-tools/pull/144) ([anho](https://github.com/anho))
- Release 0.2.8 [\#140](https://github.com/riemann/riemann-tools/pull/140) ([jamtur01](https://github.com/jamtur01))

## [0.2.8](https://github.com/riemann/riemann-tools/tree/0.2.8) (2016-02-09)

[Full Changelog](https://github.com/riemann/riemann-tools/compare/0.2.7...0.2.8)

**Closed issues:**

- problem sending tags [\#135](https://github.com/riemann/riemann-tools/issues/135)
- exclude iso9660 filesystems from riemann-health. [\#127](https://github.com/riemann/riemann-tools/issues/127)
- riemann-docker-health [\#119](https://github.com/riemann/riemann-tools/issues/119)
- make tags additive to CLI tags [\#99](https://github.com/riemann/riemann-tools/issues/99)
- Split repository [\#61](https://github.com/riemann/riemann-tools/issues/61)

**Merged pull requests:**

- Fixes \#127 - Excludes ISO9660 filesystems from riemann-health [\#145](https://github.com/riemann/riemann-tools/pull/145) ([jamtur01](https://github.com/jamtur01))
- Fixes \#99 - Additive tags [\#143](https://github.com/riemann/riemann-tools/pull/143) ([jamtur01](https://github.com/jamtur01))
- Updates to gems [\#141](https://github.com/riemann/riemann-tools/pull/141) ([jamtur01](https://github.com/jamtur01))
- Added tools split out back into the repo [\#138](https://github.com/riemann/riemann-tools/pull/138) ([jamtur01](https://github.com/jamtur01))
- Separate HAproxy's server state from server metrics [\#137](https://github.com/riemann/riemann-tools/pull/137) ([dobrinov](https://github.com/dobrinov))
- Splits out individual programs to GitHub Riemann org [\#136](https://github.com/riemann/riemann-tools/pull/136) ([jamtur01](https://github.com/jamtur01))
- Enable riemann-elb-metrics to use IAM Instance profile [\#133](https://github.com/riemann/riemann-tools/pull/133) ([iramello](https://github.com/iramello))
- Avoid event to expire before we actually check again [\#132](https://github.com/riemann/riemann-tools/pull/132) ([ktf](https://github.com/ktf))
- Use conventional state "ok" in place of "green" [\#131](https://github.com/riemann/riemann-tools/pull/131) ([ktf](https://github.com/ktf))
- Corrects a typo when specifying dependencies. [\#130](https://github.com/riemann/riemann-tools/pull/130) ([yundt](https://github.com/yundt))
- Add Marathon watcher [\#129](https://github.com/riemann/riemann-tools/pull/129) ([ktf](https://github.com/ktf))
- Add Mesos metrics watcher [\#128](https://github.com/riemann/riemann-tools/pull/128) ([ktf](https://github.com/ktf))
- RFC : Riemann-consul : Sends consul services status to riemann [\#125](https://github.com/riemann/riemann-tools/pull/125) ([shanielh](https://github.com/shanielh))
- Riemann-docker-health : Multiple changes [\#124](https://github.com/riemann/riemann-tools/pull/124) ([shanielh](https://github.com/shanielh))
- Fix/str maybe nil [\#123](https://github.com/riemann/riemann-tools/pull/123) ([jsvisa](https://github.com/jsvisa))
- Added AWS SQS monitor [\#121](https://github.com/riemann/riemann-tools/pull/121) ([krakatoa](https://github.com/krakatoa))
- Added docker-health tool [\#120](https://github.com/riemann/riemann-tools/pull/120) ([shanielh](https://github.com/shanielh))
- riemann-freeswitch sends number of threads used by Freeswitch [\#118](https://github.com/riemann/riemann-tools/pull/118) ([krakatoa](https://github.com/krakatoa))
- Change the way `ioreqs` metric is handled [\#117](https://github.com/riemann/riemann-tools/pull/117) ([pariviere](https://github.com/pariviere))
- add option to specify a proxied path prefix [\#115](https://github.com/riemann/riemann-tools/pull/115) ([peterneubauer](https://github.com/peterneubauer))

## [0.2.7](https://github.com/riemann/riemann-tools/tree/0.2.7) (2015-07-17)

[Full Changelog](https://github.com/riemann/riemann-tools/compare/0.2.6...0.2.7)

## [0.2.6](https://github.com/riemann/riemann-tools/tree/0.2.6) (2015-04-21)

[Full Changelog](https://github.com/riemann/riemann-tools/compare/0.2.5...0.2.6)

**Closed issues:**

- Error in riemann-net when new interfaces are added [\#112](https://github.com/riemann/riemann-tools/issues/112)
- riemann-varnish not working with Varnish 4+ [\#104](https://github.com/riemann/riemann-tools/issues/104)
- Riemann-health not working on Ubuntu 14.10 x64 vmlinuz-3.16.0-28-generic [\#103](https://github.com/riemann/riemann-tools/issues/103)
- Make riemann-rabbitmq honor even SSL connections [\#101](https://github.com/riemann/riemann-tools/issues/101)

**Merged pull requests:**

- Send out "expired" state when riemann-net stops seeing an interface [\#114](https://github.com/riemann/riemann-tools/pull/114) ([md5](https://github.com/md5))
- Skip network metric comparison for newly added interfaces [\#113](https://github.com/riemann/riemann-tools/pull/113) ([md5](https://github.com/md5))
- riemann-proc alerts output which processes matched [\#111](https://github.com/riemann/riemann-tools/pull/111) ([tcrayford](https://github.com/tcrayford))
- abort if no DB specified [\#110](https://github.com/riemann/riemann-tools/pull/110) ([peterneubauer](https://github.com/peterneubauer))
- Adding monitoring of an RDS instance [\#109](https://github.com/riemann/riemann-tools/pull/109) ([peterneubauer](https://github.com/peterneubauer))
- Added NTP statistics collector [\#108](https://github.com/riemann/riemann-tools/pull/108) ([jamtur01](https://github.com/jamtur01))
- Fixed failed comparison of Fixnum with True [\#107](https://github.com/riemann/riemann-tools/pull/107) ([iramello](https://github.com/iramello))
- in my rabbitmq instance, it seems there is \['messages\_ready'\] missing on... [\#106](https://github.com/riemann/riemann-tools/pull/106) ([peterneubauer](https://github.com/peterneubauer))
- Added check and switch for Varnish 4 [\#105](https://github.com/riemann/riemann-tools/pull/105) ([jamtur01](https://github.com/jamtur01))

## [0.2.5](https://github.com/riemann/riemann-tools/tree/0.2.5) (2015-01-26)

[Full Changelog](https://github.com/riemann/riemann-tools/compare/0.2.3...0.2.5)

**Merged pull requests:**

- Adding support for https connection [\#102](https://github.com/riemann/riemann-tools/pull/102) ([peterneubauer](https://github.com/peterneubauer))
- Adds monitoring a folder based on its number of files [\#100](https://github.com/riemann/riemann-tools/pull/100) ([iramello](https://github.com/iramello))
- add directory space use monitoring [\#96](https://github.com/riemann/riemann-tools/pull/96) ([tcrayford](https://github.com/tcrayford))

## [0.2.3](https://github.com/riemann/riemann-tools/tree/0.2.3) (2015-01-06)

[Full Changelog](https://github.com/riemann/riemann-tools/compare/0.2.2...0.2.3)

**Merged pull requests:**

- Add CLI status check [\#95](https://github.com/riemann/riemann-tools/pull/95) ([default50](https://github.com/default50))
- Add support for reporting current number of conferences in riemann-freeswitch [\#94](https://github.com/riemann/riemann-tools/pull/94) ([default50](https://github.com/default50))
- Monitor RabbitMQ queue sizes and node memory/disk health [\#93](https://github.com/riemann/riemann-tools/pull/93) ([mpalmer](https://github.com/mpalmer))
- Alert if there are any outstanding partition transfers [\#92](https://github.com/riemann/riemann-tools/pull/92) ([mpalmer](https://github.com/mpalmer))
- Avoid failure if process checked user is different from riemann agent. [\#91](https://github.com/riemann/riemann-tools/pull/91) ([default50](https://github.com/default50))
- Riemann freeswitch [\#90](https://github.com/riemann/riemann-tools/pull/90) ([default50](https://github.com/default50))
- Add support for some extra Riak stats [\#89](https://github.com/riemann/riemann-tools/pull/89) ([algernon](https://github.com/algernon))
- Correct comment in riemann-net [\#88](https://github.com/riemann/riemann-tools/pull/88) ([danielcompton](https://github.com/danielcompton))
- Fixed broken memory calculation for OSX Mavericks [\#87](https://github.com/riemann/riemann-tools/pull/87) ([Kungi](https://github.com/Kungi))
- Fix typo in riemann-health [\#86](https://github.com/riemann/riemann-tools/pull/86) ([jsyrjala](https://github.com/jsyrjala))

## [0.2.2](https://github.com/riemann/riemann-tools/tree/0.2.2) (2014-06-30)

[Full Changelog](https://github.com/riemann/riemann-tools/compare/0.2.1...0.2.2)

**Closed issues:**

- Elasticsearch tool gives error NoMethodError undefined method `URI' [\#84](https://github.com/riemann/riemann-tools/issues/84)

**Merged pull requests:**

- one-character fix: Make riemann-aws-billing work again [\#85](https://github.com/riemann/riemann-tools/pull/85) ([benley](https://github.com/benley))
- Fix for latest riemann-client changes [\#83](https://github.com/riemann/riemann-tools/pull/83) ([eric](https://github.com/eric))
- riemann proc regex should quote args to grep [\#82](https://github.com/riemann/riemann-tools/pull/82) ([tcrayford](https://github.com/tcrayford))
- riemann-redis migrated to https://github.com/riemann/riemann-redis [\#81](https://github.com/riemann/riemann-tools/pull/81) ([fborgnia](https://github.com/fborgnia))

## [0.2.1](https://github.com/riemann/riemann-tools/tree/0.2.1) (2014-03-26)

[Full Changelog](https://github.com/riemann/riemann-tools/compare/0.2.0...0.2.1)

**Merged pull requests:**

- Update FreeBSD load average for 1 min [\#79](https://github.com/riemann/riemann-tools/pull/79) ([zachfi](https://github.com/zachfi))
- Added riemann-varnish collector script [\#77](https://github.com/riemann/riemann-tools/pull/77) ([pradeepchhetri](https://github.com/pradeepchhetri))
- allow dashes in diskstats volume names to support lvm volumes like "dm-0" [\#75](https://github.com/riemann/riemann-tools/pull/75) ([cmerrick](https://github.com/cmerrick))
- rieman-tools aws billing [\#74](https://github.com/riemann/riemann-tools/pull/74) ([jespada](https://github.com/jespada))
- Added basic metric monitoring for zookeeper [\#73](https://github.com/riemann/riemann-tools/pull/73) ([aterreno](https://github.com/aterreno))

## [0.2.0](https://github.com/riemann/riemann-tools/tree/0.2.0) (2014-01-23)

[Full Changelog](https://github.com/riemann/riemann-tools/compare/0.1.9...0.2.0)

**Closed issues:**

- riemann-net stopped working with beefcake version 0.4.0 [\#70](https://github.com/riemann/riemann-tools/issues/70)
- riemann-riak fails to detect if riak is down [\#54](https://github.com/riemann/riemann-tools/issues/54)

**Merged pull requests:**

- Add Apache Httpd Metrics [\#72](https://github.com/riemann/riemann-tools/pull/72) ([dmichel1](https://github.com/dmichel1))

## [0.1.9](https://github.com/riemann/riemann-tools/tree/0.1.9) (2013-12-10)

[Full Changelog](https://github.com/riemann/riemann-tools/compare/0.1.8...0.1.9)

**Merged pull requests:**

- Dup service in riemann-net, work around frozen str [\#69](https://github.com/riemann/riemann-tools/pull/69) ([gsandie](https://github.com/gsandie))
- workaround for beefcake frozen string issue [\#68](https://github.com/riemann/riemann-tools/pull/68) ([maxnewbould](https://github.com/maxnewbould))

## [0.1.8](https://github.com/riemann/riemann-tools/tree/0.1.8) (2013-11-11)

[Full Changelog](https://github.com/riemann/riemann-tools/compare/0.1.6...0.1.8)

## [0.1.6](https://github.com/riemann/riemann-tools/tree/0.1.6) (2013-11-11)

[Full Changelog](https://github.com/riemann/riemann-tools/compare/0.1.7...0.1.6)

**Closed issues:**

- riemann-redis run\_id can be infinity [\#65](https://github.com/riemann/riemann-tools/issues/65)
- License missing from gemspec [\#64](https://github.com/riemann/riemann-tools/issues/64)
- riemann-health EMSGSIZE Message too long - sendto\(2\) on OSX [\#16](https://github.com/riemann/riemann-tools/issues/16)
- add riemann-cloudwatch [\#9](https://github.com/riemann/riemann-tools/issues/9)

**Merged pull requests:**

- Add a license and description to the rakefile [\#67](https://github.com/riemann/riemann-tools/pull/67) ([gsandie](https://github.com/gsandie))
- Set run\_id property to zero [\#66](https://github.com/riemann/riemann-tools/pull/66) ([gsandie](https://github.com/gsandie))

## [0.1.7](https://github.com/riemann/riemann-tools/tree/0.1.7) (2013-10-18)

[Full Changelog](https://github.com/riemann/riemann-tools/compare/0.1.5...0.1.7)

**Closed issues:**

- riemann-riak error when adding tag [\#62](https://github.com/riemann/riemann-tools/issues/62)

**Merged pull requests:**

- add riemann-proc running process counter [\#63](https://github.com/riemann/riemann-tools/pull/63) ([cmerrick](https://github.com/cmerrick))

## [0.1.5](https://github.com/riemann/riemann-tools/tree/0.1.5) (2013-10-15)

[Full Changelog](https://github.com/riemann/riemann-tools/compare/0.1.3...0.1.5)

**Closed issues:**

- Ripe new release? [\#59](https://github.com/riemann/riemann-tools/issues/59)

**Merged pull requests:**

- Riemann mysql client [\#60](https://github.com/riemann/riemann-tools/pull/60) ([fborgnia](https://github.com/fborgnia))
- Feature/riemann fd [\#58](https://github.com/riemann/riemann-tools/pull/58) ([ainsleyc](https://github.com/ainsleyc))
- Set the executable bit on riemann elb metrics [\#57](https://github.com/riemann/riemann-tools/pull/57) ([gsandie](https://github.com/gsandie))
- First pass at pulling metrics from AWS ELBs [\#56](https://github.com/riemann/riemann-tools/pull/56) ([gsandie](https://github.com/gsandie))
- Fix small problems in riemann elasticsearch [\#55](https://github.com/riemann/riemann-tools/pull/55) ([gsandie](https://github.com/gsandie))
- Reauthenticate redis on reconnections [\#53](https://github.com/riemann/riemann-tools/pull/53) ([gsandie](https://github.com/gsandie))
- Riemann rabbitmq - real basic rabbitmq metrics [\#52](https://github.com/riemann/riemann-tools/pull/52) ([gsandie](https://github.com/gsandie))
- pass redis info fields' string value in status field [\#51](https://github.com/riemann/riemann-tools/pull/51) ([narrative-joe](https://github.com/narrative-joe))
- Add health status to riemann nginx [\#50](https://github.com/riemann/riemann-tools/pull/50) ([gsandie](https://github.com/gsandie))
- Report ok when resmon connection is working [\#49](https://github.com/riemann/riemann-tools/pull/49) ([gsandie](https://github.com/gsandie))
- Add a simple elastic search check [\#48](https://github.com/riemann/riemann-tools/pull/48) ([gsandie](https://github.com/gsandie))
- Add SSL support for riemann-riak [\#46](https://github.com/riemann/riemann-tools/pull/46) ([supersix4our](https://github.com/supersix4our))
- resmon: don't send metrics as strings [\#45](https://github.com/riemann/riemann-tools/pull/45) ([goblin](https://github.com/goblin))
- Add missing tx errors to riemann-net [\#44](https://github.com/riemann/riemann-tools/pull/44) ([gsandie](https://github.com/gsandie))

## [0.1.3](https://github.com/riemann/riemann-tools/tree/0.1.3) (2013-05-28)

[Full Changelog](https://github.com/riemann/riemann-tools/compare/0.1.2...0.1.3)

**Closed issues:**

- riemann-kvminstance\(s\) duplicate scripts [\#34](https://github.com/riemann/riemann-tools/issues/34)

**Merged pull requests:**

- Remove dead code [\#43](https://github.com/riemann/riemann-tools/pull/43) ([lwf](https://github.com/lwf))
- Handle timeouts [\#42](https://github.com/riemann/riemann-tools/pull/42) ([lwf](https://github.com/lwf))
- Allow riemann resmon to use hostname or FQDN for events [\#41](https://github.com/riemann/riemann-tools/pull/41) ([gsandie](https://github.com/gsandie))
- Remove duplicated file riemann-kvminstances. [\#39](https://github.com/riemann/riemann-tools/pull/39) ([default50](https://github.com/default50))
- Add ability to add attributes from CLI [\#38](https://github.com/riemann/riemann-tools/pull/38) ([lwf](https://github.com/lwf))

## [0.1.2](https://github.com/riemann/riemann-tools/tree/0.1.2) (2013-04-30)

[Full Changelog](https://github.com/riemann/riemann-tools/compare/0.0.9...0.1.2)

**Closed issues:**

- riemann-nginx? [\#31](https://github.com/riemann/riemann-tools/issues/31)
- Commit \#7de2572ccace567d90e555415498c2325bb8d87f seems to have borked how the hostname get's sent [\#22](https://github.com/riemann/riemann-tools/issues/22)

**Merged pull requests:**

- allow dynamic setting of riak cookie field [\#37](https://github.com/riemann/riemann-tools/pull/37) ([Bhuwan](https://github.com/Bhuwan))
- Fixed two bugs: [\#36](https://github.com/riemann/riemann-tools/pull/36) ([default50](https://github.com/default50))
- Adding reporting capabilities for FreeSWITCH calls and channels. [\#35](https://github.com/riemann/riemann-tools/pull/35) ([default50](https://github.com/default50))
- riemann-nginx-status [\#33](https://github.com/riemann/riemann-tools/pull/33) ([BrianHicks](https://github.com/BrianHicks))
- Typo,  @httpstats -\> @httpstatus [\#32](https://github.com/riemann/riemann-tools/pull/32) ([jegt](https://github.com/jegt))
- Add a Redis SLOWLOG client [\#30](https://github.com/riemann/riemann-tools/pull/30) ([inkel](https://github.com/inkel))
- Improve riemann-redis client [\#29](https://github.com/riemann/riemann-tools/pull/29) ([inkel](https://github.com/inkel))
- Riemann aws-status [\#28](https://github.com/riemann/riemann-tools/pull/28) ([gsandie](https://github.com/gsandie))
- Allow seperate health checks [\#27](https://github.com/riemann/riemann-tools/pull/27) ([gsandie](https://github.com/gsandie))
- Fix incorrect resmon host vars [\#26](https://github.com/riemann/riemann-tools/pull/26) ([gsandie](https://github.com/gsandie))
- Riemann resmon improvements [\#25](https://github.com/riemann/riemann-tools/pull/25) ([gsandie](https://github.com/gsandie))
- Added a plugin for Resmon [\#24](https://github.com/riemann/riemann-tools/pull/24) ([goblin](https://github.com/goblin))
- Update host-val with even-host only if really set [\#23](https://github.com/riemann/riemann-tools/pull/23) ([bipthelin](https://github.com/bipthelin))
- Fallback to riak-admin if nothing else works [\#21](https://github.com/riemann/riemann-tools/pull/21) ([bipthelin](https://github.com/bipthelin))
- Default event hostname [\#20](https://github.com/riemann/riemann-tools/pull/20) ([timshadel](https://github.com/timshadel))
- Add memcached monitoring support for riemann-tools. [\#19](https://github.com/riemann/riemann-tools/pull/19) ([fcuny](https://github.com/fcuny))
- Typo in rieman-riak using :servie instead of :service [\#18](https://github.com/riemann/riemann-tools/pull/18) ([dgtized](https://github.com/dgtized))
- Add riemann-aws-status [\#13](https://github.com/riemann/riemann-tools/pull/13) ([lwf](https://github.com/lwf))

## [0.0.9](https://github.com/riemann/riemann-tools/tree/0.0.9) (2012-12-08)

[Full Changelog](https://github.com/riemann/riemann-tools/compare/version-0.0.2...0.0.9)

**Merged pull requests:**

- fix overflowing text from ps by swapping args for comm [\#17](https://github.com/riemann/riemann-tools/pull/17) ([dch](https://github.com/dch))
- Fix darwin cpu usage. Show used cpu instead of idle [\#15](https://github.com/riemann/riemann-tools/pull/15) ([henrikno](https://github.com/henrikno))
- Fix core count on darwin [\#14](https://github.com/riemann/riemann-tools/pull/14) ([henrikno](https://github.com/henrikno))
- Add riemann-diskstats [\#12](https://github.com/riemann/riemann-tools/pull/12) ([lwf](https://github.com/lwf))
- Reflect each haproxy config as its own unique status [\#11](https://github.com/riemann/riemann-tools/pull/11) ([perezd](https://github.com/perezd))
- allow for a commandline configurable TTL. [\#10](https://github.com/riemann/riemann-tools/pull/10) ([perezd](https://github.com/perezd))
- add host properties to cloudant, haproxy, redis. [\#8](https://github.com/riemann/riemann-tools/pull/8) ([perezd](https://github.com/perezd))
- adds Cloudant.com shared cluster load balancer statistics/monitoring support [\#7](https://github.com/riemann/riemann-tools/pull/7) ([perezd](https://github.com/perezd))
- adds haproxy statistics monitoring support for riemann. [\#6](https://github.com/riemann/riemann-tools/pull/6) ([perezd](https://github.com/perezd))
- adds redis monitoring support to riemann-tools. [\#5](https://github.com/riemann/riemann-tools/pull/5) ([perezd](https://github.com/perezd))
- Prevent riemann-health from failing to report memory on OpenVZ virtual machines.  [\#4](https://github.com/riemann/riemann-tools/pull/4) ([mindreframer](https://github.com/mindreframer))
- added a script to report kvm instances running on a host [\#3](https://github.com/riemann/riemann-tools/pull/3) ([wjimenez5271](https://github.com/wjimenez5271))
- Add --tag option to specify tags [\#2](https://github.com/riemann/riemann-tools/pull/2) ([lwf](https://github.com/lwf))
- add freebsd and darwin support to riemann-health [\#1](https://github.com/riemann/riemann-tools/pull/1) ([joecaswell](https://github.com/joecaswell))

## [version-0.0.2](https://github.com/riemann/riemann-tools/tree/version-0.0.2) (2012-04-17)

[Full Changelog](https://github.com/riemann/riemann-tools/compare/4970399184a9dbec5f4aa247ccfde43b2b9e0dbc...version-0.0.2)



\* *This Changelog was automatically generated by [github_changelog_generator](https://github.com/github-changelog-generator/github-changelog-generator)*
