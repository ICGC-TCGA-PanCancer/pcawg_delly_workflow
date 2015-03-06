#!/bin/bash
#PBS -o /icgc/dkfzlsdf/analysis/prostate/weischej/results/cluster_run/pcawgDEL.out
#PBS -e /icgc/dkfzlsdf/analysis/prostate/weischej/results/cluster_run/pcawgDEL.err
#PBS -m abe
#PBS -M weischen@embl.de
#PBS -l nodes=1:ppn=2
#PBS -l mem=16gb
#PBS -l walltime=24:00:00
#PBS -N pcawgDEL
#PBS -t 2

## qsub /home/weischej/job_scripts/pawg_scripts/PAWG/sv_calling_vcf_pawg_dkfz.sh
date
uname -a
ROOTFOLDER="/icgc/dkfzlsdf/analysis/PAWG/freeze_train2"

DATADIR="${ROOTFOLDER}/samples"
RESULTDIR="${ROOTFOLDER}/results/sv_pilot60"
REFGENOME="/icgc/ngs_share/assemblies/hg19_GRCh37_1000genomes/sequence/1KGRef/hs37d5.fa"
DELLY="/home/weischej/software/sv_tools/delly_v0.5.9_parallel_linux_x86_64bit"
SOMATIC_FILTER="/home/weischej/job_scripts/pawg_scripts/PAWG/DellySomaticFreqFilter.py"
DELLY2BED="/home/weischej/job_scripts/pawg_scripts/PAWG/dellyVcf2Tsv.py"
PEDUMP="/home/weischej/job_scripts/pawg_scripts/PAWG/delly_pe_dump.sh"
GENCODE="/icgc/dkfzlsdf/analysis/prostate/weischej/ref_genome/gencode.v19.gene.minimal.bed.gz"
REF_EXCLUDE="/icgc/dkfzlsdf/analysis/prostate/weischej/ref_genome/human.hg19.excl.tsv"
export TMP="/data/weischej"

$DELLY -? | grep Version

TASK_DEL=1
TASK_DUP=0
TASK_INV=0
TASK_TRANS=0

BREAKPOINT=1

SOMATIC_FILTERING=1

export OMP_NUM_THREADS=2

