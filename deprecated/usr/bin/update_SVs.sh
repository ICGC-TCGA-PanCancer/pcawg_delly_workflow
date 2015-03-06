#!/bin/bash
ROOTDIR=/icgc/dkfzlsdf/analysis/PAWG
export PATH=$PATH:/home/weischej/software/vcflib/bin/
echo $ROOTDIR
SVDIR=${ROOTDIR}/results/sv/
for tumorType in {BLCA-US,BRCA-US,BTCA-SG,CESC-US,COAD-US,ESAD-UK,GBM-US,HNSC-US,KICH-US,KIRC-US,KIRP-US,LAML-US,LGG-US,LIHC-US,LUAD-US,LUSC-US,OV-US,PACA-CA,PRAD-UK,PRAD-US,READ-US,SARC-US,SKCM-US,STAD-US,THCA-US,UCEC-US}
do
do echo $tumorType
for sampleType in {control,tumor}
do echo $sampleType
	mkdir -p ${tumorType}/${sampleType}
	if [ $sampleType == "control" ]
	then
		samplePos="tail"
	else
		samplePos="head"
	fi

	for svType in {delly,duppy,invy,jumpy}

	do

		for svFile in $(find  ${SVDIR}/${svType}/${tumorType}/*/  -iname "*ions.vcf" -or -iname "*ions.bp.vcf") 
		do
			ls $svFile	
			mkdir -p ${tumorType}/${sampleType}/${svType}
			cp $svFile ${tumorType}/${sampleType}/${svType}
		done

		echo   ${tumorType}/${sampleType}/${svType}/*.vcf
		for i in ${tumorType}/${sampleType}/${svType}/*.vcf
		do
			echo $i
			vcfsamplenames $i
			sampleTot=`vcfsamplenames $i`
			n=0; for token in $sampleTot; do n=$((n+1));done
			if [[ $n == 1 && $sampleType == "control" ]];then
			rm $i
			continue
			fi
			vcfsamplenames $i | $samplePos
			sample=`vcfsamplenames $i | $samplePos -n1`
			vcfkeepsamples $i $sample | vcf2tsv -g -n "." | awk 'BEGIN{ OFS="\t" }{ if (NR==1) { for (i=1; i<=NF; i++) { c[$i]=i };} if ($c["DV"]>0) print $c["CHROM"],$c["POS"],$c["POS"]+1,$c["CHR2"],$c["END"],$c["END"]+1,$c["SAMPLE"] }' | sed 's/\.fa\t/\t/g' | sed '1d'
		done > ${tumorType}/${sampleType}/${svType}/combinedSVs.bedpe

		split -l 5000000 -a3 -d ${tumorType}/${sampleType}/${svType}/combinedSVs.bedpe ${tumorType}/${sampleType}/${svType}/combinedSVs.bedpe.part
		cut -f 7 ${tumorType}/${sampleType}/${svType}/combinedSVs.bedpe | sort | uniq | wc -l > ${tumorType}/${sampleType}/${svType}/numberOfSamples.txt
	done
done
done
