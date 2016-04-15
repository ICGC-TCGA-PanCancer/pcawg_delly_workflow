# DELLY Workflow for PanCancer Analysis of Whole Genomes (PCAWG)

[![Build Status](https://travis-ci.org/ICGC-TCGA-PanCancer/pcawg_delly_workflow.svg?branch=master)](https://travis-ci.org/ICGC-TCGA-PanCancer/pcawg_delly_workflow) [![Docker Repository on Quay](https://quay.io/repository/pancancer/pcawg-sanger-cgp-workflow/status "Docker Repository on Quay")](https://quay.io/repository/pancancer/pcawg-sanger-cgp-workflow)

A [Dockstore](http://dockstore.org) version of the DELLY and COV workflow used by the PCAWG project. This is a cleaned up version with PCAWG-specific components removed and designed to be easier to call. See [Pancancer.info](http://pancancer.info) and the [PCAWG ICGC portal](https://dcc.icgc.org/pcawg) for more information about this project and how to access its results. The underlying workflow has been written using [SeqWare 1.1.1](http://seqware.io).

The workflow consists of two main tools:

### [DELLY](https://github.com/tobiasrausch/delly)

DELLY is an integrated structural variant prediction method that can detect deletions, tandem duplications, inversions and translocations at single-nucleotide resolution in short-read massively parallel sequencing data. It uses paired-ends and split-reads to sensitively and accurately delineate genomic rearrangements throughout the genome.

### COV

Genome-wide coverage analysis and Depth of Coverage plotting, comparing tumor-normal

## Authors

Email Brian if you have questions.  Joachim was the primary author.

* Joachim Weischenfeldt (primary author)
* Brian O'Connor <briandoconnor@gmail.com>
* Solomon Shorser

## Building

    cd delly_docker
    docker build -t pancancer/pcawg-delly-workflow:1.4 .

## Hardware Requirements

This workflow recommends:

* 16-32 cores
* 4.5G per core, so, ideally 72GB+ for 16 cores, for 32 cores 144GB+, on Amazon we recommend r3.8xlarge or r3.4xlarge
* 1TB of local disk space

## See Also

These resources are based on a mirror of the original [bitbucket repository](https://bitbucket.org/weischen/pcawg-delly-workflow) on [Github](https://github.com/ICGC-TCGA-PanCancer/pcawg_delly_workflow)
*
* [Docker Hub Automated Build](https://registry.hub.docker.com/u/pancancer/pcawg-delly-workflow/)