GERMS=(
"BLCA-US/fa36e89d-55b8-4c72-9392-80113efde076/PCAWG.c878fe80-0a2e-43d2-ab62-1214fc34c282"
"BRCA-US/0fd19ef1-6ae9-43d8-88cc-8c81b97221cf/PCAWG.be4e193a-0c7e-4f1f-bb1d-db374264155d"
"BRCA-US/7dc06c71-8af9-428e-b87e-b268aa2b9168/PCAWG.1f6de218-f294-4555-9a6c-04c6c4ed81ef"
"BTCA-SG/34d42b18-1717-4720-a487-4459165c6782/3a62b4250f4c7227fd5283888f2b598e"
"BTCA-SG/6c85dd09-dc9e-43ff-b8f6-cde205524a41/6047b764df227f9e79bfd1b0c10e5c0c"
"CESC-US/0074e250-33ea-4530-b716-aede78a6a443/PCAWG.94f8d946-a92e-4d2b-9f29-8e10f4274efe"
"CESC-US/1e8faf9d-5754-4c99-a099-7d16c68a64ad/PCAWG.3b2c5881-e2a9-4ae9-9abd-bafec7c045f1"
"CESC-US/bd829214-f230-4331-b234-def10bbe7938/PCAWG.ba8bb154-ef77-4383-99b5-0abc5034aaeb"
"COAD-US/2cfc1abc-5f03-480f-b6ca-c0a66dbd0979/PCAWG.b53f2539-d20a-4549-b061-fcf3a35be49f"
"COAD-US/4a960a82-841d-4775-b3a1-3f95b2f50a23/PCAWG.0e0d6399-3a1e-4b5a-8f9b-02303edd8f4a"
#10
"GBM-US/fcc335ca-9ad0-4745-8958-85d0f74073eb/PCAWG.701ee04f-ee1c-42b4-9614-499d51cf4a0a"
"GBM-US/68381915-3304-4d69-8dc3-95eebf28ea49/PCAWG.fa4fa49d-6d53-4ffa-9759-ffb884b28d17"
"HNSC-US/cdad9413-eb63-4290-9955-630fe32296fc/PCAWG.863fe801-c4eb-436c-9410-545a1164e943"
"KICH-US/c93832a2-920f-4f60-87aa-464c6e5270cc/PCAWG.47187a57-68f9-44c2-8e11-87e2169d43a1"
"KICH-US/4f58250a-9ebe-4a5b-9c6a-f804be2d1add/PCAWG.88eb7362-ea2f-43e7-861d-e9b70dce04f3"
"KIRC-US/d70ab7dc-94d5-4285-a9c5-01ee037f91ce/PCAWG.cdccdb98-4446-41f2-bcf2-e5459a2e477d"
"KIRC-US/f6a408bf-f5ee-4618-a00e-c61640053196/PCAWG.80d8e24d-3ec1-4e43-a28a-4dba015c7fa6"
"KIRP-US/6b677539-15c7-44a3-a6fd-d4a823668252/PCAWG.3a921418-7ca7-41af-aa40-8cc35d64156c"
"LAML-US/fcc373a3-3b60-4429-b74f-224686d679ce/PCAWG.b0511bcd-f3d6-4557-bdb5-6c7439b7784b"
"LGG-US/b63be7c7-420c-40a5-b823-efaa75976973/PCAWG.f466f409-012f-4833-957b-8de7d21ae60f"
#20
"LGG-US/4ef08191-bec0-45cd-80d8-fea1f22b3a11/PCAWG.3fb8200c-664f-4526-b558-e1b16acee25a"
"LUAD-US/2816802d-5e8d-4a81-82bf-88f42ff92c38/PCAWG.3fa326fb-473e-49c6-888a-8774c1beed5d"
"LUAD-US/f817c944-a8a1-4b5f-a751-de5bc9fd6812/PCAWG.fb5bfc6c-2215-459d-8e51-520e3397b525"
"OV-US/3ab1316a-5041-47a0-8bd4-e4f3b700ff97/PCAWG.01db3f49-af1e-4779-803b-b2e516a9fbfd"
"OV-US/70526856-e50e-45ef-9a93-17121888f0a8/PCAWG.999309db-074b-454c-897e-4935d45ac118"
"PRAD-US/ec23b03c-e72f-445e-b481-8a4db35553b4/PCAWG.1d7f3a4b-3795-4ba5-a840-583767b7a96f"
"PRAD-US/2a2938e1-6bba-42e4-ba62-04a57dd838bc/PCAWG.34f66158-f8af-4de3-b55a-cc44d8ebd143"
"READ-US/15d31ad9-9ef8-495b-bde8-660e0990e744/PCAWG.fa7a917b-3692-408e-a23b-88d52f7b91d3"
"READ-US/7634a2d6-33d6-4d5a-9780-e62935985cc1/PCAWG.71481425-8371-4e2f-be7f-22ef1883af87"
"SARC-US/616b79ad-38e6-4715-90f8-ce010e19bb58/PCAWG.7aa1e116-1111-4acb-b368-578d10458cd0"
#30
"SARC-US/87eb7494-f142-49a7-8a5e-4f862311d40c/PCAWG.2ebf592b-a06d-442c-8b79-743df0d2d0f0"
"SKCM-US/96aa2792-3c16-4a9a-b3c9-65bdbc43d2fc/PCAWG.af9d74d7-e130-4421-acd8-381e7dd562a7"
"SKCM-US/ec2d62cb-4f90-43ff-88b0-61be40dd92f7/PCAWG.02a966f9-14a4-4376-88df-8d4ca397c763"
"STAD-US/6b1280da-a45d-4239-bfd6-9aa70fac39c3/PCAWG.043eb12d-c4a7-4f60-b133-2363530ce4b2"
"THCA-US/27d0b7c5-d9b8-437c-8c57-2217d76dbef5/PCAWG.d2149bf0-0ebf-44fc-8763-98cbac731b09"
"UCEC-US/a80881bf-3bf3-4597-974b-7621d1ccb18e/PCAWG.4a47eec1-a25e-4591-be8e-110637134b0e"
"LIHC-US/f0b31ba6-d9ca-4758-80e0-f386ee1194f7/PCAWG.29034096-d0af-4a86-b348-1c918253a9ef"
"LIHC-US/aa5f3d31-2bf5-451e-ae41-f19f6d7a0748/PCAWG.8829bdfc-961c-404f-87a2-222ed55f12c5"
"LIHC-US/f7878f38-4c60-4d15-9eb7-1c8ae79f8124/PCAWG.a1c6172d-d3a5-4020-b53c-c356a352adfc"
"READ-US/9129813f-c196-49bb-b645-2257b5e134b6/PCAWG.3185c99a-b8ff-46a6-bd0a-c78bf9ddb24a"
#40
"BLCA-US/f22a72c5-73c8-478d-b03e-04599b9d5321/PCAWG.67455c36-aa47-4cc4-8b6d-9a9012b616ed"
"BLCA-US/964bac8f-43cc-4a47-b233-53798d287029/PCAWG.13985b6b-d7b6-4efd-9c53-288f4d269a0c"
"BRCA-US/88c45872-86a2-4cfa-8424-93030c4fdd4f/PCAWG.7ff82d5b-8ad1-4da2-b6bf-f1c746609638"
"BRCA-US/42649da3-0a01-4ffe-b27c-a368b55cc0f2/PCAWG.4544b1d3-bd47-4921-a049-7f4702b75f31"
"HNSC-US/b8e83a08-d46e-43aa-b94e-9b37e51de9a0/PCAWG.000f332c-7fd9-4515-bf5f-9b77db43a3fd"
"HNSC-US/e42d8b45-646d-4bf2-b4d9-1c3998d231c7/PCAWG.a0963407-05e7-4c84-bfe0-34aacac08eed"
"LUSC-US/4bf50875-e55f-461a-abb0-a08d757e574a/PCAWG.19efc6e3-91dc-456d-9a03-38ccc7f71f42"
"LUSC-US/28e7b333-86e9-4536-bdb4-b4e6f6648941/PCAWG.9509ed15-8d7f-4931-98aa-738861641411"
"STAD-US/250a9d13-6c2f-4d0c-999b-caab3a24d213/PCAWG.222f5df2-cab8-4e0f-8e65-cfb1862779ca"
"STAD-US/9ba9b557-e8fd-40f4-930d-2e538ac5e51f/PCAWG.dd7df5f1-6a83-429a-8b55-2a5ee392e308"
#50
"UCEC-US/c2809b17-5b64-495e-b58a-1f4823b848dd/PCAWG.72350fe0-0c5e-493f-8d19-ee2303dc7f81"
)

