#! /usr/bin/env python
# DellySomaticFreqFilter.py
from __future__ import print_function
import sys,os
sys.path.append(os.path.join(os.path.dirname(__file__), "py"))
import argparse
import numpy
import re
import collections
import copy
import vcf
import gzip


def overlapValid(s1, e1, s2, e2, reciprocalOverlap=0.8, maxOffset=250):
    if (e1 < s2) or (s1 > e2):
        return False
    overlapLen = float(min(e1, e2) - max(s1, s2))
    lenA=float(e1-s1)
    lenB=float(e2-s2)
    if (overlapLen<0):
        sys.exit("Sites are not overlapping.")
    if (lenA<=0) or (lenB<=0):
        sys.exit("Invalid intervals.")
    # Check reciprocal overlap
    if (overlapLen/max(lenA,lenB))<reciprocalOverlap:
        return False
    # Check offset
    if max(abs(s2-s1), abs(e2-e1))>maxOffset:
        return False
    return True

# def projectSpec(vcfInfo, tumorType, tumorTypeCtrlFrq,tumorTypeTumFrq, max1kGP=0.05):
#     projectOnly=False
#     scList = [sc for sc in vcfInfo if 'SC' in sc]
#     if (vcfInfo['SC_1KGP_F'] <= max1kGP \
#     or (vcfInfo['SC_1KGP_F'] <= max1kGP*2 \
#     and vcfInfo['SC_1KGP_C']<=2)) \
#     and (vcfInfo.get(tumorTypeCtrlFrq) >0 \
#     or vcfInfo.get(tumorTypeTumFrq) >0):
#         projectOnly=True
#         for k in scList:
#             if not tumorType in k \
#             and k.endswith('F') and int(record.INFO.get(k)) > 0:
#                     projectOnly = False
#                     break
#     return projectOnly


def germSpecFilter(vcfInfo, tumorType, tumorTypeCtrlFrq,tumorTypeTumFrq,max1kGP=0.05):
    germOnly=False
    scList = [sc for sc in vcfInfo if 'SC' in sc]
    sampleSet = set([re.sub('SC_(([^_]*))_[a-z]*_[CF]','\\1',k) for k in scList if 'tumor' in k or 'control' in k])
    if (vcfInfo['SC_1KGP_F'] <= max1kGP \
    or (vcfInfo['SC_1KGP_F'] <= max1kGP*2 \
    and vcfInfo['SC_1KGP_C']<=2)) \
    and vcfInfo.get(tumorTypeCtrlFrq) >0 \
    and vcfInfo.get(tumorTypeCtrlFrq) >= vcfInfo.get(tumorTypeTumFrq):
        germOnly=True
        for k in sampleSet:
            s = [i for i in scList if k in i and i.endswith('F')]
            if len(s) > 1 and vcfInfo.get(s[0]) > vcfInfo.get(s[1]):
                germOnly=False
                break
    return germOnly

def tumSpecFilter(vcfInfo, tumorType, tumorTypeCtrlFrq,tumorTypeTumFrq, maxCtrl=0.05, max1kGP=0.05):
    tumOnly=False
    scList = [sc for sc in vcfInfo if 'SC' in sc]
    if ( float(vcfInfo['SC_1KGP_F']) <= max1kGP \
    or ( float(vcfInfo['SC_1KGP_F']) <= max1kGP*2 \
    and int(vcfInfo['SC_1KGP_C'] )<= 5)) \
    and float(vcfInfo[tumorTypeTumFrq]) > 0:
        for k in scList:
            if k.endswith('control_F') and float(vcfInfo.get(k)) > maxCtrl:
                tumOnly=False
                break
            else:
                tumOnly=True
    return tumOnly

def RefGeno(call, rcRef):
    if (call.gt_type == 0):
        if ((not precise) and (call['DV'] == 0)) or ((precise) and (call['RV']==0)):
            rcRef.append(call['RC'])
    return rcRef


def AltGeno(call, rcAlt):
    if (call.gt_type != 0):
        if ((not precise) and (call['DV'] >= suppPairs) \
        and (float(call['DV'])/float(call['DV']+call['DR'])>=altAF)) \
        or ((precise) and (call['RV'] >= suppPairs) \
        and (float(call['RV'])/float(call['RR'] + call['RV'])>=altAF)):
            rcAlt.append(call['RC'])
    return rcAlt




# Parse command line
parser = argparse.ArgumentParser(description='Filter for somatic SVs.')
parser.add_argument('-v', '--vcf', metavar='variants.vcf', required=True, dest='vcfFile', help='input vcf file (required)')
#parser.add_argument('-t', '--type', metavar='DEL', required=True, dest='svType', help='SV type [DEL, DUP, INV, INS] (required)')
parser.add_argument('-o', '--out', metavar='out.vcf', required=False, dest='outFile', help='output vcf file. Default suffix ".highConf.vcf" (optional)')
parser.add_argument('-s', '--sample', metavar='PRAD', required=False, dest='tumorType', help='tumor sample type [PRAD, BLCA, MB...] (default PRAD)')
parser.add_argument('-a', '--altaf', metavar='0.25', required=False, dest='altAF', help='min. alt. AF (default 0)')
parser.add_argument('-m', '--minsize', metavar='100', required=False, dest='minSize', help='min. size (default 100)')
parser.add_argument('-n', '--maxsize', metavar='500000000', required=False, dest='maxSize', help='max. size (optional)')
parser.add_argument('-p', '--tumorpairs', metavar='2', required=False, dest='suppPairs', help='min number of supporing pairs in tumor for high confident filter (default 4)')
parser.add_argument('-f', '--filter', dest='siteFilter', action='store_true', help='Filter sites for PASS')
args = parser.parse_args()

