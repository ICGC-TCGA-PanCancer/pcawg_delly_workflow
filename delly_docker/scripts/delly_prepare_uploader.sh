#!/bin/bash

# $META.sv.vcf.gz
# $META.sv.vcf.gz.tbi
# META = Sample ID + Workflow + Date + Type

DELLY2BED=$1
RESULTSDIR_ROOT=$2
DELLY_COMBI=$3
DEL=$4
DUP=$5
INV=$6
TRA=$7
PEDUMP=$8
BAM=$9
FILENAME_LOG=${10}
FILENAME_COV=${11}
COVDIR=${12}
DELLY_COMBI_RAW=${13}
DEL_RAW=${14}
DUP_RAW=${15}
INV_RAW=${16}
TRA_RAW=${17}
SAMPLEPAIR=${18}
TIMING_SCRIPT=${19}
TIME_JSON=${20}
QC_SCRIPT=${21}
QC_JSON=${22}
#TIMING_SCRIPT=delly_pcawg_timing_json.py

OUTDIR=/datastore/

if [[ ! -d ${OUTDIR} ]]; then
	mkdir ${OUTDIR}
fi

## Combine VCF
vcfcombine ${DEL} ${DUP} ${INV} ${TRA} | grep -vP '^hs37d5|^GL0' | vcf-sort | bgzip > ${DELLY_COMBI}
md5sum ${DELLY_COMBI} | awk '{print $1}' > ${DELLY_COMBI}.md5
tabix -p vcf ${DELLY_COMBI}
md5sum ${DELLY_COMBI}.tbi | awk '{print $1}' > ${DELLY_COMBI}.tbi.md5

cp ${DELLY_COMBI}* ${OUTDIR}

## BEDPE
DELLY_BEDPE=${DELLY_COMBI/.vcf.gz/.bedpe.txt}
python ${DELLY2BED} -v ${DELLY_COMBI} -o ${DELLY_BEDPE}

md5sum ${DELLY_BEDPE} | awk '{print $1}' > ${DELLY_BEDPE}.md5

tar -cvzf ${DELLY_BEDPE}.tar.gz ${DELLY_BEDPE}

md5sum ${DELLY_BEDPE}.tar.gz | awk '{print $1}' > ${DELLY_BEDPE}.tar.gz.md5

cp ${DELLY_BEDPE}* ${OUTDIR}

## readname adjust
DELLY_DUMP=${DELLY_COMBI/.vcf.gz/.readname.txt}
DEL_DUMP="${DEL/.highConf.vcf/.readname.txt}"
DUP_DUMP="${DUP/.highConf.vcf/.readname.txt}"
INV_DUMP="${INV/.highConf.vcf/.readname.txt}"
TRA_DUMP="${TRA/.highConf.vcf/.readname.txt}"

bash ${PEDUMP} ${DEL} ${DEL/.deletions.*/.deletions.pe_dump.txt} ${BAM} > ${DEL_DUMP}
bash ${PEDUMP} ${DUP} ${DUP/.duplications.*/.duplications.pe_dump.txt} ${BAM} > ${DUP_DUMP}
bash ${PEDUMP} ${INV} ${INV/.inversions.*/.inversions.pe_dump.txt} ${BAM} > ${INV_DUMP}
bash ${PEDUMP} ${TRA} ${TRA/.translocations.*/.translocations.pe_dump.txt} ${BAM} > ${TRA_DUMP}

tar -cvzf ${DELLY_DUMP}.tar.gz ${DEL_DUMP} ${DUP_DUMP} ${INV_DUMP} ${TRA_DUMP}
md5sum ${DELLY_DUMP}.tar.gz | awk '{print $1}' > ${DELLY_DUMP}.tar.gz.md5

cp ${DELLY_DUMP}* ${OUTDIR}

## LOG and COV - for somatic calls
if [[ $# -gt 9 ]];then


# combine raw calls
vcfcombine ${DEL_RAW} ${DUP_RAW} ${INV_RAW} ${TRA_RAW} | grep -vP '^hs37d5|^GL0' | vcf-sort | bgzip > ${DELLY_COMBI_RAW}
md5sum ${DELLY_COMBI_RAW} | awk '{print $1}' > ${DELLY_COMBI_RAW}.md5
tabix -p vcf ${DELLY_COMBI_RAW}
md5sum ${DELLY_COMBI_RAW}.tbi | awk '{print $1}' > ${DELLY_COMBI_RAW}.tbi.md5

cp ${DELLY_COMBI_RAW}* ${OUTDIR}


## log files
#LOG_COMBI=${RESULTSDIR_ROOT}/${FILENAME_LOG}
LOG_COMBI=${FILENAME_LOG}
if [[ ! -z $LOG_COMBI  ]]; then
	DEL_LOG="$(dirname $DEL)/*log"
	DUP_LOG="$(dirname $DUP)/*log"
	INV_LOG="$(dirname $INV)/*log"
	TRA_LOG="$(dirname $TRA)/*log"

	tar -cvzf ${LOG_COMBI}.tar.gz ${DEL_LOG} ${DUP_LOG} ${INV_LOG} ${TRA_LOG} ${COVDIR}/*log
	md5sum ${LOG_COMBI}.tar.gz | awk '{print $1}' > ${LOG_COMBI}.tar.gz.md5
	cp ${LOG_COMBI}* ${OUTDIR}
fi

## COV
COV_COMBI=${RESULTSDIR_ROOT}/${FILENAME_COV}
if [[ ! -z $COV_COMBI ]]; then
	tar -cvzf ${COV_COMBI}.tar.gz ${COVDIR}
	md5sum ${COV_COMBI}.tar.gz | awk '{print $1}' > ${COV_COMBI}.tar.gz.md5
	cp ${COV_COMBI}* ${OUTDIR}
	
	# package up plots. Assume plots are in ${COVDIR}/plot
	COVPLOT_COMBI=${RESULTSDIR_ROOT}/${FILENAME_COV}.plots
	tar -cvzf ${COVPLOT_COMBI}.tar.gz ${COVDIR}/plot
	md5sum ${COVPLOT_COMBI}.tar.gz | awk '{print $1}' > ${COVPLOT_COMBI}.tar.gz.md5
	cp ${COVPLOT_COMBI}* ${OUTDIR}
fi

## timing json
TIME_OUT=${TIME_JSON}
DEL_TIME="$(dirname $DEL)/*delly.time"
DUP_TIME="$(dirname $DUP)/*duppy.time"
INV_TIME="$(dirname $INV)/*invy.time"
TRA_TIME="$(dirname $TRA)/*jumpy.time"

python ${TIMING_SCRIPT} -s ${SAMPLEPAIR} -a ${DEL_TIME} -b ${DUP_TIME} -c ${INV_TIME} -d ${TRA_TIME} -e ${COVDIR} -o ${TIME_OUT}

## qc json
QC_OUT=${QC_JSON}
DEL_QC="$(dirname ${DEL})"
DUP_QC="$(dirname ${DUP})"
INV_QC="$(dirname ${INV})"
TRA_QC="$(dirname ${TRA})"

python ${QC_SCRIPT} -s ${SAMPLEPAIR} -a ${DEL_QC} -b ${DUP_QC} -c ${INV_QC} -d ${TRA_QC} -e ${COVDIR} -o ${QC_OUT}


fi
