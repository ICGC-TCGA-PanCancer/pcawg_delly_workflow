#! /usr/bin/env python


"""

###############################
joachim.weischenfeldt@gmail.com
###############################

dellyVcf2Tsv.py 
Converts delly v vcf file to BEDPE or classical delly tsv format

Usage:
    dellyVcf2Tsv.py -v <vcfFile> -o <output>  [(--bedpe|--delly)]

Options:
  -h --help     Show this screen.
  -v --vcfFile  DELLY v0.5+
  -o --output   tsv output file
  -b --bedpe     choose BEDPE output format (default)
  -d --delly     choose classical delly output format


"""


from __future__ import print_function
import sys,os
sys.path.append(os.path.join(os.path.dirname(__file__), "py"))
from docopt import docopt
import vcf
import csv
import re

arguments = docopt(__doc__)

delly_format = ""
if arguments['--delly']:
    delly_format = True

vcfFile = arguments['<vcfFile>']

fileOut = arguments['<output>']

with open(fileOut, 'wb') as w:
    csv_writer = csv.writer(w, delimiter="\t")
    vcf_reader = vcf.Reader(open(vcfFile, 'r'))
    if not delly_format:
      header = ['chrom1', 'start1', 'end1', 'chrom2', 'start2', 'end2', 'id', 'pairs', 'strand1', 'strand2', 'svtype', 'size', 'orient', 'mapq', 'split_reads', 'split_mapq', 'split_consensus',  'pid', 'heterozygosity', 'genotypes']
      csv_writer.writerow(header)
    for record in vcf_reader:
        out = []
        samples = [call.sample for call in record.samples]
        samples_base = [re.sub(r'((.*))_[0-9]{6}_.*sequence', '\\1', x) for x in samples]
        pid = '_vs_'.join(map(str, samples_base))
        vcf_id = pid + '_' + record.ID
        strand_1, strand_2 = record.INFO['CT'].replace('3to', '+to').replace('5to', '-to').replace('to3', 'to-').replace('to5', 'to+').split('to')
        svTypeConvert = record.INFO['SVTYPE'].replace('DEL', 'Deletion').replace('DUP', 'Duplication').replace('INV', 'Inversion').replace('TRA', 'Translocation')
	# DELLY Format:
	if delly_format:
          if record.INFO['SVTYPE'] != "TRA":
            out = [record.CHROM, record.POS, record.INFO['END'], record.INFO['SVLEN'], record.INFO['PE'], record.INFO['MAPQ'], '>' + svTypeConvert + '_' + record.INFO['CT'] + '_' + vcf_id + '<']
          else:
            out = [record.CHROM, record.POS, record.INFO['CHR2'], record.INFO['END'],  record.INFO['PE'], record.INFO['MAPQ'], '>' + svTypeConvert + '_' + record.INFO['CT'] + '_' + vcf_id + '<']
	# BEDPE Format:
	else:
          try:
            het = record.heterozygosity
          except Exception, e:
            het = "0"
          try:
            genotypes = ';'.join(map(str,[record.genotype(sample).data.GT for sample in samples]))
          except Exception, e:
            genotypes = '.;.'
          try:
            split = record.INFO['SR']
            splitmapq = record.INFO['SRQ']
            consensus = record.INFO['CONSENSUS']
          except KeyError:
            split = "0"
            splitmapq = "."
            consensus = "."
          out = [record.CHROM, record.POS, int(record.POS)+1, record.INFO['CHR2'], record.INFO['END'], int(record.INFO['END'])+1, record.ID, record.INFO['PE'], strand_1, strand_2, record.INFO['SVTYPE'], record.INFO['SVLEN'], record.INFO['CT'],  record.INFO['MAPQ'], split, splitmapq, consensus, pid, het, genotypes]
        csv_writer.writerow(out)
