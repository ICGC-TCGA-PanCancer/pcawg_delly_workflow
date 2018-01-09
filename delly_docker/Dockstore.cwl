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
  dockerPull: quay.io/pancancer/pcawg_delly_workflow:feature_gosu_and_icgc_portal

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
  PCAWG EMBL variant calling workflow is developed by European Molecular Biology Laboratory at Heidelberg (EMBL, [https://www.embl.de](https://www.embl.de)), it consists of software components calling structural variants using uniformly aligned tumor / normal WGS sequences. The workflow has been dockerized and packaged using CWL workflow language, the source code is available on GitHub at: [https://github.com/ICGC-TCGA-PanCancer/pcawg_delly_workflow](https://github.com/ICGC-TCGA-PanCancer/pcawg_delly_workflow). The workflow is also registered in Dockstore at: [https://dockstore.org/containers/quay.io/pancancer/pcawg_delly_workflow](https://dockstore.org/containers/quay.io/pancancer/pcawg_delly_workflow).


    ## Run the workflow with your own data
    
    ### Prepare compute environment and install software packages
    The workflow has been tested in Ubuntu 16.04 Linux environment with the following hardware and software settings.
    
    1. Hardware requirement (assuming X30 coverage whole genome sequence)
    - CPU core: 16
    - Memory: 64GB
    - Disk space: 1TB
    
    2. Software installation
    - Docker (1.12.6): follow instructions to install Docker https://docs.docker.com/engine/installation
    - CWL tool
    ```
    pip install cwltool==1.0.20170217172322
    ```
    
    ### Prepare input data
    1. Input aligned tumor / normal BAM files
    
    The workflow uses a pair of aligned BAM files as input, one BAM for tumor, the other for normal, both from the same donor. Here we assume file names are `tumor_sample.bam` and `normal_sample.bam`, and both files are under `bams` subfolder.
    
    2. Reference data file
    
    The workflow also uses one precompiled reference files as input, they can be downloaded from the ICGC Data Portal at [https://dcc.icgc.org/releases/PCAWG/reference_data/pcawg-dkfz](https://dcc.icgc.org/releases/PCAWG/reference_data/pcawg-dkfz). We assume the reference file is under `reference` subfolder. 
    
    3. Job JSON file for CWL
    
    Finally, we need to prepare a JSON file with input, reference and output files specified. Please replace the `tumor` and `normal` parameters with your real BAM file names. Parameters for output are file name suffixes, usually don't need to be changed.
    
    Name the JSON file: `pcawg-delly-sv-caller.job.json`
    ```
    {
      "run-id": "run_id",
      "tumor-bam": {
        "path":"bams/tumor_sample.bam",
        "class":"File"
      },
      "normal-bam": {
        "path":"bams/normal_sample.bam",
        "class":"File"
      },
      "reference-gz": {
        "path": "https://dcc.icgc.org/api/v1/download?fn=/PCAWG/reference_data/pcawg-bwa-mem/genome.fa.gz",
        "class": "File"
      },
      "reference-gc": {
        "path": "https://dcc.icgc.org/api/v1/download?fn=/PCAWG/reference_data/pcawg-delly/hs37d5_1000GP.gc",
        "class": "File"
      },
      "somatic_sv_vcf": {
        "path":"delly.somatic.sv.vcf.gz",
        "class":"File"
      },
      "somatic_bedpe": {
        "path":"delly.somatic.sv.bedpe.txt",
        "class":"File"
      },
      "cov": {
        "path":"delly.sv.cov.tar.gz",
        "class":"File"
      },
      "cov_plots": {
        "path":"delly.sv.cov.plots.tar.gz",
        "class":"File"
      },
      "germline_sv_vcf": {
        "path":"delly.germline.sv.vcf.gz",
        "class":"File"
      },
      "germline_bedpe": {
        "path":"delly.germline.sv.bedpe.txt",
        "class":"File"
      },
      "sv_log": {
        "path":"delly.sv.log.tar.gz",
        "class":"File"
      },
      "sv_timing": {
        "path":"delly.sv.timing.json",
        "class":"File"
      },
      "sv_qc": {
        "path":"delly.sv.qc.json",
        "class":"File"
      }
    }
    ```

