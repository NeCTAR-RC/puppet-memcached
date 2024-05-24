#! /usr/bin/env python3

import sys
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


def main():
    p = optparse.OptionParser()

    p.add_option('-H', '--host', action='store', type='string',
                 dest='host', default='127.0.0.1',
                 help='The hostname you want to connect to')

    p.add_option('-P', '--port', action='store', type='int',
                 dest='port', default=11211,
                 help='The port memcached is runnung on')

    p.add_option('-W', '--warning', action='store', type='int',
                 dest='warning',
                 help='The warning threshold we want to set')

    p.add_option('-C', '--critical', action='store', type='int',
                 dest='critical',
                 help='The critical threshold we want to set')

    p.add_option('-M', '--metric', action='store', dest="metric",
                 type="string", help="Memcached metric to test for")

    (options, args) = p.parse_args()

    config = {
        'host': options.host,
        'port': options.port
    }

    metric = get_metric(config, options.metric)

    if metric is None:
        print("Metric '%s' returned nothing" % options.metric)
        sys.exit(4)

    if metric >= options.critical:
        print("ERROR: Memcached %s %d (%d)" %
              (options.metric, metric, options.critical))
        sys.exit(2)
    elif metric >= options.warning:
        print("WARNING: Memcached %s %d (%d)" %
              (options.metric, metric, options.warning))
        sys.exit(1)
    else:
        print("OK: Memcached %s %d" % (options.metric, metric))
        sys.exit(0)


if __name__ == "__main__":
    main()
