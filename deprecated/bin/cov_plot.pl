#!/usr/bin/perl

use strict;
use warnings;
use FindBin;

my $bin_dir = $FindBin::Bin;

my $germ_cov = $ARGV[0];
my $tumor_cov = $ARGV[1];
my $tmp_dir = $ARGV[2];

unless (-d $tmp_dir) { die "Invalid temp directory $tmp_dir"; }
unless ($tumor_cov =~ /^.*\/(\S+)\.gcnorm\.cov/) { die "Cannot extract tumor name from $tumor_cov"; }
my $tumor_name = $1;
unless ($germ_cov =~ /^.*\/(\S+)\.gcnorm\.cov/) { die "Cannot extract germ name from $germ_cov"; }
my $germ_name = $1;


my $out_file_germ = $tmp_dir . "/germ.gcnorm.cov.out";
open(OUTGERMCOV, ">$out_file_germ") or die "Cannot write to $out_file_germ";

open(REFCOV, $germ_cov) or die "Cannot read $germ_cov";
open(FILCOV, $tumor_cov) or die "Cannor read $tumor_cov";
my @scaling;
while(<REFCOV>) {
  print OUTGERMCOV;
	chomp($_);
	chomp(my $line = <FILCOV>);
	my @refcov = split(/\t/, $_);
	my @filcov = split(/\t/, $line);
	if (($refcov[3]) && ($filcov[3])) {
		push(@scaling, $filcov[3] / $refcov[3]);
	}
}
close(REFCOV);
close(FILCOV);

my $scale;
@scaling = sort(@scaling);
if (($#scaling % 2) == 0) { $scale = $scaling[int($#scaling / 2)]; }
else { $scale = ($scaling[int(scalar(@scaling) / 2)] + $scaling[int(scalar(@scaling) / 2) - 1]) / 2; }

$scale = 1 / $scale;

# Adjust coverage counts
open(FILCOV, $tumor_cov) or die "Cannot read $tumor_cov";
my $out_file_tum = $tmp_dir . "/tum.gcnorm.cov.out";
open(OUTCOV, ">$out_file_tum") or die "Cannot write to $out_file_tum";
while(<FILCOV>) {
	chomp($_);
	my @filcov = split(/\t/, $_);
	$filcov[3] = $filcov[3] * $scale;
	print OUTCOV join("\t", @filcov) ."\n";	
}
close(OUTCOV);
close(FILCOV);

#prepare the R file
my $r_file = $germ_name . "-" . $tumor_name . "-cov_plot.R";

open(OUT, ">$bin_dir/$r_file") or die "Cannot write to $bin_dir/$r_file";

print OUT "dataFile=c('tum.gcnorm.cov.out','germ.gcnorm.cov.out'); sampleNames=c('$tumor_name','$germ_name')\n";

open (IN, $bin_dir . "/read_depth_ratio_plusCovSigSeg.R") or die "Cannot read read_depth_ratio_plusCovSigSeg.R from $bin_dir";
while (<IN>) {
  if (/^LIBRARY/) {
	  print OUT "if(\"DNAcopy\" %in% rownames(installed.packages()) == FALSE) {install.packages(\"$bin_dir/DNAcopy_1.38.1.tar.gz\")}\nlibrary(\"DNAcopy\")\n";
   #print OUT "library(\"DNAcopy\", lib.loc=\"$bin_dir/DNAcopy\")\n";
	next;
  }
  print OUT;
}

#run R;
chdir $tmp_dir;
if (system("Rscript $bin_dir/$r_file")) { die "Error running $bin_dir/$r_file"; }




