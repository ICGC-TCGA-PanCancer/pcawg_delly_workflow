#!/usr/bin/env python

"""

###############################
joachim.weischenfeldt@gmail.com
1503
###############################

delly_pcawg_timing_json.py
extracts delly timing information to json file

Usage:
    delly_pcawg_timing_json.py -s <samplepair> -a <timedel> -b <timedup> -c <timeinv> -d <timetra> -e <timecovs>  -o <timing_json_out>

Options:
  -h --help     Show this screen.
  -s --samplepair  samplepair name
  -a --timedel  delly timing file
  -b --timedup  duppy timing file
  -c --timeinv  invy timing file
  -d --timetra  jumpy timing file
  -e --timecovs  cov timing dir
  -o --timing_json_out   timing output file


"""

from __future__ import print_function
from docopt import docopt
import json, sys, glob
from collections import defaultdict

arguments = docopt(__doc__)


timedel = arguments['<timedel>']
timedup = arguments['<timedup>']
timeinv = arguments['<timeinv>']
timetra = arguments['<timetra>']
timecovs = arguments['<timecovs>']
samplepair = arguments['<samplepair>']
timing_json_out = arguments['<timing_json_out>']

print (timedel, timedup, timeinv, timetra, timecovs, timing_json_out)

d = defaultdict(dict)
d['timing_metrics']['workflow'] = defaultdict(dict)
d['timing_metrics']['workflow']['pairs'] = defaultdict(dict)
d['timing_metrics']['workflow']['pairs'][samplepair] = defaultdict(dict)

for timing_file in [timedel, timedup, timeinv, timetra] + glob.glob(timecovs + '/*.time'):
	timetype = timing_file.split('/')[-1].split('.time')[0]
	print ("\n", timetype, "\n")
	d['timing_metrics']['workflow']['pairs'][samplepair][timetype] = defaultdict(dict)
	d['timing_metrics']['workflow']['pairs'][samplepair][timetype]["detailed"] = defaultdict(dict)
	d['timing_metrics']['workflow']['pairs'][samplepair][timetype]["detailed"]["group"] = list()
	print ("\n\n",timing_file, timetype)
	with open(timing_file) as lin:
		out = list()
		for f in lin:
			row = f.replace('\n', '').split(' ')
			out.append( {row[0]: float(row[1])})
	d['timing_metrics']['workflow']['pairs'][samplepair][timetype]["detailed"]["group"] = out


log_json = json.dumps(d)

with open(timing_json_out, 'w') as wout:
    wout.write(log_json)

print (timing_json_out, "written")

