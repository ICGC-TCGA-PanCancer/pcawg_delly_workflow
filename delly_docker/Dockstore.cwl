#!/usr/bin/env cwl-runner

class: CommandLineTool
id: "Seqware-Delly-Workflow"
label: "Seqware-Delly-Workflow"

description: |
    ![pcawg logo](https://dcc.icgc.org/styles/images/PCAWG-final-small.png "pcawg logo")
    #PCAWG DELLY Workflow
    The DELLY workflow from the ICGC PanCancer Analysis of Whole Genomes (PCAWG) project. For more information see the PCAWG project [page](https://dcc.icgc.org/pcawg) and our GitHub
    [page](https://github.com/ICGC-TCGA-PanCancer) for our code including the source for
    [this workflow](https://github.com/ICGC-TCGA-PanCancer/pcawg_delly_workflow).
    ```
    Usage:
    # fetch CWL
    $> dockstore cwl --entry quay.io/pancancer/pcawg-delly-workflow:2.0.0 > Dockstore.cwl
    # make a runtime JSON template and edit it
    $> dockstore convert cwl2json --cwl Dockstore.cwl > Dockstore.json
    # run it locally with the Dockstore CLI
    $> dockstore launch --entry quay.io/pancancer/pcawg-delly-workflow:2.0.0 \
        --json Dockstore.json
    ```

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
    dockerPull: pancancer/pcawg-delly-workflow:2.0.0

inputs:
  - id: "#reads"
    type:
      type: array
      items: File
    inputBinding:
      position: 1
      prefix: "--file"

outputs:
  - id: "#bam"
    type: array
    items: File
    outputBinding:
      glob: ["*.bam", "*.bai"]

baseCommand: ["perl", "/usr/bin/run_seqware_workflow.pl"]
