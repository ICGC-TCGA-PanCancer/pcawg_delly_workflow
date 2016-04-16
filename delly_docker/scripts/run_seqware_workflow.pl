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
# # key=input_bam_path_tumor:type=text:display=T:display_name=The relative tumor BAM path, directory name only
input_bam_path_tumor=907c95e8-217c-4434-8b1d-3550507f0b80

# key=input_bam_path_germ:type=text:display=T:display_name=The relative germline BAM path, corresponding to the directory with the tumor BAM
input_bam_path_germ=b8a9dda5-8299-4fe4-8964-d248bb24bb95

# key=datastore:type=text:display=T:display_name=path to datastore directory within the Docker container (which is tied from the upper level when running the Docker container)
datastore=/datastore/

# so for the above, the path is the directory that contains the BAM file... I could do something like /datastore/tumor and /datastore/normal...

#key=ref_genome_path:type=text:display=F:display_name=The reference genome used in breakpointing. Only used if breakpoint=true.
ref_genome_path=/datastore/data/hg19_1_22XYMT.fa
#key=ref_genome_gc_path:type=text:display=F:display_name=The reference genome GC file.
ref_genome_gc_path=/datastore/data/hg19_1_22XYMT.gc

# TODO: need to be params, where are these hosted?
http://s3.amazonaws.com/pan-cancer-data/pan-cancer-reference/genome.fa.gz
https://s3.amazonaws.com/pan-cancer-data/pan-cancer-reference/hs37d5_1000GP.gc 




my @files;
my ($reference_gz, $reference_gz_fai, $reference_gz_amb, $reference_gz_ann, $reference_gz_bwt, $reference_gz_pac, $reference_gz_sa);
my $cwd = cwd();

# workflow version
my $wfversion = "2.6.8";

GetOptions (
  "file=s"   => \@files,
  "reference-gz=s" => \$reference_gz,
  "reference-gz-fai=s" => \$reference_gz_fai,
  "reference-gz-amb=s" => \$reference_gz_amb,
  "reference-gz-ann=s" => \$reference_gz_ann,
  "reference-gz-bwt=s" => \$reference_gz_bwt,
  "reference-gz-pac=s" => \$reference_gz_pac,
  "reference-gz-sa=s" => \$reference_gz_sa,
)
# TODO: need to add all the new params, then symlink the ref files to the right place
 or die("Error in command line arguments\n");

# PARSE OPTIONS
my $file_str = join ",", @files;
my @metadata;
my @download;
for (my $i=0; $i<scalar(@files); $i++) {
  # we're not using these so just pad them with URLs
  push @metadata, "https://gtrepo-ebi.annailabs.com/cghub/metadata/analysisFull/87bad5b8-bc1f-11e3-a065-b669c091c278";
  push @download, "https://gtrepo-ebi.annailabs.com/cghub/data/analysis/download/87bad5b8-bc1f-11e3-a065-b669c091c278";
}
my $metadata_str = join ",", @metadata;
my $download_str = join ",", @download;

