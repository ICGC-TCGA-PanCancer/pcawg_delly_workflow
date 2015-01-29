#!/bin/bash

SAMPLE=$1
SAMPLE_NAME=$(basename $SAMPLE)
SV_TYPES_TO_ANNOTATE=$2
DIR_PROJECT=$3
TUMOR_ENTITY=$4
DIR_SVS="results/$5"
DIR_SV_COLLECTION="/path/to/svCallCollections/$6"
GENCODE="/path/to/annotation/gencode.v19.gene.minimal.bed.gz"
echo $SAMPLE, $SV_TYPES_TO_ANNOTATE

CUTOFF_SV_OVERHANG=1000

BEDTOOLS=bedtools
VCF2TSV=/home/weischej/software/vcflib/bin/vcf2tsv
VCFADDINFO=/home/weischej/software/vcflib/bin/vcfaddinfo
DELLY2BED="/path/to/script/dellyVcf2Tsv.py"
SOMATICFILTER="/path/to/script/DellySomaticFreqFilter.py"

for SV_TYPE in `echo $SV_TYPES_TO_ANNOTATE`
do
	echo $SV_TYPE
if [[ $SV_TYPE == "delly" ]];then
	svSuffix="deletions"
elif [[ $SV_TYPE == "duppy" ]];then
	svSuffix="duplications"
elif [[ $SV_TYPE == "invy" ]];then
	svSuffix="inversions"
elif [[ $SV_TYPE == "jumpy" ]];then
	svSuffix="translocations"
