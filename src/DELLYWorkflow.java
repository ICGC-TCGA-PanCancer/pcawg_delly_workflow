    package io.seqware;

import java.util.Map;
import java.util.ArrayList;
import java.util.logging.Level;
import java.util.logging.Logger;
import net.sourceforge.seqware.pipeline.workflowV2.AbstractWorkflowDataModel;
import net.sourceforge.seqware.pipeline.workflowV2.model.Job;
import net.sourceforge.seqware.pipeline.workflowV2.model.SqwFile;

public class DELLYWorkflow extends AbstractWorkflowDataModel {

    private boolean breakpoint=false;
    private String delly_bin;
    private String cov_bin;
    private String cov_plot;
    private String gcnorm_r;
    private String rscript_bin;
    private String uploader_bin;
    private String somatic_filter;
    private String delly2bed;

    private String ref_genome_path = "";
    private String ref_genome_gc_path = "";
    
    private String resultsDirRoot = "results";
    private String resultsDirDelly = "results/delly";
    private String resultsDirJumpy = "results/jumpy";
    private String resultsDirDuppy = "results/duppy";
    private String resultsDirInvy = "results/invy";
    private String resultsDirCov = "results/cov";
    private String resultsDirCovPlot = "results/cov/plot";


    String inputBamPathTumor = null;
    String inputBamPathGerm = null;  

    // used to download with gtdownload
    String gnosInputFileURLTumor = null;
    String gnosInputFileURLGerm = null;
    String gnosUploadFileURL = null;
    String gnosKey = null;


    private void init() {
	try {
      
      if (hasPropertyAndNotNull("breakpoint")) {
          breakpoint = Boolean.valueOf(getProperty("breakpoint"));
      }
      inputBamPathTumor = getProperty("input_bam_path_tumor");

      gnosInputFileURLTumor = getProperty("gnos_input_file_url_tumor");

      inputBamPathGerm = getProperty("input_bam_path_germ");

      gnosInputFileURLGerm = getProperty("gnos_input_file_url_germ");

      //      gnosUploadFileURL = getProperty("gnos_output_file_url");
      gnosKey = getProperty("gnos_key");

      delly_bin = getProperty("delly_bin");
      cov_bin = getProperty("cov_bin");
      cov_plot = getProperty("cov_plot");
      gcnorm_r = getProperty("gcnorm_r");
      rscript_bin = getProperty("rscript_bin");
      uploader_bin = getProperty("uploader_bin");
      somatic_filter = getProperty("somatic_filter");
      delly2bed = getProperty("delly2bed");

      ref_genome_path = getProperty("ref_genome_path");
      ref_genome_gc_path = getProperty("ref_genome_gc_path");

	} catch (Exception e) {
	    e.printStackTrace();
	    throw new RuntimeException(e);
	}
    }

    @Override
    public void setupDirectory() {
        //since setupDirectory is the first method run, we use it to initialize variables too.
        init();
       

        this.addDirectory(resultsDirDelly);
        this.addDirectory(resultsDirDuppy);
        this.addDirectory(resultsDirInvy);
        this.addDirectory(resultsDirJumpy);
        this.addDirectory(resultsDirCov);
        this.addDirectory(resultsDirCovPlot);

    }
 
