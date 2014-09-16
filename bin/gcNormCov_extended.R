#args = c("/icgc/dkfzlsdf/analysis/prostate/weischej/results/cov/ICGC_PCA009_T01/ICGC_PCA009_N01/ICGC_PCA009_N01_10kb.cov", "/icgc/dkfzlsdf/analysis/prostate/weischej/data/refgenomes/hg19_chr1_22XYM.gc", "/icgc/dkfzlsdf/analysis/prostate/weischej/results/cov/ICGC_PCA009_T01/ICGC_PCA009_N01/ICGC_PCA009_N01_10kb.gcnorm.cov")
args <- commandArgs(trailingOnly=T)
covFile <- args[1]
gcFile <- args[2]
outFile <- args[3]
#covFile = ""
cat("###\t","gc normalization for coverage track:", covFile, "\t###\n\n")
gc <- read.delim(gcFile, as.is=T, header=F)
cov <- read.delim(covFile, as.is=T, header=T)

cov_trim = cov[cov[,1] %in% unique(gc[,1]),]
cat("gc norm compare:", nrow(cov_trim) == nrow(gc), "\n")

# avoid unequal data frames, eg with truncated cov file.
min_len = min(nrow(cov_trim), nrow(gc))
cov_trim = cov_trim[1:min_len,]
gc = gc[1:min_len,]


gc_sub <- c()
cov_sub <- c()
for (chr in unique(cov_trim[,1])) {
  cat("chrom", chr, "\n")
  gc_sub <- rbind(gc_sub, gc[gc[,1]==chr & gc[,5]!=0 & cov_trim[,5]>0,])
  cov_sub <- rbind(cov_sub, cov_trim[cov_trim[,1]==chr & gc[,5]!=0 & cov_trim[,5]>0,])
}


cov_trim$gc_factor <- (predict(smooth.spline(gc_sub[, 5], cov_sub[,5], df=6),gc[,5])$y)
cov_trim$gc_norm <- (cov_trim[,5] / cov_trim$gc_factor) * median(cov_trim[,5])

#write.table(cov_trim[,c(1:5,7)], file=outFile, sep="\t", quote=F, row.names=F, col.names=T)
write.table(cov_trim[,c(1:3,7)], file=outFile, sep="\t", quote=F, row.names=F, col.names=F)

cat("\nFile written:", outFile, "\n\ndone!\n\n")
