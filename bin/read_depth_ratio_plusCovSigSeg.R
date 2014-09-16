#################################
# Plots the read depth ratio
# ------------------


# Set default arguments
if (!exists("dataFile")) {
	dataFile=c('cov1','cov2');
}
if (!exists("chr")) {
	cov1 = read.table(dataFile[1]);
	chr = unique(cov1[,1])
}
if (!exists("maxRatio")) {
#	minRatio=-2.5;
	minRatio=-3;
	maxRatio=5;
}
if (!exists("minDelta")) {
  minDelta= 2;
}

if (!exists("vlines")) {
	vlines=c();
}
if (!exists("sampleNames")) {
	sampleNames=c('Tumor','Control');
}

cov1_full = read.table(dataFile[1]);
cov2_full = read.table(dataFile[2]);

### Segmentation
#if("DNAcopy" %in% rownames(installed.packages()) == FALSE) {install.packages("DNAcopy")}

#library("DNAcopy", lib.loc="opy")
LIBRARY

cbind(cov1_full, LRR=log2(cov1_full$V4/cov2_full$V4))->cov_combi
cov_combi[cov_combi=="NaN" | cov_combi=="-Inf" | cov_combi=="Inf"]<-0
CNA.object <- CNA(cov_combi[,5],
                  cov_combi[,1],
                  cov_combi[,2],
                  data.type="logratio",sampleid=sampleNames[1])

# smoothing
smoothed.CNA.object <- smooth.CNA(CNA.object)

#Segmentation at default parameters
segment.smoothed.CNA.object <- segment(smoothed.CNA.object, verbose=1)

segment.smoothed.CNA.object$output->CNA.seg



# Iterate over chromosomes
for(myChr in chr) {
	
	# Read coverage files
	cov1 = cov1_full[cov1_full[,1]==myChr,]
	cov2 = cov2_full[cov2_full[,1]==myChr,]
	cov3 = CNA.seg[CNA.seg[,2]==myChr,]
	windowsMerged = 1

	print(paste("Chromosome:",myChr,"File:",dataFile[1],"Median:",median(cov1[,4]),"Mean:",mean(cov1[,4]),"Sd:",sd(cov1[,4]),sep=' '))
	print(paste("Chromosome:",myChr,"File:",dataFile[2],"Median:",median(cov2[,4]),"Mean:",mean(cov2[,4]),"Sd:",sd(cov2[,4]),sep=' '))

	# Set window	
	if (exists("win")) {
		# If necessary increase the window size
		covWinSize = cov1[1,3] - cov1[1,2]
		while (win[2] - win[1] < 10 * covWinSize) {
			win[1] = win[1] - 100;
			win[2] = win[2] + 100;
			if (win[1] < 0) {
				win[1] = 0;
			}
		}
	       	cov1 = cov1[cov1[,2] >= win[1],]
	       	cov1 = cov1[cov1[,3] <= win[2],]
	       	cov2 = cov2[cov2[,2] >= win[1],]
	       	cov2 = cov2[cov2[,3] <= win[2],]
		size1 = win[1] + 1100
		size2 = win[2] - 1100
	}
	xnames=cov1[,2];
	logRatio=log2(cov1[,4]/cov2[,4]) 
	globalMed=median(logRatio[is.finite(logRatio)])
	

	logCov1=log2(cov1[,4])
	logCov2=log2(cov2[,4])
	winSizeInKb=(cov1[1,3]-cov1[1,2])/1000 * windowsMerged

	sig <- pmax(cov1[,4],cov2[,4]) > 20

	ymax <- max(c(logCov1[is.finite(logCov1)], logCov2[is.finite(logCov2)]))

	if (length(logRatio[is.finite(logRatio)]) > 0) {
		jpeg(paste(myChr, ".jpg", sep=""), quality=90, width=1600, height=1000);

		par(mfrow=c(3,1))
		plot(xnames, logCov2, xlim=c(min(xnames), max(xnames)), ylim=c(0,ymax), main=paste(sampleNames[2], myChr), xlab="Chromosome position", ylab=paste("Log2 #read per ", winSizeInKb, "kb", sep=""), col='black', pch=20, cex.main=1.5, cex.axis=1.5, cex.lab=1.5, cex=0.8) #, xaxt="n")
		abline(h=median(logCov2[is.finite(logCov2)]), col=colors()[230], lty=1)
		abline(h=seq(0,(as.integer(ymax)+1),2), col="gray60", lty="dotted")
		abline(v=seq(min(xnames), max(xnames), 5000000), col="gray60", lty="dotted")
		plot(xnames, logCov1, xlim=c(min(xnames), max(xnames)), ylim=c(0,ymax), main=paste(sampleNames[1], myChr), xlab="Chromosome position", ylab=paste("Log2 #read per ", winSizeInKb, "kb", sep=""), col='black', pch=20, cex.main=1.5, cex.axis=1.5, cex.lab=1.5, cex=0.8) #, xaxt="n")
		abline(h=median(logCov1[is.finite(logCov1)]), col=colors()[230], lty=1)
		abline(h=seq(0,(as.integer(ymax)+1),2), col="gray60", lty="dotted")
		abline(v=seq(min(xnames), max(xnames), 5000000), col="gray60", lty="dotted")
	  	plot(xnames[sig], logRatio[sig], xlim=c(min(xnames), max(xnames)), ylim=c(min(logRatio[is.finite(logRatio)], -minDelta, na.rm = T),max(logRatio[is.finite(logRatio)], minDelta, na.rm = T)), main=paste("log2 ratio sample vs control", myChr), xlab="Chromosome position", ylab="Log2 ratio", col='black', pch=20, cex.main=1.5, cex.axis=1.5, cex.lab=1.5, cex=0.8) #, xaxt="n")

		abline(v=seq(min(xnames), max(xnames), 5000000), col="gray60", lty="dotted")
		abline(v=vlines, col="gray60", lty=1)
		abline(h=0, col=colors()[230], lty=1)
		abline(h=c(-20:-1,1:20), col="gray60", lty="dotted")

		segments(cov3$loc.start,cov3$seg.mean,cov3$loc.end,cov3$seg.mean,lwd=3, col="firebrick2")
		
		dev.off();
	} else {
		jpeg(paste(myChr, ".jpg", sep=""), quality=100);
		plot(0,0,xlim=c(min(xnames),max(xnames)), ylim=c(globalMed-2, globalMed+2), main=myChr, xlab="Chromosome position", ylab="Log2 ratio", pch="o")
		abline(globalMed,0,col = "green", lty=2)
		dev.off();
	}
}
write.table(CNA.seg,file=paste(sampleNames[1], "_segmentation.txt", sep=""), col.names=T, row.names=F, sep="\t", quote=F)