fi		
echo $svSuffix
	date

	SV_FILE_BASE=$DIR_PROJECT/$DIR_SVS/$SV_TYPE/${TUMOR_ENTITY}/$SAMPLE/${SAMPLE_NAME}.${svSuffix}
	## check if is with breakpoint [bp] notation
	if [[ -f ${SV_FILE_BASE}.bp.vcf ]]; then
		SV_FILE=${SV_FILE_BASE}.bp.vcf
		VCF="bp.vcf"
	else
		SV_FILE=${SV_FILE_BASE}.vcf
		VCF="vcf"
	fi
	cp ${SV_FILE} ${SV_FILE_BASE}.tmp.vcf

	$VCF2TSV -n "." ${SV_FILE} | awk 'BEGIN{ OFS="\t" }{ if (NR==1) { for (i=1; i<=NF; i++) { c[$i]=i };} print $c["CHROM"],$c["POS"]-'$CUTOFF_SV_OVERHANG',$c["POS"]+'$CUTOFF_SV_OVERHANG',$c["CHR2"],$c["END"]-'$CUTOFF_SV_OVERHANG',$c["END"]+'$CUTOFF_SV_OVERHANG',NR,".",".",".",$c["ID"],$c["CHROM"]"%",$c["POS"] }' | sed 's/\.fa\t/\t/g;s/chr//;s/chr//' | sed '1d' > ${SV_FILE_BASE}.tmp.bedpe



	for j in $DIR_SV_COLLECTION/{*,*/*}/$SV_TYPE
	do
		COMPARISON_SAMPLE_SET_DIR=`echo $j | sed -e 's%'$DIR_SV_COLLECTION'/%%;s%/'$SV_TYPE'$%%'`
		COMPARISON_SAMPLE_SET=`echo $COMPARISON_SAMPLE_SET_DIR | sed 's/\//_/'`

		count=1
		for i in $DIR_SV_COLLECTION/$COMPARISON_SAMPLE_SET_DIR/$SV_TYPE/combinedSVs.bedpe.part*
		do
			if [[ -f $i ]]; then
			echo $i
			$BEDTOOLS pairtopair -is -a ${SV_FILE_BASE}.tmp.bedpe -b  <(awk 'NF>1' $i) > ${SV_FILE_BASE}.tmp.bedpe.overlap.${COMPARISON_SAMPLE_SET}.p${count}

			ls -lh  ${SV_FILE_BASE}.tmp.bedpe.overlap.${COMPARISON_SAMPLE_SET}.p${count}
			count=$(( $count + 1 ))
			fi
		done
		if [[ -f ${SV_FILE_BASE}.tmp.bedpe.overlap.${COMPARISON_SAMPLE_SET}.p1 ]]; then
		cat ${SV_FILE_BASE}.tmp.bedpe.overlap.${COMPARISON_SAMPLE_SET}.p* | cut -f1-13,20 | sort | uniq | cut -f1-13 | cat - ${SV_FILE_BASE}.tmp.bedpe | sort -k7n | uniq -c | awk 'BEGIN{ OFS="\t" }{ $1=$1-1; print }' > ${SV_FILE_BASE}.tmp.bedpe.overlap.${COMPARISON_SAMPLE_SET}.sampleCount
		rm ${SV_FILE_BASE}.tmp.bedpe.overlap.${COMPARISON_SAMPLE_SET}.p*
		fi
		cat $DIR_SV_COLLECTION/$COMPARISON_SAMPLE_SET_DIR/$SV_TYPE/numberOfSamples.txt > ${SV_FILE_BASE}.tmp.bedpe.overlap.${COMPARISON_SAMPLE_SET}.totalNumSamples

		cat ${SV_FILE} | grep "^#" | sed 's/FILTER\tINFO\tFORMAT.*/FILTER\tINFO/' | sed 's/\(##INFO=<ID=CIEND.*\)/##INFO=<ID=SC_'$COMPARISON_SAMPLE_SET'_C,Number=1,Type=Float,Description="Count of variant in '$COMPARISON_SAMPLE_SET'">\n##INFO=<ID=SC_'$COMPARISON_SAMPLE_SET'_F,Number=1,Type=Float,Description="Frequency of variant in '$COMPARISON_SAMPLE_SET'">\n\1/' > ${SV_FILE_BASE}.tmp.bedpe.overlap.${COMPARISON_SAMPLE_SET}.sampleCount.vcf
		cat ${SV_FILE_BASE}.tmp.bedpe.overlap.${COMPARISON_SAMPLE_SET}.sampleCount | awk -v sampleCount=`cat ${SV_FILE_BASE}.tmp.bedpe.overlap.${COMPARISON_SAMPLE_SET}.totalNumSamples` 'BEGIN{ OFS="\t" }{ print $13,$14,$12,".",".",".",".","SC_'$COMPARISON_SAMPLE_SET'_C="$1";SC_'$COMPARISON_SAMPLE_SET'_F="int(($1/sampleCount)*10000)/10000 }' | sed 's/%//' >> ${SV_FILE_BASE}.tmp.bedpe.overlap.${COMPARISON_SAMPLE_SET}.sampleCount.vcf


	$VCFADDINFO ${SV_FILE_BASE}.tmp.vcf ${SV_FILE_BASE}.tmp.bedpe.overlap.${COMPARISON_SAMPLE_SET}.sampleCount.vcf > ${SV_FILE_BASE}.svFreq.${VCF}



		cp ${SV_FILE_BASE}.svFreq.${VCF} ${SV_FILE_BASE}.tmp.vcf
		rm ${SV_FILE_BASE}.tmp.bedpe.overlap.${COMPARISON_SAMPLE_SET}*
	done
	rm ${SV_FILE_BASE}.tmp.*
	date


	
	if [[ -f ${SV_FILE_BASE}.svFreq.${VCF} ]];then
	
		python ${SOMATICFILTER} -s ${TUMOR_ENTITY} -v ${SV_FILE_BASE}.svFreq.${VCF}
	
		for f in ${SV_FILE_BASE}.svFreq.*somatic*.vcf  ${SV_FILE_BASE}.svFreq.*germ*.vcf; do 
		echo $f
		$DELLY2BED -v ${f} -o ${f/.vcf/.bedpe.txt}
		done
	
	fi

done

echo -e "###\ncombining SV call set\n###"

RESULTDIR_COMBINE=$DIR_PROJECT/$DIR_SVS/DELLY_COMBINE/${SAMPLE_NAME}
mkdir -p $RESULTDIR_COMBINE

for svtype in  delly duppy invy jumpy; do

        sv_bp=${DIR_PROJECT}/${DIR_SVS}/${svtype}/${TUMOR_ENTITY}/$SAMPLE/${SAMPLE_NAME}*.svFreq.bp.vcf


        sv=${DIR_PROJECT}/${DIR_SVS}/${svtype}/${TUMOR_ENTITY}/$SAMPLE/${SAMPLE_NAME}*.svFreq.vcf
		ls -lh $sv
        if [[ -f $(echo $sv_bp) && $svtype != "jumpy"  && $(stat -c%s $(echo $sv_bp) ) -gt 20 ]];then
          ln -fs $sv_bp $RESULTDIR_COMBINE/$svtype.vcf
          elif [[ -f $(echo $sv) && $(stat -c%s $(echo $sv) ) -gt 20 ]];then
          ln -fs $sv $RESULTDIR_COMBINE/$svtype.vcf
        fi

done

DELLY_COMBI=${RESULTDIR_COMBINE}/${SAMPLE_NAME}.svFreq.vcf.gz

vcf-concat $RESULTDIR_COMBINE/delly.vcf $RESULTDIR_COMBINE/duppy.vcf $RESULTDIR_COMBINE/invy.vcf $RESULTDIR_COMBINE/jumpy.vcf | grep -vP '^hs37d5|^GL0' | vcf-sort | bgzip -c > $DELLY_COMBI

# FILTER
python ${SOMATICFILTER} -v $DELLY_COMBI -s ${TUMOR_ENTITY}
for vcf in ${RESULTDIR_COMBINE}/${SAMPLE_NAME}.svFreq*vcf
do
ls -lh $vcf
BEDPE=${vcf/.vcf*/.bedpe.txt}
${DELLY2BED} -v ${vcf} -o ${BEDPE} -g ${GENCODE}
wc -l ${BEDPE}

done
