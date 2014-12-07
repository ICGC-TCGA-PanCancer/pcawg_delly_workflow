#! /usr/bin/env python


"""

###############################
joachim.weischenfeldt@gmail.com
###############################

dellyVcf2Tsv.py 
Converts delly v vcf file to BEDPE or classical delly tsv format
Adds gene annotation if gene bed file is provided

Usage:
    dellyVcf2Tsv.py -v <vcfFile> -o <output>  [(--bedpe|--delly)] [-g <genes>] [-r <regions>]

Options:
  -h --help     Show this screen.
  -v --vcfFile  DELLY v0.5+
  -o --output   tsv output file
  -b --bedpe     choose BEDPE output format (default)
  -d --delly     choose classical delly output format
  -g --genes     gene annotation in BED format (chr, start, end, name, strand)
  -r --region   genomic regions in BED format


"""


from __future__ import print_function
from docopt import docopt
import vcf
import sys
import csv
import re
import gzip
from pybedtools import BedTool
arguments = docopt(__doc__)

delly_format = ""
if arguments['--delly']:
    delly_format = True

vcfFile = arguments['<vcfFile>']

fileOut = arguments['<output>']

fileOutAnno = re.sub('\.[^.]*$','',fileOut) + '.genes.txt'


gencode = ''
if arguments['<genes>']:
    gencode_file = arguments['<genes>']
    gencode = BedTool(gencode_file)


region_file = ''
if arguments['<regions>']:
    region_file = arguments['<regions>']


def overlap(x,y,d=100000):
    regiondist = ''
    x = [int(x[0]), int(x[-1])]
    y = [int(y[0]), int(y[-1])]
    if range(max(x[0], y[0]), min(x[-1], y[-1])+1):
        regiondist = 0
    elif range(max(x[0], y[0]-d), min(x[-1], y[-1]+d)+1 ):
        regiondist = min(abs(x[-1]-y[0]), abs(y[-1]-x[0]) )
    return regiondist

def cisreg_overlap(bedpe_list, header, region_file):
    header = header + ['pos1_cisreg', 'pos2_cisreg']
    with gzip.open(region_file, 'rb') as region_in:
        region_reader = csv.reader(region_in, delimiter="\t")
        region_list = list(region_reader)
    bedpe_list3 = list()
    bedpe_list3.append(header)
    for b in bedpe_list:
        pos1_region = list()
        pos2_region = list()
        for r in region_list:
            if r[0] == b[0]:
                regiondist = overlap(b[1:3], r[1:3])
                if regiondist:
                    pos1_region.append([r[5] + ",score="+r[4] + ",dist=" + str(regiondist)])
            if r[0] == b[3]:
                regiondist = overlap(b[4:6], r[1:3])
                if regiondist:
                    pos2_region.append([r[5] + ",score="+r[4] + ",dist=" + str(regiondist)])
        if pos1_region:
            pos1_out = [';'.join(map(str,[i for (i,) in pos1_region]))]
        else:
            pos1_out = ['.']
        if pos2_region:
            pos2_out = [';'.join(map(str,[i for (i,) in pos2_region]))]
        else:
            pos2_out = ['.']                
        bedpe_list3.append(b + pos1_out + pos2_out)

    return bedpe_list3




