#!/bin/sh

# $META.sv.vcf.gz
# $META.sv.vcf.gz.tbi
# META = Sample ID + Workflow + Date + Type

DIR=$(cd $(dirname "$0"); pwd)
export PATH=$PATH:$DIR

DELLY2BED=$1
RESULTSDIR_ROOT=$2
FILENAME_DELLY=$3
DEL=$4
DUP=$5
INV=$6
TRA=$7
FILENAME_COV=$8
COVDIR=$9


DELLY_COMBI=${RESULTSDIR_ROOT}/${FILENAME_DELLY}
## Combine VCF
$DIR/vcfcombine ${DEL} ${DUP} ${INV} ${TRA} | grep -vP '^hs37d5|^GL0' | $DIR/vcf-sort | bgzip > ${DELLY_COMBI}

md5sum ${DELLY_COMBI} | awk '{print $1}' > ${DELLY_COMBI}.md5

tabix -p vcf ${DELLY_COMBI}

md5sum ${DELLY_COMBI}.tbi | awk '{print $1}' > ${DELLY_COMBI}.tbi.md5

## BEDPE
DELLY_BEDPE=${DELLY_COMBI/.vcf.gz/.bedpe.txt}

python ${DELLY2BED} -v ${DELLY_COMBI} -o ${DELLY_BEDPE}

tar -cvzf ${DELLY_BEDPE}.tar.gz ${DELLY_BEDPE}

md5sum ${DELLY_BEDPE}.tar.gz | awk '{print $1}' > ${DELLY_BEDPE}tar.gz.md5

## COV
if [[ ! -z $COV_COMBI ]]; then
	COV_COMBI=${RESULTSDIR_ROOT}/${FILENAME_COV}
	
	tar -cvzf ${COV_COMBI}.tar.gz ${COVDIR}

	md5sum ${COV_COMBI}.tar.gz | awk '{print $1}' > ${COV_COMBI}.tar.gz.md5

fi
