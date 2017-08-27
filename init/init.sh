#!/usr/bin/dumb-init /bin/sh

service carbon-cache start
service carbon-relay start
service graphite-api start
/opt/riemann/bin/riemann /opt/riemann/etc/riemann.config
