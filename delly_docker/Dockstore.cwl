#!/usr/bin/env cwl-runner

class: CommandLineTool
id: Seqware-Delly-Workflow
label: Seqware-Delly-Workflow
cwlVersion: v1.0

dct:creator:
  '@id': http://orcid.org/0000-0002-7681-6415
  foaf:name: Brian O'Connor
  foaf:mbox: mailto:briandoconnor@gmail.com

dct:contributor:
  foaf:name: Denis Yuen
  foaf:mbox: mailto:denis.yuen@oicr.on.ca
  
requirements:
- class: DockerRequirement
  dockerPull: quay.io/pancancer/pcawg_delly_workflow:2.0.1-cwl1.0

inputs:
  run-id:
    type: string
    inputBinding:
      position: 1
      prefix: --run-id
  reference-gc:
    type: File
    inputBinding:
      position: 5
      prefix: --reference-gc
  tumor-bam:
    type: File
    inputBinding:
      position: 3
      prefix: --tumor-bam
  normal-bam:
    type: File
    inputBinding:
      position: 2
      prefix: --normal-bam
  reference-gz:
    type: File
    inputBinding:
      position: 4
      prefix: --reference-gz
outputs:
  somatic_sv_vcf:
    type: File
    outputBinding:
      glob: '*.somatic.sv.vcf.gz'
  cov_plots:
    type: File
    outputBinding:
      glob: '*.sv.cov.plots.tar.gz'
  cov:
    type: File
    outputBinding:
      glob: '*.sv.cov.tar.gz'
  somatic_bedpe:
    type: File
    outputBinding:
      glob: '*.somatic.sv.bedpe.txt'
  germline_bedpe:
    type: File
    outputBinding:
      glob: '*.germline.sv.bedpe.txt'
  sv_log:
    type: File
    outputBinding:
      glob: '*.sv.log.tar.gz'
  sv_timing:
    type: File
    outputBinding:
      glob: '*.sv.timing.json'
  sv_qc:
    type: File
    outputBinding:
      glob: '*.sv.qc.json'
  germline_sv_vcf:
    type: File
    outputBinding:
      glob: '*.germline.sv.vcf.gz'
baseCommand: [/start.sh, perl, /usr/bin/run_seqware_workflow.pl]
doc: |
  ![pcawg logo](https://raw.githubusercontent.com/ICGC-TCGA-PanCancer/pcawg_delly_workflow/2.0.0/img/PCAWG-final-small.png "pcawg logo")

  **PCAWG DELLY Workflow**

  The DELLY workflow from the ICGC PanCancer Analysis of Whole Genomes (PCAWG) project. For more information see the PCAWG project [page](https://dcc.icgc.org/pcawg) and our GitHub
  [page](https://github.com/ICGC-TCGA-PanCancer) for our code including the source for
  [this workflow](https://github.com/ICGC-TCGA-PanCancer/pcawg_delly_workflow).

  *Usage:*

  Use this sample [Dockstore.json](https://raw.githubusercontent.com/ICGC-TCGA-PanCancer/pcawg_delly_workflow/2.0.0/delly_docker/Dockstore.json) with public URLs for sample data.

