#!/bin/bash

# $META.sv.vcf.gz
# $META.sv.vcf.gz.tbi
# META = Sample ID + Workflow + Date + Type

DIR=$(cd $(dirname "$0"); pwd)
export PATH=$PATH:$DIR

DELLY2BED=$1
RESULTSDIR_ROOT=$2
DELLY_COMBI=$3
DEL=$4
DUP=$5
INV=$6
TRA=$7
PEDUMP=$8
BAM=$9
FILENAME_LOG=$10
FILENAME_COV=$11
COVDIR=$12

echo $DELLY2BED $DEL $DUP $INV $TRA
# Combine VCF
vcfcombine ${DEL} ${DUP} ${INV} ${TRA} | grep -vP '^hs37d5|^GL0' | vcf-sort | bgzip > ${DELLY_COMBI}

md5sum ${DELLY_COMBI} | awk '{print $1}' > ${DELLY_COMBI}.md5

tabix -p vcf ${DELLY_COMBI}

md5sum ${DELLY_COMBI}.tbi | awk '{print $1}' > ${DELLY_COMBI}.tbi.md5

## BEDPE
DELLY_BEDPE=${DELLY_COMBI/.vcf.gz/.bedpe.txt}

python ${DELLY2BED} -v ${DELLY_COMBI} -o ${DELLY_BEDPE}

tar -cvzf ${DELLY_BEDPE}.tar.gz ${DELLY_BEDPE}

md5sum ${DELLY_BEDPE}.tar.gz | awk '{print $1}' > ${DELLY_BEDPE}.tar.gz.md5

echo "# PE_READNAME"
DELLY_DUMP=${DELLY_COMBI/.vcf.gz/.readname.txt}
DEL_DUMP="${DEL/.highConf.vcf/.readname.txt}"
DUP_DUMP="${DUP/.highConf.vcf/.readname.txt}"
INV_DUMP="${INV/.highConf.vcf/.readname.txt}"
TRA_DUMP="${TRA/.highConf.vcf/.readname.txt}"

echo $DEL
ls ${DEL/.deletions.*/.deletions.pe_dump.txt}

echo -e "bash ${PEDUMP} ${DEL} ${DEL/.deletions.*/.deletions.pe_dump.txt} ${BAM} > ${DEL_DUMP}"
bash ${PEDUMP} ${DEL} ${DEL/.deletions.*/.deletions.pe_dump.txt} ${BAM} > ${DEL_DUMP}
bash ${PEDUMP} ${DUP} ${DUP/.duplications.*/.duplications.pe_dump.txt} ${BAM} > ${DUP_DUMP}
bash ${PEDUMP} ${INV} ${INV/.inversions.*/.inversions.pe_dump.txt} ${BAM} > ${INV_DUMP}
bash ${PEDUMP} ${TRA} ${TRA/.translocations.*/.translocations.pe_dump.txt} ${BAM} > ${TRA_DUMP}


echo TAR
tar -cvzf ${DELLY_DUMP}.tar.gz ${DEL_DUMP} ${DUP_DUMP} ${INV_DUMP} ${TRA_DUMP}
md5sum ${DELLY_DUMP}.tar.gz | awk '{print $1}' > ${DELLY_DUMP}.tar.gz.md5

if [[ $# -gt 9 ]];then
## log files
LOG_COMBI=${RESULTSDIR_ROOT}/${FILENAME_LOG}
if [[ ! -z $LOG_COMBI  ]]; then
	DEL_LOG=$(echo $(dirname $DEL)/*log)
	DUP_LOG=$(echo $(dirname $DUP)/*log)
	INV_LOG=$(echo $(dirname $INV)/*log)
	TRA_LOG=$(echo $(dirname $TRA)/*log)

	LOG_COMBI=${RESULTSDIR_ROOT}/${FILENAME_LOG}
	tar -cvzf ${LOG_COMBI}.tar.gz ${DEL_LOG} ${DUP_LOG} ${INV_LOG} ${TRA_LOG}
	md5sum ${LOG_COMBI}.tar.gz | awk '{print $1}' > ${LOG_COMBI}.tar.gz.md5
fi

## COV
COV_COMBI=${RESULTSDIR_ROOT}/${FILENAME_COV}
if [[ ! -z $FILENAME_COV ]]; then
	tar -cvzf ${COV_COMBI}.tar.gz ${COVDIR}

	md5sum ${COV_COMBI}.tar.gz | awk '{print $1}' > ${COV_COMBI}.tar.gz.md5

fi
fi
