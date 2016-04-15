# DELLY Workflow for PanCancer Analysis of Whole Genomes (PCAWG)

![Alt text](img/PCAWG-final-small.png "Optional title")

[![Build Status](https://travis-ci.org/ICGC-TCGA-PanCancer/pcawg_delly_workflow.svg?branch=master)](https://travis-ci.org/ICGC-TCGA-PanCancer/pcawg_delly_workflow) [![Docker Repository on Quay](https://quay.io/repository/pancancer/pcawg-sanger-cgp-workflow/status "Docker Repository on Quay")](https://quay.io/repository/pancancer/pcawg-sanger-cgp-workflow)

A [Dockstore](http://dockstore.org) version of the DELLY and COV workflow used by the PCAWG project. This is a cleaned up version with PCAWG-specific components removed and designed to be easier to call. See [Pancancer.info](http://pancancer.info) and the [PCAWG ICGC portal](https://dcc.icgc.org/pcawg) for more information about this project and how to access its results. The underlying workflow has been written using [SeqWare 1.1.1](http://seqware.io).

The workflow consists of two main tools:

### DELLY

[DELLY](https://github.com/tobiasrausch/delly) is an integrated structural variant prediction method that can detect deletions, tandem duplications, inversions and translocations at single-nucleotide resolution in short-read massively parallel sequencing data. It uses paired-ends and split-reads to sensitively and accurately delineate genomic rearrangements throughout the genome.

### COV

Genome-wide coverage analysis and Depth of Coverage plotting, comparing tumor-normal

## Authors

Email Brian if you have questions.  Joachim was the primary author.

* Joachim Weischenfeldt (primary workflow author) <joachim.weischenfeldt@embl.de>
* Ivica Letunic (Dockerfile) <letunic@biobyte.de>
* Brian O'Connor <briandoconnor@gmail.com>
* Solomon Shorser <Solomon.Shorser@oicr.on.ca>

## Building

You need Docker installed in order to perform this build.

    cd delly_docker
    docker build -t pancancer/pcawg-delly-workflow:2.0.0 .

Alternatively, you can view the entry on [Dockstore](https://www.dockstore.org/containers/quay.io/pancancer/pcawg-delly-workflow) to use a pre-built image.

## Hardware Requirements

This workflow recommends:

* 16-32 cores
* 4.5G per core, so, ideally 72GB+ for 16 cores, for 32 cores 144GB+, on Amazon we recommend r3.8xlarge or r3.4xlarge
* 1TB of local disk space

## Running

You can use the Dockstore command line to simplify calling this workflow.  If you prefer to call the workflow directly using Docker see the output from the commands below.  For a parameterization using test data see our sample [Dockstore.json](https://github.com/ICGC-TCGA-PanCancer/pcawg_delly_workflow/blob/develop/delly_docker/Delly.json) hosted in GitHub.

    Usage:
    # fetch CWL
    $> dockstore cwl --entry quay.io/pancancer/pcawg-delly-workflow:2.0.0 > Dockstore.cwl
    # make a runtime JSON template and edit it
    $> dockstore convert cwl2json --cwl Dockstore.cwl > Dockstore.json
    # run it locally with the Dockstore CLI
    $> dockstore launch --entry quay.io/pancancer/pcawg-delly-workflow:2.0.0 \
        --json Dockstore.json

## See Also

These resources are based on a mirror of the original [bitbucket repository](https://bitbucket.org/weischen/pcawg-delly-workflow) to [Github](https://github.com/ICGC-TCGA-PanCancer/pcawg_delly_workflow).
