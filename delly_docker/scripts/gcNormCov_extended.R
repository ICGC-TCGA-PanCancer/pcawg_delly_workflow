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

# multisamples
n_tum = ncol(cov_trim)-4
tum_list = list()
tum_list[[1]] = cov_trim[,c(1:3)]
for (tum in 1:n_tum){
	tumcol=tum  + 4
	cov_sub_trim = cov_trim[,c(1:4, tumcol)]
	gc_sub <- c()
	cov_sub <- c()
	for (chr in unique(cov_sub_trim[,1])) {
	  gc_sub <- rbind(gc_sub, gc[gc[,1]==chr & gc[,5]!=0 & cov_sub_trim[,5]>0,])
	  cov_sub <- rbind(cov_sub, cov_sub_trim[cov_sub_trim[,1]==chr & gc[,5]!=0 & cov_sub_trim[,5]>0,])
	}
	cov_sub_trim$gc_factor <- (predict(smooth.spline(gc_sub[, 5], cov_sub[,5], df=6),gc[,5])$y)
	cov_sub_trim$gc_norm <- (cov_sub_trim[,5] / cov_sub_trim$gc_factor) * median(cov_sub_trim[,5])
	tum_list[[tum+1]] = cov_sub_trim[,5]
}
cov_trim_out = do.call(cbind.data.frame, tum_list)
names(cov_trim_out) = c(names(cov_trim_out[c(1:3)]), paste("T0",seq(1,n_tum), sep=""))
#write.table(cov_trim[,c(1:5,7)], file=outFile, sep="\t", quote=F, row.names=F, col.names=T)
write.table(cov_trim_out, file=outFile, sep="\t", quote=F, row.names=F, col.names=F)

cat("\nFile written:", outFile, "\n\ndone!\n\n")