    @Override
    public Map<String, SqwFile> setupFiles() {
      try {        
          if (breakpoint == true) {
              SqwFile ref_genome = this.createFile("ref_gen");
              ref_genome.setSourcePath(ref_genome_path);
              ref_genome.setIsInput(true);  
          }
          SqwFile ref_genome_gc = this.createFile("ref_gen_gc");
          ref_genome_gc.setSourcePath(ref_genome_gc_path);
          ref_genome_gc.setIsInput(true);  

      } catch (Exception ex) {
        ex.printStackTrace();
        throw new RuntimeException(ex);
      }
      return this.getFiles();
    }
    
   
    @Override
    public void buildWorkflow() {
        
        String ref_gen_path = " ";
        String ref_gen_gc_path = " ";
        ArrayList<Job> downloadJobs = new ArrayList<Job>();

        // DOWNLOAD DATA

        Job gtDownloadJob1 = this.getWorkflow().createBashJob("gtdownload1");
        gtDownloadJob1.getCommand().addArgument("gtdownload")
            .addArgument("-c " + gnosKey)
            .addArgument("-v -d")
            .addArgument(gnosInputFileURLTumor);
        downloadJobs.add(gtDownloadJob1);
        Job gtDownloadJob2 = this.getWorkflow().createBashJob("gtdownload2");
        gtDownloadJob2.getCommand().addArgument("gtdownload")
            .addArgument("-c " + gnosKey)
            .addArgument("-v -d")
            .addArgument(gnosInputFileURLGerm);
        downloadJobs.add(gtDownloadJob2);

        
        //prepare output
        
        String tumorFile = inputBamPathTumor;
        String germFile = inputBamPathGerm;
             
        String[] tumorName = tumorFile.split("/");
        String[] germName = germFile.split("/");
        //String samplePair =tumorName[0] + "_vs_" + germName[0];
        String samplePair =tumorName[0];
        if (breakpoint == true) {
            samplePair += ".bp";
            ref_gen_path = this.getFiles().get("ref_gen").getProvisionedPath();
        }
        ref_gen_gc_path = this.getFiles().get("ref_gen_gc").getProvisionedPath();

        String logFileDelly=resultsDirDelly + "/" + samplePair + ".deletions.bp.log";
        String outputFileDelly=resultsDirDelly + "/" + samplePair + ".deletions.bp.vcf";
        String outputFileDellyFilter=resultsDirDelly + "/" + samplePair + ".deletions.bp.somatic.vcf";

        String logFileDuppy=resultsDirDuppy + "/" + samplePair + ".duplications.bp.log";
        String outputFileDuppy=resultsDirDuppy + "/" + samplePair + ".duplications.bp.vcf";
        String outputFileDuppyFilter=resultsDirDuppy + "/" + samplePair + ".duplications.bp.somatic.vcf";

        String logFileInvy=resultsDirInvy + "/" + samplePair + ".inversions.bp.log";
        String outputFileInvy=resultsDirInvy + "/" + samplePair + ".inversions.bp.vcf";
        String outputFileInvyFilter=resultsDirInvy + "/" + samplePair + ".inversions.bp.somatic.vcf";

        String logFileJumpy=resultsDirJumpy + "/" + samplePair + ".translocations.bp.log";
        String outputFileJumpy=resultsDirJumpy + "/" + samplePair + ".translocations.bp.vcf";
        String outputFileJumpyFilter=resultsDirJumpy + "/" + samplePair + ".translocations.bp.somatic.vcf";
        
        String outputFileCovGerm1=resultsDirCov + "/" + germName[0] + "_1kb.cov";
        String outputFileCovGerm1Log=resultsDirCov + "/" + germName[0] + "_1kb.log";
        String outputFileCovGerm2=resultsDirCov + "/" + germName[0] + "_10kb.cov";
        String outputFileCovGerm2Log=resultsDirCov + "/" + germName[0] + "_10kb.log";

        String outputFileCovGermGcnorm=resultsDirCov + "/" + germName[0] + ".gcnorm.cov";

        String outputFileCovTumor1=resultsDirCov + "/" + tumorName[0] + "_1kb.cov";
        String outputFileCovTumor1Log=resultsDirCov + "/" + tumorName[0] + "_1kb.log";
        String outputFileCovTumor2=resultsDirCov + "/" + tumorName[0] + "_10kb.cov";
        String outputFileCovTumor2Log=resultsDirCov + "/" + tumorName[0] + "_10kb.log";

        String outputFileCovTumorGcnorm=resultsDirCov + "/" + tumorName[0] + ".gcnorm.cov";
             
    
        //7 jobs per downloaded BAM pair (DELLY,DUPPY,INVY,JUMPY, 3xCOV)
        
        Job dellyJob = this.getWorkflow().createBashJob("delly_job");
        dellyJob.getCommand().addArgument(delly_bin)
            .addArgument("-t DEL")
            .addArgument("-s 9")
            .addArgument(breakpoint == true ? "-g " + ref_gen_path : " ")
            .addArgument("-q 1")
            .addArgument("-o " + outputFileDelly)
            .addArgument(tumorFile)
            .addArgument(germFile)
            .addArgument(" &> " + logFileDelly);
        dellyJob.addParent(downloadJobs.get(0));
        dellyJob.addParent(downloadJobs.get(1));
        
        Job dellyFilterJob1 = this.getWorkflow().createBashJob("delly_filter_job1");
        dellyFilterJob1.getCommand().addArgument(delly2bed)
            .addArgument("-v " + outputFileDelly)
            .addArgument("-o " + outputFileDelly + ".bedpe.txt");
        dellyFilterJob1.addParent(dellyJob);
        
        Job dellyFilterJob2 = this.getWorkflow().createBashJob("delly_filter_job2");
        dellyFilterJob2.getCommand().addArgument(somatic_filter)
            .addArgument("-v " + outputFileDelly)
            .addArgument("-o " + outputFileDellyFilter);
        dellyFilterJob2.addParent(dellyJob);

        Job dellyFilterJob3 = this.getWorkflow().createBashJob("delly_filter_job3");
        dellyFilterJob3.getCommand().addArgument(delly2bed)
            .addArgument("-v " + outputFileDellyFilter)
            .addArgument("-o " + outputFileDellyFilter + ".bedpe.txt");
        dellyFilterJob3.addParent(dellyFilterJob2);

        //DUPPY
        Job duppyJob = this.getWorkflow().createBashJob("duppy_job");
        duppyJob.getCommand().addArgument(delly_bin)
            .addArgument("-t DUP")
            .addArgument("-s 9")
            .addArgument(breakpoint == true ? "-g " + ref_gen_path : " ")
            .addArgument("-q 1")
            .addArgument("-o " + outputFileDuppy)
            .addArgument(tumorFile)
            .addArgument(germFile)
            .addArgument(" &> " + logFileDuppy);
        duppyJob.addParent(downloadJobs.get(0));
        duppyJob.addParent(downloadJobs.get(1));

        Job duppyFilterJob1 = this.getWorkflow().createBashJob("duppy_filter_job1");
        duppyFilterJob1.getCommand().addArgument(delly2bed)
            .addArgument("-v " + outputFileDuppy)
            .addArgument("-o " + outputFileDuppy + ".bedpe.txt");
        duppyFilterJob1.addParent(duppyJob);
        
        Job duppyFilterJob2 = this.getWorkflow().createBashJob("duppy_filter_job2");
        duppyFilterJob2.getCommand().addArgument(somatic_filter)
            .addArgument("-v " + outputFileDuppy)
            .addArgument("-o " + outputFileDuppyFilter);
        duppyFilterJob2.addParent(duppyJob);

        Job duppyFilterJob3 = this.getWorkflow().createBashJob("duppy_filter_job3");
        duppyFilterJob3.getCommand().addArgument(delly2bed)
            .addArgument("-v " + outputFileDuppyFilter)
            .addArgument("-o " + outputFileDuppyFilter + ".bedpe.txt");
        duppyFilterJob3.addParent(duppyFilterJob2);


        //INVY
        Job invyJob = this.getWorkflow().createBashJob("invy_job");
        invyJob.getCommand().addArgument(delly_bin)
            .addArgument("-t INV")
            .addArgument("-q 1")
            .addArgument(breakpoint == true ? "-g " + ref_gen_path : " ")
            .addArgument("-o " + outputFileInvy)
            .addArgument(tumorFile)
            .addArgument(germFile)
            .addArgument(" &> " + logFileInvy);
        invyJob.addParent(downloadJobs.get(0));
        invyJob.addParent(downloadJobs.get(1));

         Job invyFilterJob1 = this.getWorkflow().createBashJob("invy_filter_job1");
        invyFilterJob1.getCommand().addArgument(delly2bed)
            .addArgument("-v " + outputFileInvy)
            .addArgument("-o " + outputFileInvy + ".bedpe.txt");
        invyFilterJob1.addParent(invyJob);
        
        Job invyFilterJob2 = this.getWorkflow().createBashJob("invy_filter_job2");
        invyFilterJob2.getCommand().addArgument(somatic_filter)
            .addArgument("-v " + outputFileInvy)
            .addArgument("-o " + outputFileInvyFilter);
        invyFilterJob2.addParent(invyJob);

        Job invyFilterJob3 = this.getWorkflow().createBashJob("invy_filter_job3");
        invyFilterJob3.getCommand().addArgument(delly2bed)
            .addArgument("-v " + outputFileInvyFilter)
            .addArgument("-o " + outputFileInvyFilter + ".bedpe.txt");
        invyFilterJob3.addParent(invyFilterJob2);
        
        //JUMPY
        Job jumpyJob = this.getWorkflow().createBashJob("jumpy_job");
        jumpyJob.getCommand().addArgument(delly_bin)
            .addArgument("-t TRA")
            .addArgument("-q 1")
            //.addArgument(breakpoint == true ? "-g " + ref_gen_path : " ") Not run breakpoint for jumpy
            .addArgument("-o " + outputFileJumpy)
            .addArgument(tumorFile)
            .addArgument(germFile)
            .addArgument(" &> " + logFileJumpy);
        jumpyJob.addParent(downloadJobs.get(0));
        jumpyJob.addParent(downloadJobs.get(1));

         Job jumpyFilterJob1 = this.getWorkflow().createBashJob("jumpy_filter_job1");
        jumpyFilterJob1.getCommand().addArgument(delly2bed)
            .addArgument("-v " + outputFileJumpy)
            .addArgument("-o " + outputFileJumpy + ".bedpe.txt");
        jumpyFilterJob1.addParent(jumpyJob);
        
        Job jumpyFilterJob2 = this.getWorkflow().createBashJob("jumpy_filter_job2");
        jumpyFilterJob2.getCommand().addArgument(somatic_filter)
            .addArgument("-v " + outputFileJumpy)
            .addArgument("-o " + outputFileJumpyFilter);
        jumpyFilterJob2.addParent(jumpyJob);

        Job jumpyFilterJob3 = this.getWorkflow().createBashJob("jumpy_filter_job3");
        jumpyFilterJob3.getCommand().addArgument(delly2bed)
            .addArgument("-v " + outputFileJumpyFilter)
            .addArgument("-o " + outputFileJumpyFilter + ".bedpe.txt");
        jumpyFilterJob3.addParent(jumpyFilterJob2);


        //COV + plot jobs
        Job covJobGerm1 = this.getWorkflow().createBashJob("cov_job_germ1");
        covJobGerm1.getCommand().addArgument(cov_bin)
            .addArgument("-s 1000")
            .addArgument("-o 1000")
            .addArgument(germFile)
            .addArgument("-f " + outputFileCovGerm1)
            .addArgument(" &> " + outputFileCovGerm1Log);
        covJobGerm1.addParent(downloadJobs.get(0));
        covJobGerm1.addParent(downloadJobs.get(1));

        Job covJobGerm2 = this.getWorkflow().createBashJob("cov_job_germ2");
        covJobGerm2.getCommand().addArgument(cov_bin)
            .addArgument("-s 10000")
            .addArgument("-o 10000")
            .addArgument(germFile)
            .addArgument("-f " + outputFileCovGerm2)
            .addArgument(" &> " + outputFileCovGerm2Log);
        covJobGerm2.addParent(downloadJobs.get(0));
        covJobGerm2.addParent(downloadJobs.get(1));

        Job covJobGerm3 = this.getWorkflow().createBashJob("cov_job_germ3");
        covJobGerm3.getCommand().addArgument(rscript_bin  + " " + gcnorm_r)
            .addArgument(outputFileCovGerm2)
            .addArgument(ref_gen_gc_path)
            .addArgument(outputFileCovGermGcnorm);
        covJobGerm3.addParent(covJobGerm2);

        Job covJobTumor1 = this.getWorkflow().createBashJob("cov_job_tumor1");
        covJobTumor1.getCommand().addArgument(cov_bin)
            .addArgument("-s 1000")
            .addArgument("-o 1000")
            .addArgument(tumorFile)
            .addArgument("-f " + outputFileCovTumor1)
            .addArgument(" &> " + outputFileCovTumor1Log);
        covJobTumor1.addParent(downloadJobs.get(0));
        covJobTumor1.addParent(downloadJobs.get(1));

        Job covJobTumor2 = this.getWorkflow().createBashJob("cov_job_tumor2");
        covJobTumor2.getCommand().addArgument(cov_bin)
            .addArgument("-s 10000")
            .addArgument("-o 10000")
            .addArgument(tumorFile)
            .addArgument("-f " + outputFileCovTumor2)
            .addArgument(" &> " + outputFileCovTumor2Log);
        covJobTumor2.addParent(downloadJobs.get(0));
        covJobTumor2.addParent(downloadJobs.get(1));

        Job covJobTumor3 = this.getWorkflow().createBashJob("cov_job_tumor3");
        covJobTumor3.getCommand().addArgument(rscript_bin  + " " + gcnorm_r)
            .addArgument(outputFileCovTumor2)
            .addArgument(ref_gen_gc_path)
            .addArgument(outputFileCovTumorGcnorm);
        covJobTumor3.addParent(covJobTumor2);
             
    
        Job covJobPlot = this.getWorkflow().createBashJob("cov_job_plot");
        covJobPlot.getCommand().addArgument(cov_plot  + " " + outputFileCovGermGcnorm)
            .addArgument(outputFileCovTumorGcnorm)
            .addArgument(resultsDirCovPlot);
        covJobPlot.addParent(covJobGerm3);
        covJobPlot.addParent(covJobTumor3);


        
        //TODO
        //check and upload results
        Job uploadJob = this.getWorkflow().createBashJob("upload_job");
        uploadJob.getCommand().addArgument(uploader_bin  + " " + resultsDirRoot + " " + samplePair);
        uploadJob.addParent(covJobPlot);

        //cleanup data downloaded + created
        
    }
}
