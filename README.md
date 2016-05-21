![pcawg logo](img/PCAWG-final-small.png "pcawg logo")

#PCAWG DELLY Workflow

[![Build Status](https://travis-ci.org/ICGC-TCGA-PanCancer/pcawg_delly_workflow.svg?branch=master)](https://travis-ci.org/ICGC-TCGA-PanCancer/pcawg_delly_workflow) [![Docker Repository on Quay](https://quay.io/repository/pancancer/pcawg-sanger-cgp-workflow/status "Docker Repository on Quay")](https://quay.io/repository/pancancer/pcawg-sanger-cgp-workflow)

A [Dockstore](http://dockstore.org) version of the DELLY and COV workflow used by the PCAWG project. This is a cleaned up version with PCAWG-specific components removed and designed to be easier to call through the use of the [Dockstore](http://dockstore.org). See [Pancancer.info](http://pancancer.info) and the [PCAWG ICGC portal](https://dcc.icgc.org/pcawg) for more information about this project and how to access its results. The underlying workflow has been written using [SeqWare 1.1.1](http://seqware.io).

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
    docker build -t quay.io/pancancer/pcawg_delly_workflow:2.0.0 .

Alternatively, you can view the entry on [Dockstore](https://www.dockstore.org/containers/quay.io/pancancer/pcawg_delly_workflow) to use a pre-built image.

## Hardware Requirements

This workflow recommends:

* 16-32 cores
* 4.5G per core, so, ideally 72GB+ for 16 cores, for 32 cores 144GB+, on Amazon we recommend r3.8xlarge or r3.4xlarge
* 1TB of local disk space (depends on the input genome size)

## Sample Data

Non-controlled access sample BAM files can be found here:

* [https://s3-eu-west-1.amazonaws.com/wtsi-pancancer/testdata/HCC1143_ds.tar](https://s3-eu-west-1.amazonaws.com/wtsi-pancancer/testdata/HCC1143_ds.tar)

And the two needed reference files can be found here:

* [https://s3.amazonaws.com/pan-cancer-data/pan-cancer-reference/genome.fa.gz](https://s3.amazonaws.com/pan-cancer-data/pan-cancer-reference/genome.fa.gz)
* [https://s3.amazonaws.com/pan-cancer-data/pan-cancer-reference/hs37d5_1000GP.gc](https://s3.amazonaws.com/pan-cancer-data/pan-cancer-reference/hs37d5_1000GP.gc)

For sample parameters (a sample Dockstore.json in the command below) see [Dockstore.json](delly_docker/Dockstore.json).
Make sure you customize this to reflect whatever local paths you downloaded and extracted
the above sample BAM files to.

## Running

You can use the Dockstore command line to simplify calling this workflow.  If you prefer to call the workflow directly using Docker see the output from the commands below.  For a parameterization using test data see our sample [Dockstore.json](https://github.com/ICGC-TCGA-PanCancer/pcawg_delly_workflow/blob/develop/delly_docker/Delly.json) hosted in GitHub and the note above.

*Usage:*

    # fetch CWL
    $> dockstore tool cwl --entry quay.io/pancancer/pcawg_delly_workflow:2.0.0 > Dockstore.cwl
    # make a runtime JSON template and edit it
    $> dockstore tool convert cwl2json --cwl Dockstore.cwl > Dockstore.json
    # run it locally with the Dockstore CLI
    $> dockstore tool launch --entry quay.io/pancancer/pcawg_delly_workflow:2.0.0 \
        --json Dockstore.json

## Tips

* Carefully monitor the CPU, storage, and memory usage of this workflow. You may be able to use a smaller instance than what is recommended above.
* Be mindful of where on the filesystem you run the `dockstore launch` above. The working directory, where large files are downloaded to, is placed here.

## See Also

These resources are based on a mirror of the original [bitbucket repository](https://bitbucket.org/weischen/pcawg-delly-workflow) to [Github](https://github.com/ICGC-TCGA-PanCancer/pcawg_delly_workflow).


