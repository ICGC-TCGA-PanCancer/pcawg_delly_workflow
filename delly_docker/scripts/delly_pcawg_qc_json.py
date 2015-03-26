#!/usr/bin/env python

"""

###############################
joachim.weischenfeldt@gmail.com
1503
###############################

delly_pcawg_qc_json.py
extracts delly qc information to json file

Usage:
    delly_pcawg_qc_json.py -s <samplepair> -a <qc_del> -b <qc_dup> -c <qc_inv> -d <qc_tra> -e <qc_cov>  -o <qc_json_out>

Options:
  -h --help     Show this screen.
  -s --samplepair  samplepair name
  -a --qc_del  delly qc file
  -b --qc_dup  duppy qc file
  -c --qc_inv  invy qc file
  -d --qc_tra  jumpy qc file
  -e --qc_cov  cov qc dir
  -o --qc_json_out   qc output file


"""

from __future__ import print_function
from docopt import docopt
import json, sys, glob, re
from collections import defaultdict

arguments = docopt(__doc__)


qc_del = arguments['<qc_del>']
qc_dup = arguments['<qc_dup>']
qc_inv = arguments['<qc_inv>']
qc_tra = arguments['<qc_tra>']
qc_cov = arguments['<qc_cov>']
samplepair = arguments['<samplepair>']
qc_json_out = arguments['<qc_json_out>']

print (qc_del, qc_dup, qc_inv, qc_tra, qc_cov, qc_json_out)


d = defaultdict(dict)
d['qc_metrics']['workflow'] = defaultdict(dict)
d['qc_metrics']['workflow']['pairs'] = defaultdict(dict)
d['qc_metrics']['workflow']['pairs'][samplepair] = defaultdict(dict)

for qc_file in glob.glob(qc_del + '/*.log') + glob.glob(qc_dup + '/*.log') + glob.glob(qc_inv + '/*.log') + glob.glob(qc_tra + '/*log') + glob.glob(qc_cov + '/*.log'):
	qc_type = qc_file.split('/')[-1].split('.log')[0]
	print ("\n", qc_type, "\n")
	d['qc_metrics']['workflow']['pairs'][samplepair][qc_type] = defaultdict(dict)
	print ("\n\n",qc_file, qc_type)
	with open(qc_file) as lin:
		out = list()
		for f in lin:
			row = f.replace('\n', '').split(' ')
			print (row)
			if row[0] == 'Sample:':
				sampleName = row[1]
				d['qc_metrics']['workflow']['pairs'][samplepair][qc_type][sampleName] = defaultdict(dict)
			if 'RG:' in row[0]:
				rg_id = re.sub(r'ID=([^,]*).*', r'\1', row[1])
				print (rg_id)
				d['qc_metrics']['workflow']['pairs'][samplepair][qc_type][sampleName]['readgroup'] = defaultdict(dict)
				d['qc_metrics']['workflow']['pairs'][samplepair][qc_type][sampleName]['readgroup'][rg_id] = defaultdict(dict)
				splitrow = row[1:][0].split(',')
				rg_metrics = {j.split('=')[0] : j.split('=')[1] for j in splitrow if not 'ID' in j}
				print ('rg', rg_metrics, d)
				d['qc_metrics']['workflow']['pairs'][samplepair][qc_type][sampleName]['readgroup'][rg_id] = rg_metrics


log_json = json.dumps(d)

with open(qc_json_out, 'w') as wout:
    wout.write(log_json)

print (qc_json_out, "written")