# Command-line args
max1kGP=0.01
maxCtrl=0
minSize = 100 ## change 
if args.minSize:
    minSize = int(args.minSize)
maxSize = 500000000
if args.maxSize:
    maxSize = int(args.maxSize)
altAF = 0
if args.altAF:
    altAF = float(args.altAF)
suppPairsHiQ = 4
if args.suppPairs:
    suppPairsHiQ = int(args.suppPairs)
tumorType = 'PRAD'
if args.tumorType:
    tumorType = args.tumorType

vcfFile = args.vcfFile
siteFilter = args.siteFilter
#svType = args.svType
outFile = vcfFile.split('.vcf')[0] + '.somatic.vcf'
if args.outFile:
    outFile = args.outFile
outFileSomaticConf = outFile.split('.vcf')[0] + '.highConf.vcf'
outFileGerm = outFile.replace('.somatic', '').split('.vcf')[0] + '.germline.vcf'
outFileGermConf = outFile.replace('.somatic', '').split('.vcf')[0] + '.germline.highConf.vcf'



# Collect high-quality SVs
sv = dict()
svDups = collections.defaultdict(list)
validRecordID = set()
validGermRecordID = set()
if vcfFile:
    vcf_reader = vcf.Reader(open(vcfFile), 'r', compressed=True) if vcfFile.endswith('.gz') else vcf.Reader(open(vcfFile), 'r', compressed=False)
    for record in vcf_reader:
        vcfInfo = record.INFO
        suppPairs = 2
        svType = re.sub(r'[0-9]*','',record.ID) 
        listOfSamples = ', '.join(map(str, list(set([re.sub('SC_((.*))_[a-z]*_[CF]', '\\1', sc) for sc in record.INFO if 'SC_' in sc and '1KGP' not in sc]))))
        if [sc for sc in record.INFO if tumorType in sc]:
            tumorTypeCtrlFrq = 'SC_' + tumorType + '_control_F'
            tumorTypeCtrlCount = 'SC_' + tumorType + '_control_C'
            tumorTypeTumFrq = 'SC_' + tumorType + '_tumor_F'
            tumorTypeTumCount = 'SC_' + tumorType + '_tumor_C'
            popFilter = True
        elif listOfSamples and tumorType:
            print (tumorType, "not present in INFO field. please skip tumorRype or use one of these tumor samples [-s]: {0}\n\nExiting".format(listOfSamples))
            sys.exit(-1)
        else:
            popFilter = False
        if ((record.INFO['SVLEN'] >= minSize) and (record.INFO['SVLEN'] <= maxSize) or (record.INFO['SVTYPE'] == 'TRA'))  and ((not siteFilter) or (len(record.FILTER) == 0)):
            precise = False
            if ('PRECISE' in record.INFO.keys()):
                precise = record.INFO['PRECISE']
            rcRef = []
            rcAlt = []
            rcGermAlt = []
            genoRef = []
            genoAlt = []
            callTum = ''
            rdRatio = 1
            isTumSpec = False
            isGermSpec = False
            for e, call in enumerate(record.samples):
                if (call.called):
                    if (re.search(r"[Nn]ormal|_N0[0-9]_|_DNA_B_", call.sample) != None):
                        genoRef = call['GT']
                        rcRef = RefGeno(call, rcRef)
                        rcGermAlt = AltGeno(call, rcGermAlt)
                    elif (re.search(r"[Tt]umor|_DNA_T_|_T0[0-9]_|_Tx_", call.sample) != None):
                        genoAlt = call['GT']
                        rcAlt = AltGeno(call, rcAlt)
                        callTum = call
                    elif len(record.samples) == 2: # If no 'tumor' or 'normal' in samples, assume that the first is tumor and the second is normal!!!
                        if (e == 0):
                            genoAlt = call['GT']
                            rcAlt = AltGeno(call, rcAlt)
                            callTum = call
                        if (e == 1):
                            genoRef = call['GT']
                            rcRef = RefGeno(call, rcRef)                            
                            rcGermAlt = AltGeno(call, rcGermAlt) # get germline specific calls
                    elif len(record.samples) == 1: # If only one sample, assume that the sample is tumor
                        genoAlt = call['GT']
                        rcAlt = AltGeno(call, rcAlt)
                        rcRef = rcAlt
                        callTum = call
            if (len(rcRef) > 0) and (len(rcAlt) > 0):
                rdRatio = 1
                if numpy.median(rcRef):
                    rdRatio = numpy.median(rcAlt)/numpy.median(rcRef)
                    if rdRatio > 4:
                        suppPairs = suppPairs + suppPairs * int(rdRatio/4.0)
                isTumSpec = True
            elif (len(rcGermAlt) > 0) and (len(rcAlt) > 0) and genoRef == genoAlt:
                isGermSpec = True
            else:
                continue
            # Filtering: If DEL or DUP: Smaller than 10kb OR RD<0.85 OR RD>1.15 OR supporting pairs +1
            if (isTumSpec or isGermSpec) and ((callTum['RV']>0 and record.INFO['SVLEN'] >= minSize) or ( record.INFO['SVLEN'] >= 500 or record.INFO['SVLEN'] == 0)) and (callTum['RV'] + callTum['DV'] >= suppPairs) and ((svType == 'INV') or (svType == 'INS') or (record.INFO['SVLEN'] <= 10000) \
            or (callTum['RV'] + callTum['DV'] >= suppPairs+1) or ((svType == 'DEL') and (rdRatio <= 0.85)) or ((svType == 'DUP') and (rdRatio >= 1.15))):
                if isGermSpec:
                    validGermRecordID.add(record.ID)
                elif isTumSpec:
                    if popFilter:
                        if tumSpecFilter(vcfInfo, tumorType, tumorTypeCtrlFrq,tumorTypeTumFrq, maxCtrl, max1kGP):
                            validRecordID.add(record.ID)
                        else:
                            next
                    else:
                        validRecordID.add(record.ID)
                if not sv.has_key( (record.CHROM,record.INFO['CHR2']) ):
                    sv[(record.CHROM,record.INFO['CHR2'])] = dict()
                if (record.POS, record.INFO['END']) in sv[(record.CHROM,record.INFO['CHR2'])]:
                    svDups[(record.CHROM, record.INFO['CHR2'], record.POS, record.INFO['END'])].append((record.ID, record.INFO['PE']))
                else:
                    sv[(record.CHROM,record.INFO['CHR2'])][(record.POS, record.INFO['END'])] = (record.ID, record.INFO['PE'])