TUMORS=(
"BLCA-US/416911eb-e10f-4edd-8f07-5e87b0228a11/PCAWG.066b5025-1a70-4db4-bd98-964b8c9939c3"
"BRCA-US/5e4bbb6b-66b2-4787-b8ce-70d17bc80ba8/PCAWG.4b7c5c51-36d4-45a4-ae4d-0e8154e4f0c6"
"BRCA-US/b92ab845-7c4c-4498-88c2-75c2cb770b62/PCAWG.a3efd151-d3c6-49da-9692-f0436e849d87"
"BTCA-SG/d080db6b-583b-46fe-9e2b-b70069ebe960/a51ad19bf9dcf4819371740c732bcba0"
"BTCA-SG/8c5fad4e-f37e-4021-b777-12b180a834e9/07a920d94cb607e6171890cef2220498"
"CESC-US/bf95e410-b371-406c-a192-391d2fce94b2/PCAWG.dc9dd886-5c1b-4564-ba84-fa2a70cc4ffe"
"CESC-US/4eda8fde-9820-4062-9706-45886bdf548c/PCAWG.0b2484f8-2bc8-474b-830a-42c68c78c881"
"CESC-US/e144c843-5043-4fb7-ab39-128ca91ffe92/PCAWG.abd8a814-8c7d-4b4a-b4a7-38394a36ac30"
"COAD-US/911ce07d-5c8d-42e4-b85a-69038a15fd13/PCAWG.6cd64542-56ff-444e-9b5a-29efc28fb5af"
"COAD-US/97449717-88cf-4caf-b4f3-d70f1bf7097d/PCAWG.a1f1bcef-0bc0-4a97-8617-1f4b6f493498"
"GBM-US/c174e3fa-00bd-43f1-9a3d-b2903b2d14a4/PCAWG.d19dbf14-3293-4e09-a072-a746bb26376c"
"GBM-US/1de43b78-ff01-4cb2-a94e-6a033ad59c0e/PCAWG.64d83e97-f798-45d1-b9e6-efaa635b4abb"
"HNSC-US/3b3b81f5-460c-4382-822f-be5f279781b3/PCAWG.9428f3db-6c71-41cc-83a0-1bc0d4a105cc"
"KICH-US/5ebc0a85-09b3-4f93-b484-6e4581d17db9/PCAWG.143bbe67-5962-448d-84e7-ebb517ce36b9"
"KICH-US/ab98704c-5a3d-494d-ba3b-85a5c37b0828/PCAWG.df7ec290-c137-4a78-93f2-c0e15bf6b3b1"
"KIRC-US/290d8791-2515-4baa-9c5f-60f6ec97f33a/PCAWG.a0218c53-0b70-4940-8e14-cdc7dde9e5a7"
"KIRC-US/11d59712-2aa8-40e8-8e93-3db41dcde710/PCAWG.964eb3a2-8c65-46b1-9087-14b3b5ade6ad"
"KIRP-US/4aaf156f-32e1-43eb-ae73-424c543c2c1b/PCAWG.af8674a0-521e-4f28-b13f-5559909e60c8"
"LAML-US/ae1fd34f-6a0f-43db-8edb-c329ccf3ebae/PCAWG.47071d63-9223-4faf-9a50-3af9c6c9492e"
"LGG-US/eb899322-b112-49ef-802a-69118308810d/PCAWG.c4acd2ab-93da-47ff-a5ac-14a9c269bc06"
"LGG-US/b58547e6-9f88-4b4e-8312-a0b1d1eb8348/PCAWG.11d167fc-2ff3-42e0-b064-b11ad64d456f"
"LUAD-US/55108813-99d3-4b96-b7d4-8d23554e491c/PCAWG.ab10ec7f-7dca-4615-b5d8-8cc82ae24546"
"LUAD-US/ac866a8f-0bf4-40bc-a8c1-5fa04e0dd537/PCAWG.cf583bf4-a5aa-4c7a-9962-1d20ffc42a98"
"OV-US/1f1a065b-1458-4846-99b3-7370bbf7b367/PCAWG.00e7f3bd-5c87-40c2-aeb6-4e4ca4a8e720"
"OV-US/24ab6651-8dd0-4d99-92d2-4d87bced077e/PCAWG.20b85de1-8cc4-4a57-baa8-656cdde95fa9"
"PRAD-US/a34f1dba-5758-45c8-b825-1c888d6c4c13/PCAWG.5c7b3dc8-f64b-4ca9-bd43-2245297450b4"
"PRAD-US/831bb915-2b6e-4fc8-be56-0d3bd8878f22/PCAWG.3b8eb3f9-0ebb-4da8-bb18-7d1bf75ce527"
"READ-US/249a5ecb-e9f7-4211-927e-02ccaf4f9e1e/PCAWG.f95a220c-742d-46ee-8110-8bf799142300"
"READ-US/ee770885-b07c-4237-ae57-6eb52111446d/PCAWG.c44b8511-615b-45c2-b848-ac4a419e307e"
"SARC-US/b13d6556-5efa-4580-924d-30fc27c86aef/PCAWG.6e51117c-0705-4967-b674-e4aed6038f8b"
"SARC-US/10209e5b-63cd-49c8-b537-037e946a806c/PCAWG.53d73a93-31ca-480e-ab1b-36742dcde99d"
"SKCM-US/8d3d84eb-6cf3-494f-bc9c-b4430ca34180/PCAWG.bf057243-6550-4e80-9b23-53bd147cb7ee"
"SKCM-US/aebb30c8-6441-4cbc-bdcb-c2e659957309/PCAWG.230303e8-f1ef-4589-9c46-d11e4b83e75c"
"STAD-US/c5fcdc44-297e-4bea-a972-a29eb83bc19e/PCAWG.efd3cefd-3cb0-4e2d-9689-65f60401262d"
"THCA-US/6c6fb07d-6b96-4421-97eb-4de2ef952fa5/PCAWG.80304de2-8f90-4d66-a991-f1102cfb3eb9"
"UCEC-US/906812ff-28fb-4ecd-8040-90b09278d7df/PCAWG.c95d9015-10a2-45bb-bc00-93e1c5815a43"
"LIHC-US/e39c1daa-c784-4587-ae64-34fe57c73f2e/PCAWG.e96e162e-067b-4b4a-9b1d-8627dcffada7"
"LIHC-US/e1f16576-9102-44de-88ed-892be7340067/PCAWG.b75e14f5-11dd-4a0c-a072-304f9ea40885"
"LIHC-US/043cce76-19ef-43ee-8876-e2ae6556254d/PCAWG.ccad54ca-89fb-4818-8122-cfe86373449c"
"READ-US/000e9e28-7d6d-44f5-b637-ddbd62699db7/PCAWG.02bf0d26-f948-4658-b871-748f6c488948"
"BLCA-US/a6e8dd23-c8a5-445a-ae4b-b9f92ed6a73e/PCAWG.a833602e-7ee7-442b-9bf9-f6489cd64ba2"
"BLCA-US/437e11a0-4137-4614-9f64-c5e798c8bb33/PCAWG.af830047-822a-4dcc-88bc-68f7440a208d"
"BRCA-US/dc22f90b-bb26-45ac-8ec9-2a37f7e8e7e9/PCAWG.15c6fc97-de2a-472c-9f20-3bca01462f66"
"BRCA-US/d525a66a-2c5d-46c2-b0b8-6469e626fbcd/PCAWG.39ad557b-b9ca-4dc6-a3c7-eea8798e56e3"
"HNSC-US/db321d2c-92a4-4d0a-8376-d88818ab5e66/PCAWG.4e9aae2e-ea49-4fba-bfaf-6b05a93fd3da"
"HNSC-US/bdffc6fb-0da3-47aa-ab87-66712732e0f6/PCAWG.251916ec-f78e-4eae-99fe-ff802e3ce2fe"
"LUSC-US/0e90fb64-00b2-4b53-bbc7-df8182b84060/PCAWG.394065e3-67f6-4d82-8ea6-ffc36fddb336"
"LUSC-US/7b1bc788-63b9-47ac-a6d5-ad65e2f4d307/PCAWG.3ca402f0-1e2b-4e5d-b12a-cbd5638ffdd6"
"STAD-US/32ad22d2-075a-46bb-a0cb-eaab5c48bf38/PCAWG.48b779ea-7651-4346-b6c7-414689670081"
"STAD-US/ada589d6-c2db-42c0-a927-7ddf0cb3de85/PCAWG.598eb33b-843a-4e15-b984-7afee6b1af9a"
"UCEC-US/b4c03bfa-fc41-4568-9006-0a2b2ba56ddf/PCAWG.c65990cd-c90c-4b5e-8192-683b5d41cbe6"
)




