#!/usr/bin/perl

use strict;
use Getopt::Long;
use Cwd;

########
# ABOUT
########
# This script wraps calling a SeqWare workflow, in this case, the DELLY workflow.
# It reads param line options, which are easier to deal with in CWL, then
# creates an INI file, and, finally, executes the workflow.  This workflow
# is already setup to run in local file mode so I just really need to override
# the inputs and outputs.
# EXAMPLE:
# perl /workflow/scripts/run_seqware_workflow.pl --file '${workflow_bundle_dir}/Workflow_Bundle_BWA/2.6.8/data/testData/sample_bam_sequence_synthetic_chr22_normal/9c414428-9446-11e3-86c1-ab5c73f0e08b/hg19.chr22.5x.normal.bam' --file '${workflow_bundle_dir}/Workflow_Bundle_BWA/2.6.8/data/testData/sample_bam_sequence_synthetic_chr22_normal/4fb18a5a-9504-11e3-8d90-d1f1d69ccc24/hg19.chr22.5x.normal2.bam'
# TODO:
# this is a very hard-coded script and assumes it's running inside the Docker container

# key items from INI
# # key=datastore:type=text:display=T:display_name=ID for the current run, will be used to create filenames
# EMBL.delly_runID=f393bb07-270c-2c93-e040-11ac0d484533

# # key=input_bam_path_tumor:type=text:display=T:display_name=The relative tumor BAM path, directory name only
#input_bam_path_tumor=907c95e8-217c-4434-8b1d-3550507f0b80

# key=input_bam_path_germ:type=text:display=T:display_name=The relative germline BAM path, corresponding to the directory with the tumor BAM
#input_bam_path_germ=b8a9dda5-8299-4fe4-8964-d248bb24bb95

# key=datastore:type=text:display=T:display_name=path to datastore directory within the Docker container (which is tied from the upper level when running the Docker container)
#datastore=/datastore/

# so for the above, the path is the directory that contains the BAM file... I could do something like /datastore/tumor and /datastore/normal...

#key=ref_genome_path:type=text:display=F:display_name=The reference genome used in breakpointing. Only used if breakpoint=true.
#ref_genome_path=/datastore/data/hg19_1_22XYMT.fa
#key=ref_genome_gc_path:type=text:display=F:display_name=The reference genome GC file.
#ref_genome_gc_path=/datastore/data/hg19_1_22XYMT.gc

# TODO: need to be params, where are these hosted?
#http://s3.amazonaws.com/pan-cancer-data/pan-cancer-reference/genome.fa.gz
#https://s3.amazonaws.com/pan-cancer-data/pan-cancer-reference/hs37d5_1000GP.gc


my @files;
my ($output_dir, $run_id, $normal_bam, $tumor_bam, $reference_gz, $reference_gc);
my $cwd = cwd();

# workflow version
my $wfversion = "2.0.0";

GetOptions (
  "output-dir=s"  => \$output_dir,
  "run-id=s"   => \$run_id,
  "normal-bam=s" => \$normal_bam,
  "tumor-bam=s" => \$tumor_bam,
  "reference-gz=s" => \$reference_gz,
  "reference-gc=s" => \$reference_gc,
)
# TODO: need to add all the new params, then symlink the ref files to the right place
 or die("Error in command line arguments\n");

$ENV{'HOME'} = $output_dir;

# check our assumptions
run("env");
run("whoami");

# PARSE OPTIONS

system("gosu root chmod a+rwx /tmp");

# SYMLINK REF FILES
run("mkdir -p /datastore/normal/");
run("mkdir -p /datastore/tumor/");
run("ln -sf $normal_bam /datastore/normal/normal.bam");
run("ln -sf $normal_bam.bai /datastore/normal/normal.bam.bai");
run("ln -sf $tumor_bam /datastore/tumor/tumor.bam");
run("ln -sf $tumor_bam.bai /datastore/tumor/tumor.bam.bai");
run("mkdir -p /datastore/data/");
#run("ln -sf $reference_gz /datastore/data/genome.fa.gz");
#run("gunzip /datastore/data/genome.fa.gz");
system("gunzip -c $reference_gz > /datastore/data/hg19_1_22XYMT.fa");
run("ln -sf $reference_gc /datastore/data/hg19_1_22XYMT.gc");

# MAKE CONFIG
# the default config is the workflow_local.ini and has most configs ready to go
my $config = "
# # key=datastore:type=text:display=T:display_name=ID for the current run, will be used to create filenames
delly_runID=$run_id

# # key=input_bam_path_tumor:type=text:display=T:display_name=The relative tumor BAM path, directory name only
input_bam_path_tumor=tumor

# key=input_bam_path_germ:type=text:display=T:display_name=The relative germline BAM path, corresponding to the directory with the tumor BAM
input_bam_path_germ=normal

# key=datastore:type=text:display=T:display_name=path to datastore directory within the Docker container (which is tied from the upper level when running the Docker container)
datastore=/datastore/

#key=ref_genome_path:type=text:display=F:display_name=The reference genome used in breakpointing. Only used if breakpoint=true.
ref_genome_path=/datastore/data/hg19_1_22XYMT.fa
#key=ref_genome_gc_path:type=text:display=F:display_name=The reference genome GC file.
ref_genome_gc_path=/datastore/data/hg19_1_22XYMT.gc
";

open OUT, ">/datastore/workflow.ini" or die;
print OUT $config;
close OUT;

# NOW RUN WORKFLOW
# workaround for docker permissions 
run("gosu root mkdir -p $output_dir/.seqware");
run("gosu root chown -R seqware $output_dir");
run("gosu root cp /home/seqware/.seqware/settings $output_dir/.seqware");
run("gosu root chmod a+wrx $output_dir/.seqware/settings");
run("perl -pi -e 's/wrench.res/seqwaremaven/g' /home/seqware/bin/seqware");
my $error = system("seqware bundle launch --dir /home/seqware/DELLY/target/Workflow_Bundle_DELLY_".$wfversion."_SeqWare_1.1.1  --engine whitestar --ini /datastore/workflow.ini --no-metadata");

# NOW FIND OUTPUT
my $path = `ls -1t /datastore/ | grep 'oozie-' | head -1`;
chomp $path;

# MOVE THESE TO THE RIGHT PLACE
system("gosu root mv /datastore/$path/*.vcf.gz /datastore/$path/*.bedpe.txt /datastore/$path/delly_results/*.sv.cov.tar.gz /datastore/$path/delly_results/*.sv.cov.plots.tar.gz /datastore/$path/*.sv.log.tar.gz /datastore/$path/*.json $output_dir");

# RETURN RESULT
exit($error);

sub run {
  my $cmd = shift;
  print "EXECUTING CMD: $cmd\n";
  my $error = system($cmd);
  if ($error) { exit($error); }
}
