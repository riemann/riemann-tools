Riemann Tools
=============

Tiny programs to submit events to Riemann.

Riemann-health, for example, submits events about the current CPU, load,
memory, and disk use. Bench submits randomly distributed metrics for load
testing. I've got a whole bunch of these internally for monitoring Redis, Riak,
queues, etc. Most have internal configuration dependencies, so it'll be a while
before I can extract them for re-use.

Get started
==========

``` bash
gem install riemann-tools
riemann-health --host my.riemann.server
```
