    package io.seqware;

import java.util.Map;
import java.util.ArrayList;
import java.util.logging.Level;
import java.util.logging.Logger;
import net.sourceforge.seqware.pipeline.workflowV2.AbstractWorkflowDataModel;
import net.sourceforge.seqware.pipeline.workflowV2.model.Job;
import net.sourceforge.seqware.pipeline.workflowV2.model.SqwFile;
import java.util.Date;
import java.util.Calendar;
import java.text.DateFormat;
import java.text.SimpleDateFormat;

public class DELLYWorkflow extends AbstractWorkflowDataModel {

    private boolean breakpoint=false;
    private String delly_bin;
    private String cov_bin;
    private String cov_plot;
    private String vcfcombine_bin;
    private String vcf_sort_bin;
    private String gcnorm_r;
    private String rscript_bin;

    private String prepare_uploader_bin;
    private String copy_results_bin;

    private String somatic_filter;
    private String delly2bed;
    private String delly_pe_dump;

    private String ref_genome_path = "";
    private String ref_genome_gc_path = "";
    private String datastore = "";
    private String runID = "";
    
    
    private String resultsDirRoot = "delly_results/";
    private String resultsDirDelly = "delly_results/delly";
    private String resultsDirJumpy = "delly_results/jumpy";
    private String resultsDirDuppy = "delly_results/duppy";
    private String resultsDirInvy = "delly_results/invy";
    private String resultsDirCov = "delly_results/cov";
    private String resultsDirCovPlot = "delly_results/cov/plot";

    String workflowID = null;
    String inputBamPathTumor = null;
    String inputBamPathGerm = null;  
   
    private void init() {
	try {
      
      if (hasPropertyAndNotNull("breakpoint")) {
          breakpoint = Boolean.valueOf(getProperty("breakpoint"));
      }
      inputBamPathTumor = getProperty("input_bam_path_tumor");
      inputBamPathGerm = getProperty("input_bam_path_germ");

      runID = getProperty("delly_runID");
      datastore = getProperty("datastore");
      
      workflowID = getProperty("delly_workflowID");

      delly_bin = getProperty("delly_bin");
      cov_bin = getProperty("cov_bin");
      cov_plot = getProperty("cov_plot");
      gcnorm_r = getProperty("gcnorm_r");
      vcfcombine_bin = getProperty("vcfcombine_bin");
      vcf_sort_bin = getProperty("vcf_sort_bin");
      rscript_bin = getProperty("rscript_bin");

      somatic_filter = getProperty("somatic_filter");
      delly2bed = getProperty("delly2bed");
      delly_pe_dump = getProperty("delly_pe_dump");

      ref_genome_path = getProperty("ref_genome_path");
      ref_genome_gc_path = getProperty("ref_genome_gc_path");
      prepare_uploader_bin = getProperty("prepare_uploader_bin");
      copy_results_bin = getProperty("copy_results_bin");

	} catch (Exception e) {
	    e.printStackTrace();
	    throw new RuntimeException(e);
	}
    }

