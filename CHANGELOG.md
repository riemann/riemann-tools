# Change Log

## [Unreleased](https://github.com/riemann/riemann-tools/tree/HEAD)

[Full Changelog](https://github.com/riemann/riemann-tools/compare/0.2.7...HEAD)

**Closed issues:**

- problem sending tags [\#135](https://github.com/riemann/riemann-tools/issues/135)
- riemann-docker-health [\#119](https://github.com/riemann/riemann-tools/issues/119)
- Split repository [\#61](https://github.com/riemann/riemann-tools/issues/61)

**Merged pull requests:**

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

## [0.2.7](https://github.com/riemann/riemann-tools/tree/0.2.7) (2015-07-17)
[Full Changelog](https://github.com/riemann/riemann-tools/compare/0.2.6...0.2.7)

**Merged pull requests:**

- riemann-freeswitch sends number of threads used by Freeswitch [\#118](https://github.com/riemann/riemann-tools/pull/118) ([krakatoa](https://github.com/krakatoa))
- Change the way `ioreqs` metric is handled [\#117](https://github.com/riemann/riemann-tools/pull/117) ([pariviere](https://github.com/pariviere))
- add option to specify a proxied path prefix [\#115](https://github.com/riemann/riemann-tools/pull/115) ([peterneubauer](https://github.com/peterneubauer))

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

## [0.2.2](https://github.com/riemann/riemann-tools/tree/0.2.2) (2014-06-30)
[Full Changelog](https://github.com/riemann/riemann-tools/compare/0.2.1...0.2.2)

**Closed issues:**

- Elasticsearch tool gives error NoMethodError undefined method `URI' [\#84](https://github.com/riemann/riemann-tools/issues/84)

## [0.2.1](https://github.com/riemann/riemann-tools/tree/0.2.1) (2014-03-26)
[Full Changelog](https://github.com/riemann/riemann-tools/compare/0.2.0...0.2.1)

## [0.2.0](https://github.com/riemann/riemann-tools/tree/0.2.0) (2014-01-23)
[Full Changelog](https://github.com/riemann/riemann-tools/compare/0.1.9...0.2.0)

**Closed issues:**

- riemann-net stopped working with beefcake version 0.4.0 [\#70](https://github.com/riemann/riemann-tools/issues/70)
- riemann-riak fails to detect if riak is down [\#54](https://github.com/riemann/riemann-tools/issues/54)

## [0.1.9](https://github.com/riemann/riemann-tools/tree/0.1.9) (2013-12-10)
[Full Changelog](https://github.com/riemann/riemann-tools/compare/0.1.8...0.1.9)

## [0.1.8](https://github.com/riemann/riemann-tools/tree/0.1.8) (2013-11-11)
[Full Changelog](https://github.com/riemann/riemann-tools/compare/0.1.6...0.1.8)

## [0.1.6](https://github.com/riemann/riemann-tools/tree/0.1.6) (2013-11-11)
[Full Changelog](https://github.com/riemann/riemann-tools/compare/0.1.7...0.1.6)

**Closed issues:**

- riemann-redis run\_id can be infinity [\#65](https://github.com/riemann/riemann-tools/issues/65)
- License missing from gemspec [\#64](https://github.com/riemann/riemann-tools/issues/64)
- riemann-health EMSGSIZE Message too long - sendto\(2\) on OSX [\#16](https://github.com/riemann/riemann-tools/issues/16)
- add riemann-cloudwatch [\#9](https://github.com/riemann/riemann-tools/issues/9)

## [0.1.7](https://github.com/riemann/riemann-tools/tree/0.1.7) (2013-10-18)
[Full Changelog](https://github.com/riemann/riemann-tools/compare/0.1.5...0.1.7)

**Closed issues:**

- riemann-riak error when adding tag [\#62](https://github.com/riemann/riemann-tools/issues/62)

## [0.1.5](https://github.com/riemann/riemann-tools/tree/0.1.5) (2013-10-15)
[Full Changelog](https://github.com/riemann/riemann-tools/compare/0.1.3...0.1.5)

**Closed issues:**

- Ripe new release? [\#59](https://github.com/riemann/riemann-tools/issues/59)

## [0.1.3](https://github.com/riemann/riemann-tools/tree/0.1.3) (2013-05-28)
[Full Changelog](https://github.com/riemann/riemann-tools/compare/0.1.2...0.1.3)

**Closed issues:**

- riemann-kvminstance\(s\) duplicate scripts [\#34](https://github.com/riemann/riemann-tools/issues/34)

## [0.1.2](https://github.com/riemann/riemann-tools/tree/0.1.2) (2013-04-30)
[Full Changelog](https://github.com/riemann/riemann-tools/compare/0.0.9...0.1.2)

**Closed issues:**

- riemann-nginx? [\#31](https://github.com/riemann/riemann-tools/issues/31)
- Commit \#7de2572ccace567d90e555415498c2325bb8d87f seems to have borked how the hostname get's sent [\#22](https://github.com/riemann/riemann-tools/issues/22)

## [0.0.9](https://github.com/riemann/riemann-tools/tree/0.0.9) (2012-12-08)
[Full Changelog](https://github.com/riemann/riemann-tools/compare/version-0.0.2...0.0.9)

## [version-0.0.2](https://github.com/riemann/riemann-tools/tree/version-0.0.2) (2012-04-17)


\* *This Change Log was automatically generated by [github_changelog_generator](https://github.com/skywinder/Github-Changelog-Generator)*