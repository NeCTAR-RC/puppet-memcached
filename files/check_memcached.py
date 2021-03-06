#! /usr/bin/env python3
'''

  2008 Kakikubo Teruo
  check_memcached.py

  Check Memcached Server plugin.
  This Plugin requires the memcached-Python API.
  This Plugin was tested only in the python 2.5

  * Wed Apr  2 20:42:56 JST 2008
  add performance data (elapsed time)

'''
import memcache
from optparse import OptionParser
import os
import sys
import signal
import time


pid = str(os.getpid())

# option
parser = OptionParser()
parser.add_option("-H", "--hostname", dest="hostaddress",
                  help="Host Address", metavar=" <hostaddr>")
parser.add_option("-t", "--timeout", dest="timeout",
                  help="timeout x seconds", metavar=" <timeout>", default=10)
parser.add_option("-p", "--port", dest="port",
                  help="port number", metavar=" <port number>", default=11211)
opts, args = parser.parse_args()

if not opts.hostaddress:
    parser.print_help()
    parser.error("UNKNOWN - Please specify Host")
    exit(2)

svr = u""
svr = str(opts.hostaddress) + ":" + str(opts.port)
mc = memcache.Client([svr], debug=0)


def handler(signum, frame):
    print("CRITICAL - timeout after " + str(opts.timeout) + " seconds")
    sys.exit(2)


signal.signal(signal.SIGALRM, handler)
signal.alarm(int(opts.timeout))
t1 = time.time()


if not mc.set(pid, "nagios value"):
    print("CRITICAL - cannot set the value")
    sys.exit(2)
else:
    if not mc.get(pid) == 'nagios value':
        print("CRITICAL - cannot get the value")
        sys.exit(2)
    else:
        mc.delete(pid)
        t2 = time.time()
        t3 = str(round((t2 - t1), 6))
        print("OK - memcached on " + str(opts.hostaddress) +
              " alive: elapsed " + t3 +
              " sec;|" + str(opts.hostaddress) +
              ":" + str(opts.port) + " time=" + t3 + "s;")
        sys.exit(0)
