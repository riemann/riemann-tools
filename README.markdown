# Riemann Tools

Tiny programs to submit events to Riemann.

Riemann-health, for example, submits events about the current CPU, load,
memory, and disk use. Also available is `riemann-bench`, which submits
randomly distributed metrics for load testing.

[![Gem Version](https://badge.fury.io/rb/riemann-tools.svg)](https://badge.fury.io/rb/riemann-tools) [![CI](https://github.com/riemann/riemann-tools/actions/workflows/ci.yml/badge.svg)](https://github.com/riemann/riemann-tools/actions/workflows/ci.yml)

## Get started

``` bash
gem install riemann-tools
riemann-health --host my.riemann.server
```

## Riemann-tools programs

This repository contains a number of different programs. Some of them
ship with the `riemann-tools` gem, including:

* riemann-apache-status - Apache monitoring.
* riemann-dir-files-count - File counts.
* riemann-freeswitch - FreeSwitch monitoring.
* riemann-memcached - Monitor Memcache.
* riemann-proc - Linux process monitoring.
* riemann-bench - Load testing for Riemann.
* riemann-dir-space - Directory space monitoring.
* riemann-haproxy - Monitor HAProxy.
* riemann-net - Network interface monitoring.
* riemann-varnish - Monitor Varnish.
* riemann-cloudant - Cloudant monitoring.
* riemann-diskstats - Disk statistics.
* riemann-health - General CPU, memory, disk and load monitoring.
* riemann-nginx-status - Monitor Nginx.
* riemann-zookeeper - Monitor Zookeeper.
* riemann-consul - Monitor Consul.
* riemann-fd - Linux file descriptor use.
* riemann-kvminstance - Monitor KVM instances.
* riemann-ntp - Monitor NTP.
* riemann-portcheck - Monitor open TCP ports.
* riemann-http-check - Monitor reachability of HTTP(S) resources.

Also contained in the repository are a number of stand-alone monitoring
tools, which are shipped as separate gems.

## Riemann stand-alone tools

Use these tools by installing their individual gems, usually named for
the specific tool, for example, to install the AWS tools:

```bash
gem install riemann-aws
```

* riemann-aws - Monitor various AWS services.
* riemann-elasticsearch - Monitor Elasticsearch.
* riemann-mesos - Monitor Mesos.
* riemann-rabbitmq - Monitor RabbitMQ.
* riemann-docker - Monitor Docker.
* riemann-marathon - Monitor Marathon.
* riemann-munin - Monitor Munin.
* riemann-riak - Monitor Riak.
* riemann-chronos - Monitor Chronos.

There are also a number of additional, stand-alone tools, contained in
the [Riemann GitHub account](https://github.com/riemann/).

## Docker Images

You can find Docker images for the tools [here](https://hub.docker.com/u/riemannio/dashboard/).

## License

The MIT License

Copyright (c) 2011-2022 Kyle Kingsbury