# SYMLINK REF FILES
run("mkdir -p /home/seqware/Seqware-BWA-Workflow/target/Workflow_Bundle_BWA_".$wfversion."_SeqWare_1.1.1/Workflow_Bundle_BWA/".$wfversion."/data/reference/bwa-0.6.2/");
run("ln -s $reference_gz /home/seqware/Seqware-BWA-Workflow/target/Workflow_Bundle_BWA_".$wfversion."_SeqWare_1.1.1/Workflow_Bundle_BWA/".$wfversion."/data/reference/bwa-0.6.2/genome.fa.gz");
run("ln -s $reference_gz_fai /home/seqware/Seqware-BWA-Workflow/target/Workflow_Bundle_BWA_".$wfversion."_SeqWare_1.1.1/Workflow_Bundle_BWA/".$wfversion."/data/reference/bwa-0.6.2/genome.fa.gz.fai");
run("ln -s $reference_gz_amb /home/seqware/Seqware-BWA-Workflow/target/Workflow_Bundle_BWA_".$wfversion."_SeqWare_1.1.1/Workflow_Bundle_BWA/".$wfversion."/data/reference/bwa-0.6.2/genome.fa.gz.64.amb");
run("ln -s $reference_gz_ann /home/seqware/Seqware-BWA-Workflow/target/Workflow_Bundle_BWA_".$wfversion."_SeqWare_1.1.1/Workflow_Bundle_BWA/".$wfversion."/data/reference/bwa-0.6.2/genome.fa.gz.64.ann");
run("ln -s $reference_gz_bwt /home/seqware/Seqware-BWA-Workflow/target/Workflow_Bundle_BWA_".$wfversion."_SeqWare_1.1.1/Workflow_Bundle_BWA/".$wfversion."/data/reference/bwa-0.6.2/genome.fa.gz.64.bwt");
run("ln -s $reference_gz_pac /home/seqware/Seqware-BWA-Workflow/target/Workflow_Bundle_BWA_".$wfversion."_SeqWare_1.1.1/Workflow_Bundle_BWA/".$wfversion."/data/reference/bwa-0.6.2/genome.fa.gz.64.pac");
run("ln -s $reference_gz_sa /home/seqware/Seqware-BWA-Workflow/target/Workflow_Bundle_BWA_".$wfversion."_SeqWare_1.1.1/Workflow_Bundle_BWA/".$wfversion."/data/reference/bwa-0.6.2/genome.fa.gz.64.sa");

print "REFERENCE DIRECTORY:\n/home/seqware/Seqware-BWA-Workflow/target/Workflow_Bundle_BWA_".$wfversion."_SeqWare_1.1.1/Workflow_Bundle_BWA/".$wfversion."/data/reference/bwa-0.6.2/\n";
system("ls -lth /home/seqware/Seqware-BWA-Workflow/target/Workflow_Bundle_BWA_".$wfversion."_SeqWare_1.1.1/Workflow_Bundle_BWA/".$wfversion."/data/reference/bwa-0.6.2/");

# MAKE CONFIG
# the default config is the workflow_local.ini and has most configs ready to go
my $config = "
# these make sure S3 and GNOS are not used
useGNOS=true
use_gtdownload=false
use_gtupload=false
use_gtvalidation=false

# don't cleanup the BAMS, we need them after the workflow runs!
cleanup=false

# key=input_bam_paths:type=text:display=T:display_name=The relative BAM paths which are typically the UUID/bam_file.bam for bams from a GNOS repo if use_gtdownload is true. If use_gtdownload is false these should be full paths to local BAMs.
input_bam_paths=$file_str

# key=input_file_urls:type=text:display=T:display_name=The URLs (comma-delimited) that are used to download the BAM files. The URLs should be in the same order as the BAMs for input_bam_paths. These are not used if use_gtdownload is false.
input_file_urls=$download_str

# key=gnos_input_metadata_urls:type=text:display=T:display_name=The URLs (comma-delimited) that are used to download the BAM files. The URLs should be in the same order as the BAMs for input_bam_paths. Metadata is read from GNOS regardless of whether or not bams are downloaded from there.
gnos_input_metadata_urls=$metadata_str

# key=output_dir:type=text:display=F:display_name=A local file path if chosen rather than an upload to a GNOS server
output_dir=/

# key=output_prefix:type=text:display=F:display_name=The output_prefix is a convention and used to specify the root of the absolute output path
output_prefix=$cwd/
";

open OUT, ">workflow.ini" or die;
print OUT $config;
close OUT;

# NOW RUN WORKFLOW
my $error = system("seqware bundle launch --dir /home/seqware/Seqware-BWA-Workflow/target/Workflow_Bundle_BWA_".$wfversion."_SeqWare_1.1.1 --engine whitestar --ini workflow.ini --no-metadata");

# NOW FIND OUTPUT
my $path = `ls -1t /datastore/ | grep 'oozie-' | head -1`;
chomp $path;

# MOVE THESE TO THE RIGHT PLACE
system("mv /datastore/$path/data/merged_output.bam* $cwd");
system("mv /datastore/$path/data/merged_output.unmapped.bam* $cwd");

# RETURN RESULT
exit($error);

sub run {
  my $cmd = shift;
  my $error = system($cmd);
  if ($error) { exit($error); }
}
