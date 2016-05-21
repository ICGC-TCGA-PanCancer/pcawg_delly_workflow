#!/usr/bin/env cwl-runner

class: CommandLineTool
id: "Seqware-Delly-Workflow"
label: "Seqware-Delly-Workflow"

description: |
    ![pcawg logo](https://raw.githubusercontent.com/ICGC-TCGA-PanCancer/pcawg_delly_workflow/2.0.0/img/PCAWG-final-small.png "pcawg logo")

    **PCAWG DELLY Workflow**

    The DELLY workflow from the ICGC PanCancer Analysis of Whole Genomes (PCAWG) project. For more information see the PCAWG project [page](https://dcc.icgc.org/pcawg) and our GitHub
    [page](https://github.com/ICGC-TCGA-PanCancer) for our code including the source for
    [this workflow](https://github.com/ICGC-TCGA-PanCancer/pcawg_delly_workflow).

    *Usage:*

    ```
    # fetch CWL
    $> dockstore tool cwl --entry quay.io/pancancer/pcawg_delly_workflow:2.0.0 > Dockstore.cwl
    # make a runtime JSON template and edit it
    $> dockstore tool convert cwl2json --cwl Dockstore.cwl > Dockstore.json
    # run it locally with the Dockstore CLI
    $> dockstore tool launch --entry quay.io/pancancer/pcawg_delly_workflow:2.0.0 \
        --json Dockstore.json
    ```
    Also see this sample [Dockstore.json](https://raw.githubusercontent.com/ICGC-TCGA-PanCancer/pcawg_delly_workflow/2.0.0/delly_docker/Dockstore.json) with public URLs for sample data.

dct:creator:
  "@id": "http://orcid.org/0000-0002-7681-6415"
  foaf:name: "Brian O'Connor"
  foaf:mbox: "mailto:briandoconnor@gmail.com"

requirements:
  - class: ExpressionEngineRequirement
    id: "#node-engine"
    requirements:
    - class: DockerRequirement
      dockerPull: commonworkflowlanguage/nodejs-engine
    engineCommand: cwlNodeEngine.js
  - class: DockerRequirement
    dockerPull: quay.io/pancancer/pcawg_delly_workflow:2.0.0

inputs:
  - id: "#run-id"
    type: string
    inputBinding:
      position: 1
      prefix: "--run-id"
  - id: "#normal-bam"
    type: File
    inputBinding:
      position: 2
      prefix: "--normal-bam"
  - id: "#tumor-bam"
    type: File
    inputBinding:
      position: 3
      prefix: "--tumor-bam"
  - id: "#reference-gz"
    type: File
    inputBinding:
      position: 4
      prefix: "--reference-gz"
  - id: "#reference-gc"
    type: File
    inputBinding:
      position: 5
      prefix: "--reference-gc"

outputs:
  - id: "#somatic_sv_vcf"
    type: File
    outputBinding:
      glob: "*.somatic.sv.vcf.gz"
  - id: "#somatic_bedpe"
    type: File
    outputBinding:
      glob: "*.somatic.sv.bedpe.txt"
  - id: "#cov"
    type: File
    outputBinding:
      glob: "*.sv.cov.tar.gz"
  - id: "#cov_plots"
    type: File
    outputBinding:
      glob: "*.sv.cov.plots.tar.gz"
  - id: "#germline_sv_vcf"
    type: File
    outputBinding:
      glob: "*.germline.sv.vcf.gz"
  - id: "#germline_bedpe"
    type: File
    outputBinding:
      glob: "*.germline.sv.bedpe.txt"
  - id: "#sv_log"
    type: File
    outputBinding:
      glob: "*.sv.log.tar.gz"
  - id: "#sv_timing"
    type: File
    outputBinding:
      glob: "*.sv.timing.json"
  - id: "#sv_qc"
    type: File
    outputBinding:
      glob: "*.sv.qc.json"

baseCommand: ["perl", "/usr/bin/run_seqware_workflow.pl"]