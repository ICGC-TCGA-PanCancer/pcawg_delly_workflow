# DELLY Workflow for Pan Cancer Analysis of Whole Genomes (PCAWG)

The workflow consists of two main workflows:

- *DELLY* variant calling

- *COV* Coverage analysis

## [DELLY](https://github.com/tobiasrausch/delly)

DELLY is an integrated structural variant prediction method that can detect deletions, tandem duplications, inversions and translocations at single-nucleotide resolution in short-read massively parallel sequencing data. It uses paired-ends and split-reads to sensitively and accurately delineate genomic rearrangements throughout the genome.

## COV

Genome-wide coverage analysis and Depth of Coverage plotting, comparing tumor-normal

## Building

    docker build -t pancancer/pcawg-delly-workflow:1.3 . 

## See Also

These resources are based on a mirror of the original [bitbucket repository](https://bitbucket.org/weischen/pcawg-delly-workflow) on [Github](https://github.com/ICGC-TCGA-PanCancer/pcawg_delly_workflow)
* [![Build Status](https://travis-ci.org/ICGC-TCGA-PanCancer/pcawg_delly_workflow.svg?branch=master)](https://travis-ci.org/ICGC-TCGA-PanCancer/pcawg_delly_workflow)
* [Docker Hub Automated Build](https://registry.hub.docker.com/u/pancancer/pcawg-delly-workflow/)
