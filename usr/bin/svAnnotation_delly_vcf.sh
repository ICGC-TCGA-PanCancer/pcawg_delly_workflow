#!/bin/bash
#PBS -o annoPCAWG.out
#PBS -e annoPCAWG.err
#PBS -l nodes=1:ppn=1
#PBS -l mem=6gb
#PBS -l walltime=24:00:00
#PBS -N anno
#PBS -t 1


SV_ANNOTATE_SCRIPT="/path/to/script/annotateSvCalls_delly_vcf_pawg_dkfz.sh"

ROOTDIR="/path/to/variants"

date
SAMPLES=(
"BLCA-US/416911eb-e10f-4edd-8f07-5e87b0228a11"
"BLCA-US/437e11a0-4137-4614-9f64-c5e798c8bb33"
"BLCA-US/a6e8dd23-c8a5-445a-ae4b-b9f92ed6a73e"
"BRCA-US/5e4bbb6b-66b2-4787-b8ce-70d17bc80ba8"
"BRCA-US/b92ab845-7c4c-4498-88c2-75c2cb770b62"
"BRCA-US/d525a66a-2c5d-46c2-b0b8-6469e626fbcd"
"BRCA-US/dc22f90b-bb26-45ac-8ec9-2a37f7e8e7e9"
"BTCA-SG/8c5fad4e-f37e-4021-b777-12b180a834e9"
"BTCA-SG/d080db6b-583b-46fe-9e2b-b70069ebe960"
"CESC-US/4eda8fde-9820-4062-9706-45886bdf548c"
)

uname -a

INDEX=$(( $PBS_ARRAYID -1 ))

SAMPLE=${SAMPLES[$INDEX]}
echo $SAMPLE

PROJECT=$(echo ${SAMPLE} | sed 's/\/.*//')
SAMPLE_NAME=$(echo ${SAMPLE} | sed 's/[^/]*\///')
echo $SAMPLE_NAME

bash  $SV_ANNOTATE_SCRIPT $SAMPLE_NAME "delly duppy invy jumpy" "${ROOTDIR}" "${PROJECT}" "sv"