# Get index of processors
INDEX=$(( $PBS_ARRAYID -1 ))
#INDEX=4
#for INDEX in {0..46}
#do 

TUMOR=${TUMORS[$INDEX]}
GERM=${GERMS[$INDEX]}

echo $TUMOR.bam on `uname -n`

TUMOR_NAME=$(basename $(dirname $TUMOR))

mappingFileTumor=$DATADIR/${TUMOR}.bam

if [[ ! -z $GERM ]]; then
        GERM_NAME=$(basename $(dirname $GERM))
        SAMPLE_PAIR=${TUMOR_NAME}_vs_${GERM_NAME}
	mappingFileGerm=$DATADIR/${GERM}.bam
else
        SAMPLE_PAIR=${TUMOR_NAME}
	mappingFileGerm=""
fi

PROJECT_SAMPLE=$(echo $TUMOR | sed 's/\/.*//')

SAMPLE_PAIR=${TUMOR_NAME}

RESULTDIR_DEL=$RESULTDIR/delly/${PROJECT_SAMPLE}/${SAMPLE_PAIR}
RESULTDIR_DUP=$RESULTDIR/duppy/${PROJECT_SAMPLE}/${SAMPLE_PAIR}
RESULTDIR_INV=$RESULTDIR/invy/${PROJECT_SAMPLE}/${SAMPLE_PAIR}
RESULTDIR_TRANS=$RESULTDIR/jumpy/${PROJECT_SAMPLE}/${SAMPLE_PAIR}