# Output vcf records
if vcfFile:
    vcf_reader=vcf.Reader(open(vcfFile), 'r', compressed=True) if vcfFile.endswith('.gz') else vcf.Reader(open(vcfFile), 'r', compressed=False)
    vcf_reader.infos['SOMATIC'] = vcf.parser._Info('SOMATIC', 0, 'Flag', 'Somatic structural variant.')
    vcf_reader.infos['GERMLINE'] = vcf.parser._Info('GERMLINE', 0, 'Flag', 'Germline structural variant.')
    vcf_writer = vcf.Writer(open(outFile, 'w'), vcf_reader, lineterminator='\n')
    vcfConf_writer = vcf.Writer(open(outFileSomaticConf, 'w'), vcf_reader, lineterminator='\n')
    vcf_Germwriter = vcf.Writer(open(outFileGerm, 'w'), vcf_reader, lineterminator='\n')    
    vcfConf_Germwriter = vcf.Writer(open(outFileGermConf, 'w'), vcf_reader, lineterminator='\n')
    for record in vcf_reader:
        # Is it a valid SV?
        if (record.ID not in validGermRecordID and record.ID not in validRecordID):
            continue
        # Collect overlapping and identical calls
        overlapCalls = list()
        for cSvID, cScore in svDups[(record.CHROM, record.INFO['CHR2'], record.POS, record.INFO['END'])]:
            if (record.ID != cSvID):
                overlapCalls.append((cSvID, cScore))
        startIntersect = list(set( sv[(record.CHROM,record.INFO['CHR2'])].keys()).intersection(set([record.POS, record.INFO['END']])))
        if startIntersect:
            for cStart, cEnd in startIntersect[0]:
                cSvID, cScore = sv[(record.CHROM,record.INFO['CHR2'])][(cStart, cEnd)]
                if (record.ID != cSvID) and (overlapValid(record.POS, record.INFO['END'], cStart, cEnd)):
                    overlapCalls.append((cSvID, cScore))
         # Judge wether overlapping calls are better
        foundBetterHit = False
        for cSvID, cScore in overlapCalls:
            if (cScore > record.INFO['PE']) or ((cScore == record.INFO['PE']) and (cSvID < record.ID)):
                foundBetterHit = True
                break
        if not foundBetterHit:
            if record.ID in validRecordID:
                record.INFO['SOMATIC'] = True
                vcf_writer.write_record(record)
                if int(record.INFO['MAPQ']) >= 20 and int(record.INFO['PE']>=suppPairsHiQ) and not record.FILTER:
                    vcfConf_writer.write_record(record)
            if record.ID in validGermRecordID:
                record.INFO['GERMLINE'] = True
                vcf_Germwriter.write_record(record)
                if int(record.INFO['MAPQ']) >= 20 and int(record.INFO['PE']>=suppPairsHiQ) and not record.FILTER:
                    vcfConf_Germwriter.write_record(record)


print ("\nGenerated filter files:\n@SOMATIC\n\t{0}\n\t{1}\n@GERMLINE\n\t{2}\n\t{3}".format(outFile,outFileSomaticConf, outFileGerm, outFileGermConf))