    @Override
    public void setupDirectory() {

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
          //          if (breakpoint == true) {
              //             SqwFile ref_genome = this.createFile("ref_gen");
          //  ref_genome.setSourcePath(ref_genome_path);
          //    ref_genome.setIsInput(true);  
          // }
          // SqwFile ref_genome_gc = this.createFile("ref_gen_gc");
          // ref_genome_gc.setSourcePath(ref_genome_gc_path);
          //ref_genome_gc.setIsInput(true);  

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
        
        
        //prepare output IDs
        
        String tumorFile = datastore + inputBamPathTumor;
        String germFile = datastore + inputBamPathGerm;
             
        String[] tumorName = tumorFile.split("/");
        String[] germName = germFile.split("/");
        
        ref_gen_path = ref_genome_path;
        ref_gen_gc_path = ref_genome_gc_path;
        
        String logFileDelly=resultsDirDelly + "/" + runID + ".deletions.log";
        String outputFileDelly=resultsDirDelly + "/" + runID + ".deletions";
        String outputFileDellyFilter=resultsDirDelly + "/" + runID + ".deletions.somatic";
        String outputFileDellyFilterConf=resultsDirDelly + "/" + runID + ".deletions.somatic.highConf";
        String outputFileDellyFilterGerm=resultsDirDelly + "/" + runID + ".deletions.germline";
        String outputFileDellyFilterConfGerm=resultsDirDelly + "/" + runID + ".deletions.germline.highConf";
        String outputFileDellyDump=resultsDirDelly + "/" + runID + ".deletions.pe_dump.txt";
        String outputFileDellySomaticDump=resultsDirDelly + "/" + runID + ".deletions.somatic.readname.txt";
        String outputFileDellyGermDump=resultsDirDelly + "/" + runID + ".deletions.germline.readname.txt";

        String logFileDuppy=resultsDirDuppy + "/" + runID + ".duplications.log";
        String outputFileDuppy=resultsDirDuppy + "/" + runID + ".duplications";
        String outputFileDuppyFilter=resultsDirDuppy + "/" + runID + ".duplications.somatic";
        String outputFileDuppyFilterConf=resultsDirDuppy + "/" + runID + ".duplications.somatic.highConf";
        String outputFileDuppyFilterGerm=resultsDirDuppy + "/" + runID + ".duplications.germline";
        String outputFileDuppyFilterConfGerm=resultsDirDuppy + "/" + runID + ".duplications.germline.highConf";
        String outputFileDuppyDump=resultsDirDuppy + "/" + runID + ".duplications.pe_dump.txt";
        String outputFileDuppySomaticDump=resultsDirDuppy + "/" + runID + ".duplications.somatic.readname.txt";
        String outputFileDuppyGermDump=resultsDirDuppy + "/" + runID + ".duplications.germline.readname.txt";

        String logFileInvy=resultsDirInvy + "/" + runID + ".inversions.log";
        String outputFileInvy=resultsDirInvy + "/" + runID + ".inversions";
        String outputFileInvyFilter=resultsDirInvy + "/" + runID + ".inversions.somatic";
        String outputFileInvyFilterConf=resultsDirInvy + "/" + runID + ".inversions.somatic.highConf";
        String outputFileInvyFilterGerm=resultsDirInvy + "/" + runID + ".inversions.germline";
        String outputFileInvyFilterConfGerm=resultsDirInvy + "/" + runID + ".inversions.germline.highConf";
        String outputFileInvyDump=resultsDirInvy + "/" + runID + ".inversions.pe_dump.txt";
        String outputFileInvySomaticDump=resultsDirInvy + "/" + runID + ".inversions.somatic.readname.txt";
        String outputFileInvyGermDump=resultsDirInvy + "/" + runID + ".inversions.germline.readname.txt";

        String logFileJumpy=resultsDirJumpy + "/" + runID + ".translocations.log";
        String outputFileJumpy=resultsDirJumpy + "/" + runID + ".translocations";
        String outputFileJumpyFilter=resultsDirJumpy + "/" + runID + ".translocations.somatic";
        String outputFileJumpyFilterConf=resultsDirJumpy + "/" + runID + ".translocations.somatic.highConf";
        String outputFileJumpyFilterGerm=resultsDirJumpy + "/" + runID + ".translocations.germline";
        String outputFileJumpyFilterConfGerm=resultsDirJumpy + "/" + runID + ".translocations.germline.highConf";
        String outputFileJumpyDump=resultsDirJumpy + "/" + runID + ".translocations.pe_dump.txt";
        String outputFileJumpySomaticDump=resultsDirJumpy + "/" + runID + ".translocations.somatic.readname.txt";
        String outputFileJumpyGermDump=resultsDirJumpy + "/" + runID + ".translocations.germline.readname.txt";

        String outputFileCovGerm1=resultsDirCov + "/" + runID + "_germ"  + "_1kb.cov";
        String outputFileCovGerm1Log=resultsDirCov + "/" + runID + "_germ"  + "_1kb.log";
        String outputFileCovGerm2=resultsDirCov + "/" + runID + "_germ"  + "_10kb.cov";
        String outputFileCovGerm2Log=resultsDirCov + "/" + runID + "_germ"  + "_10kb.log";

        String outputFileCovGermGcnorm=resultsDirCov + "/" + runID + "_germ"  + ".gcnorm.cov";

        String outputFileCovTumor1=resultsDirCov + "/" + runID + "_tumor"  + "_1kb.cov";
        String outputFileCovTumor1Log=resultsDirCov + "/" + runID + "_tumor"  + "_1kb.log";
        String outputFileCovTumor2=resultsDirCov + "/" + runID + "_tumor"  + "_10kb.cov";
        String outputFileCovTumor2Log=resultsDirCov + "/" + runID + "_tumor"  + "_10kb.log";
        String outputFileCovTumorGcnorm=resultsDirCov + "/" + runID + "_tumor"  + ".gcnorm.cov";
              
        //7 jobs per downloaded BAM pair (DELLY,DUPPY,INVY,JUMPY, 3xCOV)
        
        Job dellyJob = this.getWorkflow().createBashJob("delly_job");
        dellyJob.getCommand().addArgument(delly_bin)
            .addArgument("-t DEL")
            .addArgument("-s 9")
            .addArgument(breakpoint == true ? "-g " + ref_gen_path : " ")
            .addArgument("-q 1")
            .addArgument("-p " + outputFileDellyDump)
            .addArgument("-o " + outputFileDelly + ".vcf")
            .addArgument(tumorFile + "/*bam")
            .addArgument(germFile + "/*bam")
            .addArgument(" &> " + logFileDelly);

        //dellyJob.addParent(downloadJobs.get(0));
        // dellyJob.addParent(downloadJobs.get(1));
        
        // Job dellyFilterJob1 = this.getWorkflow().createBashJob("delly_filter_job1");
        // dellyFilterJob1.getCommand().addArgument(delly2bed)
        //     .addArgument("-v " + outputFileDelly + ".vcf")
        //     .addArgument("-o " + outputFileDelly + ".bedpe.txt");
        // dellyFilterJob1.addParent(dellyJob);
        
         Job dellyFilterJob2 = this.getWorkflow().createBashJob("delly_filter_job2");
         dellyFilterJob2.getCommand().addArgument(somatic_filter)
             .addArgument("-v " + outputFileDelly + ".vcf")
             .addArgument("-o " + outputFileDellyFilter + ".vcf");
         dellyFilterJob2.addParent(dellyJob);

        // Job dellyFilterJob3 = this.getWorkflow().createBashJob("delly_filter_job3");
        // dellyFilterJob3.getCommand().addArgument(delly2bed)
        //     .addArgument("-v " + outputFileDellyFilter + ".vcf")
        //     .addArgument("-o " + outputFileDellyFilter + ".bedpe.txt");
        // dellyFilterJob3.addParent(dellyFilterJob2);

        // Job dellyFilterJob4 = this.getWorkflow().createBashJob("delly_filter_job4");
        // dellyFilterJob4.getCommand().addArgument(delly2bed)
        //     .addArgument("-v " + outputFileDellyFilterConf + ".vcf")
        //     .addArgument("-o " + outputFileDellyFilterConf + ".bedpe.txt");
        // dellyFilterJob4.addParent(dellyFilterJob3);



        //DUPPY
        Job duppyJob = this.getWorkflow().createBashJob("duppy_job");
        duppyJob.getCommand().addArgument(delly_bin)
            .addArgument("-t DUP")
            //.addArgument("-s 9")
            .addArgument(breakpoint == true ? "-g " + ref_gen_path : " ")
            .addArgument("-q 1")
            .addArgument("-p " + outputFileDuppyDump)
            .addArgument("-o " + outputFileDuppy + ".vcf")
            .addArgument(tumorFile + "/*bam")
            .addArgument(germFile + "/*bam")
            .addArgument(" &> " + logFileDuppy);
        
        //        duppyJob.addParent(downloadJobs.get(0));
        // duppyJob.addParent(downloadJobs.get(1));

        // Job duppyFilterJob1 = this.getWorkflow().createBashJob("duppy_filter_job1");
        // duppyFilterJob1.getCommand().addArgument(delly2bed)
        //     .addArgument("-v " + outputFileDuppy + ".vcf")
        //     .addArgument("-o " + outputFileDuppy + ".bedpe.txt");
        // duppyFilterJob1.addParent(duppyJob);
        
         Job duppyFilterJob2 = this.getWorkflow().createBashJob("duppy_filter_job2");
         duppyFilterJob2.getCommand().addArgument(somatic_filter)
             .addArgument("-v " + outputFileDuppy + ".vcf")
             .addArgument("-o " + outputFileDuppyFilter + ".vcf");
         duppyFilterJob2.addParent(duppyJob);

        // Job duppyFilterJob3 = this.getWorkflow().createBashJob("duppy_filter_job3");
        // duppyFilterJob3.getCommand().addArgument(delly2bed)
        //     .addArgument("-v " + outputFileDuppyFilter + ".vcf")
        //     .addArgument("-o " + outputFileDuppyFilter + ".bedpe.txt");
        // duppyFilterJob3.addParent(duppyFilterJob2);

        // Job duppyFilterJob4 = this.getWorkflow().createBashJob("duppy_filter_job4");
        // duppyFilterJob4.getCommand().addArgument(delly2bed)
        //     .addArgument("-v " + outputFileDuppyFilterConf + ".vcf")
        //     .addArgument("-o " + outputFileDuppyFilterConf + ".bedpe.txt");
        // duppyFilterJob4.addParent(duppyFilterJob3);        


        //INVY
        Job invyJob = this.getWorkflow().createBashJob("invy_job");
        invyJob.getCommand().addArgument(delly_bin)
            .addArgument("-t INV")
            .addArgument("-q 1")
            .addArgument(breakpoint == true ? "-g " + ref_gen_path : " ")
            .addArgument("-p " + outputFileInvyDump)
            .addArgument("-o " + outputFileInvy + ".vcf")
            .addArgument(tumorFile + "/*bam")
            .addArgument(germFile + "/*bam")
            .addArgument(" &> " + logFileInvy);
        
        //        invyJob.addParent(downloadJobs.get(0));
        //        invyJob.addParent(downloadJobs.get(1));

        //  Job invyFilterJob1 = this.getWorkflow().createBashJob("invy_filter_job1");
        // invyFilterJob1.getCommand().addArgument(delly2bed)
        //     .addArgument("-v " + outputFileInvy + ".vcf")
        //     .addArgument("-o " + outputFileInvy + ".bedpe.txt");
        // invyFilterJob1.addParent(invyJob);
        
         Job invyFilterJob2 = this.getWorkflow().createBashJob("invy_filter_job2");
         invyFilterJob2.getCommand().addArgument(somatic_filter)
             .addArgument("-v " + outputFileInvy + ".vcf")
             .addArgument("-o " + outputFileInvyFilter + ".vcf");
         invyFilterJob2.addParent(invyJob);

        // Job invyFilterJob3 = this.getWorkflow().createBashJob("invy_filter_job3");
        // invyFilterJob3.getCommand().addArgument(delly2bed)
        //     .addArgument("-v " + outputFileInvyFilter + ".vcf")
        //     .addArgument("-o " + outputFileInvyFilter + ".bedpe.txt");
        // invyFilterJob3.addParent(invyFilterJob2);

        // Job invyFilterJob4 = this.getWorkflow().createBashJob("invy_filter_job4");
        // invyFilterJob4.getCommand().addArgument(delly2bed)
        //     .addArgument("-v " + outputFileInvyFilterConf + ".vcf")
        //     .addArgument("-o " + outputFileInvyFilterConf + ".bedpe.txt");
        // invyFilterJob4.addParent(invyFilterJob3);        

        
        //JUMPY
        Job jumpyJob = this.getWorkflow().createBashJob("jumpy_job");
        jumpyJob.getCommand().addArgument(delly_bin)
            .addArgument("-t TRA")
            .addArgument("-q 1")
            .addArgument("-p " + outputFileJumpyDump)
            .addArgument("-o " + outputFileJumpy + ".vcf")
            .addArgument(tumorFile + "/*bam")
            .addArgument(germFile + "/*bam")
            .addArgument(" &> " + logFileJumpy);
        
        //        jumpyJob.addParent(downloadJobs.get(0));
        //        jumpyJob.addParent(downloadJobs.get(1));

        //  Job jumpyFilterJob1 = this.getWorkflow().createBashJob("jumpy_filter_job1");
        // jumpyFilterJob1.getCommand().addArgument(delly2bed)
        //     .addArgument("-v " + outputFileJumpy + ".vcf")
        //     .addArgument("-o " + outputFileJumpy + ".bedpe.txt");
        // jumpyFilterJob1.addParent(jumpyJob);
        
         Job jumpyFilterJob2 = this.getWorkflow().createBashJob("jumpy_filter_job2");
         jumpyFilterJob2.getCommand().addArgument(somatic_filter)
             .addArgument("-v " + outputFileJumpy + ".vcf")
             .addArgument("-o " + outputFileJumpyFilter + ".vcf");
         jumpyFilterJob2.addParent(jumpyJob);

        // Job jumpyFilterJob3 = this.getWorkflow().createBashJob("jumpy_filter_job3");
        // jumpyFilterJob3.getCommand().addArgument(delly2bed)
        //     .addArgument("-v " + outputFileJumpyFilter + ".vcf")
        //     .addArgument("-o " + outputFileJumpyFilter + ".bedpe.txt");
        // jumpyFilterJob3.addParent(jumpyFilterJob2);

        // Job jumpyFilterJob4 = this.getWorkflow().createBashJob("jumpy_filter_job4");
        // jumpyFilterJob4.getCommand().addArgument(delly2bed)
        //     .addArgument("-v " + outputFileJumpyFilterConf + ".vcf")
        //     .addArgument("-o " + outputFileJumpyFilterConf + ".bedpe.txt");
        // jumpyFilterJob4.addParent(jumpyFilterJob3);        


        //COV + plot jobs
        Job covJobGerm1 = this.getWorkflow().createBashJob("cov_job_germ1");
        covJobGerm1.getCommand().addArgument(cov_bin)
            .addArgument("-s 1000")
            .addArgument("-o 1000")
            .addArgument(germFile + "/*bam")
            .addArgument("-f " + outputFileCovGerm1)
            .addArgument(" &> " + outputFileCovGerm1Log);
        

        Job covJobGerm2 = this.getWorkflow().createBashJob("cov_job_germ2");
        covJobGerm2.getCommand().addArgument(cov_bin)
            .addArgument("-s 10000")
            .addArgument("-o 10000")
            .addArgument(germFile + "/*bam")
            .addArgument("-f " + outputFileCovGerm2)
            .addArgument(" &> " + outputFileCovGerm2Log);
        

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
            .addArgument(tumorFile + "/*bam")
            .addArgument("-f " + outputFileCovTumor1)
            .addArgument(" &> " + outputFileCovTumor1Log);
        

        Job covJobTumor2 = this.getWorkflow().createBashJob("cov_job_tumor2");
        covJobTumor2.getCommand().addArgument(cov_bin)
            .addArgument("-s 10000")
            .addArgument("-o 10000")
            .addArgument(tumorFile + "/*bam")
            .addArgument("-f " + outputFileCovTumor2)
            .addArgument(" &> " + outputFileCovTumor2Log);
        

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


        //check results and cleanup

        String currdateStamp = new SimpleDateFormat("yyyyMMdd").format(Calendar.getInstance().getTime());
        String delly_somatic = runID + "." + workflowID + "." + currdateStamp + ".somatic.vcf.gz";
        String delly_bedpe_somatic = runID + "." + workflowID + "." + currdateStamp + ".somatic.bedpe.txt";
        String cov_somatic = runID + "." + workflowID + "." + currdateStamp + ".cov";
        String delly_germline = runID + "." + workflowID + "." + currdateStamp + ".germline.vcf.gz";
        String delly_bedpe_germline = runID + "." + workflowID + "." + currdateStamp + ".germline.bedpe.txt";
        String delly_log = resultsDirRoot + runID + "." + workflowID + "." + currdateStamp + ".log";
        String delly_somatic_pe_dump = resultsDirRoot  + runID + "." + workflowID + "." + currdateStamp + ".somatic.readname.txt";
        String delly_germline_pe_dump = resultsDirRoot  + runID + "." + workflowID + "." + currdateStamp + ".germline.readname.txt";

       Job prepareUploadJobSomatic = this.getWorkflow().createBashJob("prepare_upload_job_somatic");
       prepareUploadJobSomatic.getCommand().addArgument(prepare_uploader_bin + " " + delly2bed  + " " + resultsDirRoot + " " + delly_somatic + " " + outputFileDellyFilterConf + ".vcf" + " " + outputFileDuppyFilterConf + ".vcf" + " " + outputFileInvyFilterConf + ".vcf" + " " + outputFileJumpyFilterConf + ".vcf "  + delly_pe_dump +  " " + tumorFile + "/*bam" + " " + delly_log + " " + cov_somatic + " " + resultsDirCov);
       prepareUploadJobSomatic.addParent(covJobPlot);

        Job prepareUploadJobGermline = this.getWorkflow().createBashJob("prepare_upload_job_germline");
        prepareUploadJobGermline.getCommand().addArgument(prepare_uploader_bin  + " " + delly2bed + " " + resultsDirRoot + " " + delly_germline + " " + outputFileDellyFilterConfGerm + ".vcf" + " " + outputFileDuppyFilterConfGerm + ".vcf" + " " + outputFileInvyFilterConfGerm + ".vcf" + " " + outputFileJumpyFilterConfGerm + ".vcf " + delly_pe_dump +  " " + germFile + "/*bam");
        prepareUploadJobGermline.addParent(prepareUploadJobSomatic);
        

        Job copyResultsJob = this.getWorkflow().createBashJob("copy_results_job");
        copyResultsJob.getCommand().addArgument(copy_results_bin  + " " + resultsDirRoot + " " + runID);
        copyResultsJob.addParent(prepareUploadJobGermline);
    }
}