if [ $TASK_DEL -eq 1 ]
then
	echo -e "\nDeletion calling on $SAMPLE_PAIR\n"
	mkdir -p $RESULTDIR_DEL
	if [[ $BREAKPOINT -eq 1 ]]; then
	    logFile=$RESULTDIR_DEL/${SAMPLE_PAIR}.deletions.bp.log
	    deletionFile=$RESULTDIR_DEL/${SAMPLE_PAIR}.deletions.bp.vcf
	    deletionFilePeDump=$RESULTDIR_DEL/${SAMPLE_PAIR}.deletions.bp.pe.dump.txt
	    deletionFilterFile=$RESULTDIR_DEL/${SAMPLE_PAIR}.deletions.bp.somatic.vcf
	    $DELLY -t DEL -x ${REF_EXCLUDE} -s 9 -g $REFGENOME -q 1 -p ${deletionFilePeDump} -o $deletionFile $mappingFileTumor $mappingFileGerm &> $logFile;
	else
	    logFile=$RESULTDIR_DEL/${SAMPLE_PAIR}.deletions.log
	    deletionFile=$RESULTDIR_DEL/${SAMPLE_PAIR}.deletions.vcf
	    deletionFilterFile=$RESULTDIR_DEL/${SAMPLE_PAIR}.deletions.somatic.vcf
	    deletionFilePeDump=$RESULTDIR_DEL/${SAMPLE_PAIR}.deletions.pe.dump.txt
	    $DELLY -t DEL -x ${REF_EXCLUDE} -s 9 -q 1 -p ${deletionFilePeDump} -o $deletionFile $mappingFileTumor $mappingFileGerm &> $logFile;
	fi
	if [[ -f ${deletionFile} || -f ${deletionFile/.vcf/.vcf.gz} ]]; then
		deletionBEDPE=${deletionFile/.vcf/.bedpe.txt}
		deletionFilterBEDPE=${deletionFilterFile/.vcf/.bedpe.txt}
		if [[ $SOMATIC_FILTERING -eq 1 ]]; then
			echo "running somatic filtering"
			$SOMATIC_FILTER -v ${deletionFile} -o $deletionFilterFile  &>> $logFile;
			for vcfFile in $(ls ${deletionFile/.vcf/}* | grep -P '.vcf$|.vcf.gz$')
			do
				echo $vcfFile
				$DELLY2BED -v ${vcfFile} -o ${vcfFile/.vcf*/.bedpe.txt} -g ${GENCODE}
			done
			echo -e "\n\nparsing read names from bam file for downstream merging\n"
			deletionFileReadNameTumor=$RESULTDIR_DEL/${SAMPLE_PAIR}.deletions.somatic.readname.txt
			bash ${PEDUMP} ${deletionFilterFile} ${deletionFilePeDump} ${mappingFileTumor} > ${deletionFileReadNameTumor}
			deletionFileReadNameGerm=$RESULTDIR_DEL/${SAMPLE_PAIR}.deletions.germline.readname.txt
			bash ${PEDUMP} ${deletionFilterFile/.somatic/.germline} ${deletionFilePeDump} ${mappingFileGerm} > ${deletionFileReadNameGerm}			
		fi
	fi