bedpe_list = list()
with open(fileOut, 'wb') as w:
    csv_writer = csv.writer(w, delimiter="\t", lineterminator="\n")
    vcf_reader=vcf.Reader(open(vcfFile), 'r', compressed=True) if vcfFile.endswith('.gz') else vcf.Reader(open(vcfFile), 'r', compressed=False)
    if not delly_format:
        header = ['chrom1', 'start1', 'end1', 'chrom2', 'start2', 'end2', 'id', 'pairs', 'strand1', 'strand2', 'svtype', 'size', 'orient', 'mapq', 'split_reads', 'split_mapq', 'split_consensus',  'pid', 'af', 'genotypes', 'rd_ratio', 'tumor_count', 'germ_count']
        csv_writer.writerow(header)
    for record in vcf_reader:
        out = []
        samples = [call.sample for call in record.samples]
        samples_base = [re.sub(r'((.*))_[0-9]{6}_.*sequence.*', '\\1', x) for x in samples]
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
            csv_writer.writerow(out)
      # BEDPE Format:
        else:
            alt_AF = list()
            for call in record.samples:
                try:
                    alt_AF.append(round(float(call['DV'])/float(call['DV']+call['DR']),3))
                except Exception, e:
                    alt_AF.append(0)
            alt_AF = ';'.join(map(str, alt_AF))
            try:
                rdRatio = record.INFO['RDRATIO']
            except Exception, e:
                rdRatio = "."
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
            germ_count = "."
            tum_count = "."                
            if [k for k in  record.INFO.keys() if 'SC_' in k]:
                try:
                    germ_count = 0
                    tum_count = 0
                    controls = [i for i in record.INFO.keys() if 'SC_' in i and 'control_C' in i]
                    tumors = [i for i in record.INFO.keys() if 'SC_' in i and 'tumor_C' in i]
                    germ_count = int(sum([record.INFO[c] for c in controls]))
                    tum_count = int(sum([record.INFO[t] for t in tumors]))
                except Exception, e:
                    pass
            out = [record.CHROM.replace('.fa', ''), record.POS, int(record.POS)+1, record.INFO['CHR2'].replace('.fa', ''), \
            record.INFO['END'], int(record.INFO['END'])+1, record.ID, record.INFO['PE'], strand_1, strand_2, record.INFO['SVTYPE'], \
            record.INFO['SVLEN'], record.INFO['CT'],  record.INFO['MAPQ'], split, splitmapq, consensus, pid, alt_AF,  genotypes, rdRatio, tum_count, germ_count]
            bedpe_list.append(out)
            csv_writer.writerow(out)

print ("\n\nFile(s) generated:\n\t", fileOut)


def chrom_format(gencode):
	return BedTool([list(j.replace('chr', '') for j in i) for i in gencode])



### ANNOTATE #####

if not delly_format and gencode and len(bedpe_list) > 0:
    bedpe_bed = BedTool(bedpe_list)
    if not 'chr' in bedpe_list[0][0]:
        gencode = chrom_format(gencode)
    bedpe_gencode = bedpe_bed.closest(gencode, d=True)
    bedpe_bed2 = BedTool([i[3:6] + i[:] for i in bedpe_gencode[:]])
    del(bedpe_gencode)
    bedpe_gencode = bedpe_bed2.closest(gencode, d=True)
    bedpe_list2 = [i[3:] for i in bedpe_gencode[:]]
    bedpe_header = header + ['chrom_gene1', 'start_gene1', 'end_gene1', 'name_gene1', 'strand_gene1', 'dist_gene1', 'chrom_gene2', 'start_gene2', 'end_gene2', 'name_gene2', 'strand_gene2', 'dist_gene2','fusion_gene']
    with open(fileOutAnno, 'wb') as wout:
        bedpe_writer = csv.writer(wout, delimiter="\t")
        max_distance = 50000
        gene_list = list()
        for r in bedpe_list2:
            fusion = '.'
            gene1 = r[26]
            gene2 = r[32]
            strand1 = r[8]
            strand2 = r[9]
            strandGene1 = r[27]
            strandGene2 = r[33]
            distGene1 = int(r[28])
            distGene2 = int(r[34])
            if gene1 != gene2 and distGene1 + distGene2 < max_distance:
                if strand1 == '+' and strand2 == '+':
                    if strandGene1 == '+' and strandGene2 == '+':
                        fusion = gene1 + ':' + gene2
                    elif strandGene1 == '-' and strandGene2 == '-':
                        fusion = gene2 + ':' + gene1
                elif strand1 == '+' and strand2 == '-':
                    if strandGene1 == '+' and strandGene2 == '-':
                        fusion = gene1 + ':' + gene2
                    elif strandGene1 == '-' and strandGene2 == '+':
                        fusion = gene2 + ':' + gene1
                elif strand1 == '-' and strand2 == '+':
                    if strandGene1 == '-' and strandGene2 == '+':
                        fusion = gene1 + ':' + gene2
                    elif strandGene1 == '+' and strandGene2 == '-':
                        fusion = gene2 + ':' + gene1
                elif strand1 == '-' and strand2 == '-':
                    if strandGene1 == '-' and strandGene2 == '-':
                        fusion = gene1 + ':' + gene2
                    elif strandGene1 == '+' and strandGene2 == '+':
                        fusion = gene2 + ':' + gene1
            gene_list.append(r + [fusion])
        gene_list.sort(key = lambda x: (x[0], int(x[1])) )
        if region_file:
            out = cisreg_overlap(gene_list, bedpe_header, region_file)
        else:
            out = [bedpe_header] + gene_list

        bedpe_writer.writerows(out)


    print ("\nAnnotation file\n\t", fileOutAnno)

