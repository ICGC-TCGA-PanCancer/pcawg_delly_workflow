#!/bin/bash
vcf=$1
pedump=$2
bamfile=$3

join -1 1 -2 1 <(zgrep -v '#' $vcf | cut -f 3 | sort -k1,1) <(sed '1d' $pedump) | sed 's/ /\t/g' > ${pedump}.tmp

while read ID CHR1 POS1 CHR2 POS2 QUAL
do
    if [ ${ID} != "#id" ]
    then
	POS01=`expr ${POS1} + 1`
	POS02=`expr ${POS2} + 1`
	RNAME=`samtools view ${bamfile} ${CHR1}:${POS01}-${POS01} | grep -w "${POS01}" | grep -m 1 -w "${POS02}" | cut -f 1`
	echo -e "${ID}\t${CHR1}\t${POS1}\t${CHR2}\t${POS2}\t${QUAL}\t${RNAME}"
    else
	echo -e "#id\tchr\tpos\tmatechr\tmatepos\tmapq\treadname"
    fi
done < ${pedump}.tmp 

rm ${pedump}.tmp 
