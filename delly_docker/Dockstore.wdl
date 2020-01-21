version 1.0

task Seqware_Delly {
  input {
    File reference_gc
    File tumorBam
    File normalBamIndex
    File tumorBamIndex
    File normalBam
    File reference_gz
    String run_id
  }
  command <<<
        # Set the exit code of a pipeline to that of the rightmost command
        # to exit with a non-zero status, or zero if all commands of the pipeline exit
        set -o pipefail
        # cause a bash script to exit immediately when a command fails
        set -e
        # cause the bash shell to treat unset variables as an error and exit immediately
        set -u
        # echo each line of the script to stdout so we can see what is happening
        set -o xtrace
        # to turn off echo do 'set +o xtrace'

        # Create a temp directory in the current working directory
        mkdir -p $PWD/tmp
        # Symlink /tmp in the Docker container to point to our temp directory
        #  in the Cromwell execution dir
        ln -s $PWD/tmp /tmp
        # Set the env variables that cwltool sets when it launches a Docker
        # container and which the workflow expects to be set
        export TEMPDIR=/tmp
        export HOME=$PWD

        /start.sh perl /usr/bin/run_seqware_workflow.pl --tumor-bam ~{tumorBam} --normal-bam ~{normalBam} --reference-gz ~{reference_gz} --reference-gc ~{reference_gc} --run-id ~{run_id}
    >>>

    output {
        Array[File] somatic_sv_vcf = glob("*.somatic.sv.vcf.gz")
        Array[File] germline_sv_vcf = glob("*.germline.sv.vcf.gz")
        Array[File] sv_vcf = glob("*[0-9].sv.vcf.gz")
        Array[File] somatic_bedpe = glob("*.somatic.sv.bedpe.txt")
        Array[File] somatic_bedpe_tar_gz = glob("*.somatic.sv.bedpe.txt.tar.gz")
        Array[File] germline_bedpe = glob("*.germline.sv.bedpe.txt")
        Array[File] germline_bedpe_tar_gz = glob("*.germline.sv.bedpe.txt.tar.gz")
        Array[File] somatic_sv_readname = glob("*.somatic.sv.readname.txt.tar.gz")
        Array[File] germline_sv_readname = glob("*.germline.sv.readname.txt.tar.gz")
        Array[File] cov = glob("*.sv.cov.tar.gz")
        Array[File] cov_plots = glob("*.sv.cov.plots.tar.gz")
        Array[File] sv_log = glob("*.sv.log.tar.gz")
        Array[File] sv_qc = glob("*.sv.qc_metrics.tar.gz")
        Array[File] sv_timing = glob("*.sv.timing_metrics.tar.gz")
    }

    runtime {
        preemptible: 1
        maxRetries: 2
        memory: 100 + " GB"
        cpu: 4
        disks: "local-disk " + 200 + " HDD"
        docker: 'quay.io/pancancer/pcawg_delly_workflow:2.2.0'
    }
}

workflow Seqware_Delly_Workflow {
  input {
    File reference_gc
    File tumorBam
    File normalBam
    File normalBamIndex
    File tumorBamIndex
    File reference_gz
    String run_id
  }
    call Seqware_Delly {
        input:
            reference_gc = reference_gc,
            tumorBam = tumorBam,
            normalBam = normalBam,
            tumorBamIndex = tumorBamIndex,
            normalBamIndex = normalBamIndex,
            reference_gz = reference_gz,
            run_id = run_id
    }
    meta {
      author : "Walt Shands, Natalie Perez"
      email : "jshands@ucsc.edu, nperez9@ucsc.edu"
      description: "PCAWG EMBL variant calling workflow was developed by European Molecular Biology Laboratory at Heidelberg (EMBL, https://www.embl.de). The source code is available on GitHub at: https://github.com/ICGC-TCGA-PanCancer/pcawg_delly_workflow"
    }
}