fi

if [ $TASK_DUP -eq 1 ]
then
    echo -e "\nDuplication calling on $SAMPLE_PAIR\n"
    mkdir -p $RESULTDIR_DUP

    if [[ $BREAKPOINT -eq 1 ]]; then
	    logFile=$RESULTDIR_DUP/${SAMPLE_PAIR}.duplications.bp.log
	    duplicationFile=$RESULTDIR_DUP/${SAMPLE_PAIR}.duplications.bp.vcf
	    duplicationFilterFile=$RESULTDIR_DUP/${SAMPLE_PAIR}.duplications.bp.somatic.vcf
      	    duplicationFilePeDump=$RESULTDIR_DUP/${SAMPLE_PAIR}.duplications.bp.pe.dump.txt
	    $DELLY -t DUP -x ${REF_EXCLUDE} -g $REFGENOME -q 1 -p ${duplicationFilePeDump} -o $duplicationFile $mappingFileTumor $mappingFileGerm &> $logFile;

    else
	    logFile=$RESULTDIR_DUP/${SAMPLE_PAIR}.duplications.log
	    duplicationFile=$RESULTDIR_DUP/${SAMPLE_PAIR}.duplications.vcf
	    duplicationFilterFile=$RESULTDIR_DUP/${SAMPLE_PAIR}.duplications.somatic.vcf
  	    duplicationFilePeDump=$RESULTDIR_DUP/${SAMPLE_PAIR}.duplications.pe.dump.txt
	    $DELLY -t DUP -x ${REF_EXCLUDE} -q 1 -p ${duplicationFilePeDump} -o $duplicationFile $mappingFileTumor $mappingFileGerm &> $logFile;

    fi
	if [[ -f ${duplicationFile} || -f ${duplicationFile/.vcf/.vcf.gz} ]]; then
		duplicationBEDPE=${duplicationFile/.vcf/.bedpe.txt}
		duplicationFilterBEDPE=${duplicationFilterFile/.vcf/.bedpe.txt}
		if [[ $SOMATIC_FILTERING -eq 1 ]]; then
			echo "running somatic filtering"
			$SOMATIC_FILTER -v ${duplicationFile} -o $duplicationFilterFile  &>> $logFile;
			for vcfFile in $(ls ${duplicationFile/.vcf/}* | grep -P '.vcf$|.vcf.gz$')
			do
				echo $vcfFile
				$DELLY2BED -v ${vcfFile} -o ${vcfFile/.vcf*/.bedpe.txt} -g ${GENCODE}
			done
			echo -e "\n\nparsing read names from bam file for downstream merging\n"
			duplicationFileReadNameTumor=$RESULTDIR_DUP/${SAMPLE_PAIR}.duplications.somatic.readname.txt
			bash ${PEDUMP} ${duplicationFilterFile} ${duplicationFilePeDump} ${mappingFileTumor} > ${duplicationFileReadNameTumor}
			duplicationFileReadNameGerm=$RESULTDIR_DUP/${SAMPLE_PAIR}.duplications.germline.readname.txt
			bash ${PEDUMP} ${duplicationFilterFile/.somatic/.germline} ${duplicationFilePeDump} ${mappingFileGerm} > ${duplicationFileReadNameGerm}						
		fi
	fi
