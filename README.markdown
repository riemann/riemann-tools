Reimann Tools
=============

Tiny programs to submit events to Reimann.

Reimann-health, for example, submits events about the current CPU, load,
memory, and disk use. Bench submits randomly distributed metrics for load
testing. I've got a whole bunch of these internally for monitoring Redis, Riak,
queues, etc. Most have internal configuration dependencies, so it'll be a while
before I can extract them for re-use.

Get started
==========

``` bash
gem install reimann-tools
reimann-health --host my.reimann.server
```
