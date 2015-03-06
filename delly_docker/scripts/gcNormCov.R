args <- commandArgs(trailingOnly=T)
covFile <- args[1]
gcFile <- args[2]
outFile <- args[3]

gc <- read.delim(gcFile, as.is=T, header=F)
cov <- read.delim(covFile, as.is=T, header=F)

#numberOfDataPoints <- 5000
gc_sub <- c()
cov_sub <- c()
for (chr in unique(cov$V1)) {
	if (chr %in% c("chrX", "chrX.fa", "chrY", "chrY.fa", "chrM", "chrM.fa", "chrU", "chr2LHet", "chr2RHet", "chr3LHet", "chr3RHet", "chrXHet", "chrYHet", "U", "2LHet", "2RHet", "3LHet", "3RHet", "XHet", "YHet", "dmel_mitochondrion_genome")) {
		next
	}
	gc_sub <- rbind(gc_sub, gc[gc$V1==chr & gc$V5!=0 & cov$V4>0,])
	cov_sub <- rbind(cov_sub, cov[cov$V1==chr & gc$V5!=0 & cov$V4>0,])
}
#gc_sub <- gc_sub[cov_sub$V4<(median(cov_sub$V4)+1*sd(cov_sub$V4)),]
#cov_sub <- cov_sub[cov_sub$V4<(median(cov_sub$V4)+1*sd(cov_sub$V4)),]
#set.seed(1)
#sel <- sample(1:nrow(gc_sub), min(nrow(gc_sub),numberOfDataPoints), replace=F)
#plot(gc_sub[sel, 5], cov_sub[sel, 4], ylim=c(0,median(cov$V4)*3), xlim=c(0.2,0.7), ylab="Coverage", xlab="GC content", pch=20, cex.main=1, main="Coverage vs GC content")
#lines(smooth.spline(gc_sub[, 5], cov_sub[, 4], df=6), col="red", lwd=2)

cov$V5 <- (predict(smooth.spline(gc_sub[, 5], cov_sub[, 4], df=6),gc$V5)$y)
cov$V6 <- (cov$V4 / cov$V5) * median(cov$V4)

write.table(cov[,c(1,2,3,6)], file=outFile, sep="\t", quote=F, row.names=F, col.names=F)