fi



if [ $TASK_INV -eq 1 ]
then
    echo -e "\nInversion calling on $SAMPLE_PAIR\n"
    mkdir -p $RESULTDIR_INV


    if [[ $BREAKPOINT -eq 1 ]]; then
	    logFile=$RESULTDIR_INV/${SAMPLE_PAIR}.inversions.bp.log
	    inversionFile=$RESULTDIR_INV/${SAMPLE_PAIR}.inversions.bp.vcf
	    inversionFilterFile=$RESULTDIR_INV/${SAMPLE_PAIR}.inversions.bp.somatic.vcf
 	    inversionFilePeDump=$RESULTDIR_INV/${SAMPLE_PAIR}.inversions.bp.pe.dump.txt
	    $DELLY -t INV -x ${REF_EXCLUDE} -g $REFGENOME -q 10 -p ${inversionFilePeDump} -o $inversionFile $mappingFileTumor $mappingFileGerm &> $logFile;

    else
	    logFile=$RESULTDIR_INV/${SAMPLE_PAIR}.inversions.log
	    inversionFile=$RESULTDIR_INV/${SAMPLE_PAIR}.inversions.vcf
	    inversionFilterFile=$RESULTDIR_INV/${SAMPLE_PAIR}.inversions.somatic.vcf
   	    inversionFilePeDump=$RESULTDIR_INV/${SAMPLE_PAIR}.inversions.pe.dump.txt
	    $DELLY -t INV -x ${REF_EXCLUDE} -q 1 -p ${inversionFilePeDump} -o $inversionFile $mappingFileTumor $mappingFileGerm &> $logFile;

    fi
	if [[ -f ${inversionFile} || -f ${inversionFile/.vcf/.vcf.gz} ]]; then
		inversionBEDPE=${inversionFile/.vcf/.bedpe.txt}
		inversionFilterBEDPE=${inversionFilterFile/.vcf/.bedpe.txt}
		if [[ $SOMATIC_FILTERING -eq 1 ]]; then
			echo "running somatic filtering"
			$SOMATIC_FILTER -v ${inversionFile} -o $inversionFilterFile  &>> $logFile;
			for vcfFile in $(ls ${inversionFile/.vcf/}* | grep -P '.vcf$|.vcf.gz$')
			do
				echo $vcfFile
				$DELLY2BED -v ${vcfFile} -o ${vcfFile/.vcf*/.bedpe.txt} -g ${GENCODE}
			done
			echo -e "\n\nparsing read names from bam file for downstream merging\n"
			inversionFileReadNameTumor=$RESULTDIR_INV/${SAMPLE_PAIR}.inversions.somatic.readname.txt
			bash ${PEDUMP} ${inversionFilterFile} ${inversionFilePeDump} ${mappingFileTumor} > ${inversionFileReadNameTumor}
			inversionFileReadNameGerm=$RESULTDIR_INV/${SAMPLE_PAIR}.inversions.germline.readname.txt
			bash ${PEDUMP} ${inversionFilterFile/.somatic/.germline} ${inversionFilePeDump} ${mappingFileGerm} > ${inversionFileReadNameGerm}					
		fi
	fi
