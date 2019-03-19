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
  dockerPull: quay.io/pancancer/pcawg_delly_workflow:2.0.4

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
    secondaryFiles:
    - .bai
  normal-bam:
    type: File
    inputBinding:
      position: 2
      prefix: --normal-bam
    secondaryFiles:
    - .bai
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
    secondaryFiles:
    - .md5
    - .tbi
    - .tbi.md5
  germline_sv_vcf:
    type: File
    outputBinding:
      glob: '*.germline.sv.vcf.gz'
    secondaryFiles:
    - .md5
    - .tbi
    - .tbi.md5
  sv_vcf:
    type: File
    outputBinding:
      glob: '*[0-9].sv.vcf.gz'
    secondaryFiles:
    - .md5
    - .tbi
    - .tbi.md5
  somatic_bedpe:
    type: File
    outputBinding:
      glob: '*.somatic.sv.bedpe.txt'
    secondaryFiles:
    - .md5
  somatic_bedpe_tar_gz:
    type: File
    outputBinding:
      glob: '*.somatic.sv.bedpe.txt.tar.gz'
    secondaryFiles:
    - .md5
  germline_bedpe:
    type: File
    outputBinding:
      glob: '*.germline.sv.bedpe.txt'
    secondaryFiles:
    - .md5
  germline_bedpe_tar_gz:
    type: File
    outputBinding:
      glob: '*.germline.sv.bedpe.txt.tar.gz'
    secondaryFiles:
    - .md5
  somatic_sv_readname:
    type: File
    outputBinding:
      glob: '*.somatic.sv.readname.txt.tar.gz'
    secondaryFiles:
    - .md5
  germline_sv_readname:
    type: File
    outputBinding:
      glob: '*.germline.sv.readname.txt.tar.gz'
    secondaryFiles:
    - .md5
  cov:
    type: File
    outputBinding:
      glob: '*.sv.cov.tar.gz'
    secondaryFiles:
    - .md5
  cov_plots:
    type: File
    outputBinding:
      glob: '*.sv.cov.plots.tar.gz'
    secondaryFiles:
    - .md5
  sv_log:
    type: File
    outputBinding:
      glob: '*.sv.log.tar.gz'
    secondaryFiles:
    - .md5
  sv_qc:
    type: File
    outputBinding:
      glob: 'sv.qc_metrics.tar.gz'
    secondaryFiles:
    - .md5
  sv_timing:
    type: File
    outputBinding:
      glob: 'sv.timing_metrics.tar.gz'
    secondaryFiles:
    - .md5

baseCommand: [/start.sh, perl, /usr/bin/run_seqware_workflow.pl]
doc: |
    PCAWG EMBL variant calling workflow is developed by European Molecular Biology Laboratory at Heidelberg
    (EMBL, https://www.embl.de), it consists of software components calling structural
    variants using uniformly aligned tumor / normal WGS sequences. The workflow has been dockerized and packaged
    using CWL workflow language, the source code is available on GitHub at:
    https://github.com/ICGC-TCGA-PanCancer/pcawg_delly_workflow.


    ## Run the workflow with your own data

    ### Prepare compute environment and install software packages
    The workflow has been tested in Ubuntu 16.04 Linux environment with the following hardware and software settings.

    #### Hardware requirement (assuming 30X coverage whole genome sequence)
    - CPU core: 16
    - Memory: 64GB
    - Disk space: 1TB

    #### Software installation
    - Docker (1.12.6): follow instructions to install Docker https://docs.docker.com/engine/installation
    - CWL tool
    ```
    pip install cwltool==1.0.20170217172322
    ```

    ### Prepare input data
    #### Input aligned tumor / normal BAM files

    The workflow uses a pair of aligned BAM files as input, one BAM for tumor, the other for normal, both
    from the same donor. Here we assume file names are *tumor_sample.bam* and *normal_sample.bam*, and are
    under *bams* subfolder.

    #### Reference data file

    The workflow also uses one precompiled reference files as input, they can be downloaded from the ICGC Data
    Portal at https://dcc.icgc.org/releases/PCAWG/reference_data/pcawg-dkfz. We assume the reference file is
    under *reference* subfolder.

    #### Job JSON file for CWL

    Finally, we need to prepare a JSON file with input, reference and output files specified. Please replace
    the *tumor* and *normal* parameters with your real BAM file names. Parameters for output are file name
    suffixes, usually don't need to be changed.

    Name the JSON file: *pcawg-delly-sv-caller.job.json*
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

    ### Run the workflow
    #### Option 1: Run with CWL tool
    - Download CWL workflow definition file
    ```
    wget -O pcawg-delly-sv-caller.cwl "https://raw.githubusercontent.com/ICGC-TCGA-PanCancer/pcawg_delly_workflow/2.0.1-cwl1.0/delly_docker/Dockstore.cwl"
    ```

    - Run `cwltool` to execute the workflow
    ```
    nohup cwltool --debug --non-strict pcawg-delly-sv-caller.cwl pcawg-delly-sv-caller.job.json > pcawg-delly-sv-caller.log 2>&1 &
    ```

    #### Option 2: Run with the Dockstore CLI
    See the *Launch with* section below for details.
