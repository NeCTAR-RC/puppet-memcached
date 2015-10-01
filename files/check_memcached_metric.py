#! /usr/bin/python

import sys
import os
import time
import optparse

import telnetlib


client = telnetlib.Telnet()

def cast(value):
    """Cast value to float or int, if possible"""
    try:
        return float(value) if '.' in value else int(value)
    except ValueError:
        return value


def query(command):
    """Send `command` to memcached and stream response"""
    client.write(command.encode('ascii') + b'\n')
    while True:
        line = client.read_until(b'\r\n').decode('ascii').strip()
        if not line or line == 'END':
            break
        (_, metric, value) = line.split(None, 2)
        yield metric, cast(value)


def get_metric(config, metric):
    m = None
    try:
        client.open(**config)
        stats = query('stats')
        for i in stats:
            if i[0] == metric:
                return i[1]
    finally:
        client.close()
    return m


def main(argv):
    p = optparse.OptionParser()

    p.add_option('-H', '--host', action='store', type='string',
                 dest='host', default='127.0.0.1',
                 help='The hostname you want to connect to')

    p.add_option('-P', '--port', action='store', type='int',
                 dest='port', default=11211,
                 help='The port mongodb is runnung on')

    p.add_option('-W', '--warning', action='store', type='int',
                 dest='warning', default=80, 
                 help='The warning threshold we want to set')

    p.add_option('-C', '--critical', action='store', type='int',
                 dest='critical', default=90,
                 help='The critical threshold we want to set')

    p.add_option('-M', '--metric', action='store', dest="metric",
                 type="string", help="Memcached metric to test for")

    p.add_option('-V', '--value', action='store', dest="value",
                 type="int", help="Value")

    (options, args) = p.parse_args()

    config = {
        'host': options.host,
        'port': options.port
    }

    metric = get_metric(config, options.metric)

    if not metric:
        print("Metric '%s' returned nothing" % options.metric)
        sys.exit(4)

    try:
        pc = metric/float(options.value) * 100
    except Exception as e:
        print("Value error: %s" % e)
        sys.exit(4)

    if pc > options.critical:
        print("ERROR: Memcached %s %d over %d%% (%s)" % 
              (options.metric, metric, options.critical, options.value))
        sys.exit(2)
    elif pc > options.warning:
        print("WARNING: Memcached %s %d over %d%% (%s)" %
              (options.metric, metric, options.warning, options.value))
        sys.exit(1)
    elif pc > 0 and pc <= options.warning:
        print("OK: Memcached %s %d" % (options.metric, metric))
        sys.exit(0)
    else:
        print("WARNING: Memcache unknown value error: %d" % metric)
        sys.exit(1)

if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