fi


if [ $TASK_TRANS -eq 1 ]
then
    echo -e "\nTranslocation calling on $SAMPLE_PAIR\n"
    mkdir -p $RESULTDIR_TRANS


    if [[ $BREAKPOINT -eq 1 ]]; then
	    logFile=$RESULTDIR_TRANS/${SAMPLE_PAIR}.translocations.bp.log
	    translocationFile=$RESULTDIR_TRANS/${SAMPLE_PAIR}.translocations.bp.vcf
	    translocationFilterFile=$RESULTDIR_TRANS/${SAMPLE_PAIR}.translocations.bp.somatic.vcf
	    translocationFilePeDump=$RESULTDIR_TRANS/${SAMPLE_PAIR}.translocations.bp.pe.dump.txt
	    $DELLY -t TRA -x ${REF_EXCLUDE} -g $REFGENOME -q 1 -p ${translocationFilePeDump} -o $translocationFile $mappingFileTumor $mappingFileGerm &> $logFile;
    else
	    logFile=$RESULTDIR_TRANS/${SAMPLE_PAIR}.translocations.log
	    translocationFile=$RESULTDIR_TRANS/${SAMPLE_PAIR}.translocations.vcf
	    translocationFilterFile=$RESULTDIR_TRANS/${SAMPLE_PAIR}.translocations.somatic.vcf
	    translocationFilePeDump=$RESULTDIR_TRANS/${SAMPLE_PAIR}.translocations.pe.dump.txt	    
	    $DELLY -t TRA -x ${REF_EXCLUDE} -q 1 -p ${translocationFilePeDump} -o $translocationFile $mappingFileTumor $mappingFileGerm &> $logFile;
    fi
	if [[ -f ${translocationFile} || -f ${translocationFile/.vcf/.vcf.gz} ]]; then
		translocationBEDPE=${translocationFile/.vcf/.bedpe.txt}
		translocationFilterBEDPE=${translocationFilterFile/.vcf/.bedpe.txt}
		if [[ $SOMATIC_FILTERING -eq 1 ]]; then
			echo "running somatic filtering"
			$SOMATIC_FILTER -v ${translocationFile} -o $translocationFilterFile  &>> $logFile;
			for vcfFile in $(ls ${translocationFile/.vcf/}* | grep -P '.vcf$|.vcf.gz$')
			do
				echo $vcfFile
				$DELLY2BED -v ${vcfFile} -o ${vcfFile/.vcf*/.bedpe.txt} -g ${GENCODE}
			done	
			echo -e "\n\nparsing read names from bam file for downstream merging\n"
			translocationFileReadNameTumor=$RESULTDIR_TRANS/${SAMPLE_PAIR}.translocations.somatic.readname.txt
			bash ${PEDUMP} ${translocationFilterFile} ${translocationFilePeDump} ${mappingFileTumor} > ${translocationFileReadNameTumor}
			translocationFileReadNameGerm=$RESULTDIR_TRANS/${SAMPLE_PAIR}.translocations.germline.readname.txt
			bash ${PEDUMP} ${translocationFilterFile/.somatic/.germline} ${translocationFilePeDump} ${mappingFileGerm} > ${translocationFileReadNameGerm}				
		fi
	fi


fi

date

