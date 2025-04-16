

    rm (list = ls())
    library (ROCR); library (foreign); library (Hmisc);
    
    root <- "/users/visitor/artes/public_html/"
    setwd (paste (root, "results/", sep=""))

    plotdir <- paste (root, "downloads/", sep="")
    
    filenames <- list.files(path = paste (root, "uploads/", sep=""), pattern=".enc", all.files = FALSE, full.names = FALSE, recursive = FALSE)
    
    goldstd <- read.spss (file=paste (root, "/key/goldstandard.sav", sep=""), to.data.frame=TRUE)
    
    
    
    names (goldstd) <- tolower (names(goldstd))
    goldstd$status <- as.numeric(goldstd$status)-1
    names (goldstd)[3] <- "score"
    names (goldstd) <- tolower (names(goldstd))
    goldstd$imgname <- trim(as.character(goldstd$imgname))
    
    goldprd <- prediction  (goldstd$score, goldstd$status)
    goldprf <- performance (goldprd, "tpr", "fpr")
    goldauc <- performance (goldprd, measure="auc")

    plotROCCurveForDamian <- function (fname, plotlabel) {
    	
          d <- read.table (paste (root, "uploads/",fname, sep=""), sep='\t', header=FALSE, skip=2)
          names (d) <- c("name", "date","time", "n", "status2", "namestring", "response", "latency")
          d$status <- as.integer(d$status2)-1
          d$latency <- d$latency / 1000
          temp <- gsub(pattern="[() .]", replacement="",  x=d$namestring)
          d$imgname <- gsub(x=temp, pattern="ccc$", replacement="" )
          
          repeats <- aggregate(d$response, by=list(d$imgname), FUN="sd",na.rm=TRUE)
          diffs <- repeats$x[!is.na (repeats$x)] * sqrt (2)
          
          pred <- prediction (d$response, d$status)
          perf <- performance (pred, "tpr", "fpr" )

# for plotting: aggregate to remove repeat observations
          k <- aggregate (d, d["namestring"], tail, 1) [,1:ncol(d)+1]
          pred_2 <- prediction (k$response, k$status)
          perf_2 <- performance (pred_2, "tpr", "fpr" )
          ciy <- binconf ((perf_2@y.values[[1]]*pred_2@n.pos[[1]]), pred_2@n.pos[[1]], alpha=0.05, method="wilson", return.df=T)
          cix <- binconf ((perf_2@x.values[[1]]*pred_2@n.neg[[1]]), pred_2@n.neg[[1]], alpha=0.05, method="wilson", return.df=T)
          
          plotdir <- paste (getwd (), "/plots/", sep="")
          subjectname <- unique (d$name);
          id2 <- substr(filenames, 1, 8)

# correlation with experts
          Spear <- merge (x=d, y=goldstd, by="imgname") [,c("response","score")]      # calculate spearman
          spearman <- cor.test (x=Spear$response, y=Spear$score, method="spearman")$estimate
          rm (Spear)

          resultFilename=paste ("downloads/", filenames,".pdf", sep="")
          pdfname <- paste(root,resultFilename, sep="")          
          print (paste ("writing ", pdfname))

		  pdf (pdfname,  width = 8, height = 7, pointsize = 10)

          par (pch=19,               # plotting character: solid circle
              bty="n",               # no box
              las=1,                 # vertical labels
              tcl=-0.25,             # tickmarks not too long
              mgp=c(1.5,0.25,0),     # distance of axis title, label, line
              mar=c(4,4,1,0))

          nf <- layout(matrix(nrow=1, ncol=2, data=c(1,2)), widths = c(7.5,2.5), heights = c(8,8), respect = FALSE)
         # layout.show(nf)

# ROC curve
          par (bty="l", mar=c(5,3,1,0.5))
          plot (perf_2, colorize=TRUE, lwd=5, bty="n", colorkey=FALSE, cex=1.4, col="grey",
              xlab="positive rate in VF-negative group", ylab="positive rate in VF-positive group",
              cex.lab = 1.4)
              
          plot (goldprf, colorize=FALSE, lwd=1, col="grey", add=TRUE)
          criterionAngle <- (mean(goldstd$score)-1) * (90/4)   # most conservative = 0 = horizontal, most liberal = vertical.
          ycrit <- criterionAngle * pi / 180
          lines (x=c(1,0), y=c(0,ycrit), col="grey", lty=2)
          
          lines (x=c(cix$PointEst [3], cix$PointEst [3]), y=c(ciy$Upper[3], ciy$Lower [3]), col="darkgreen")       # vertical EB
          lines (x=c(cix$Lower [3], cix$Upper [3]), y=c(ciy$PointEst [3], ciy$PointEst [3]), col="darkgreen")      # horiz EB

          categs <- perf_2@alpha.values[[1]]
          category_labels <- c("E","D","C","B","A")
          cats <- categs[-c(1, length(categs))]
          ncats <- seq(from=2, to=length(perf_2@x.values[[1]])-1)
          text(x=perf_2@x.values[[1]][ncats], y=perf_2@y.values[[1]][ncats], labels=category_labels[cats], cex=1.5)

          criterionAngle <- (mean(k$response)-1) * (90/4)  * pi/180   # most conservative = 0 = horizontal, most liberal = vertical.
          lines (x=c(1,0), y=c(0,criterionAngle), col="red")

          auroc <- performance (pred_2, measure="auc")
                   
          seROC <- function(AUC, na, nn) {
              a <- AUC
              q1 <- a/(2-a)
              q2 <- (2*a^2)/(1+a)
              se <- sqrt((a*(1-a)+(na-1)*(q1-a^2)+(nn-1)*(q2-a^2))/(nn*na))
              se
              }
    
          auroc_se <- seROC (auroc@y.values[[1]], pred@n.pos[[1]], pred@n.pos[[1]]+pred@n.neg[[1]])
          auroc_ci <- c (auroc@y.values[[1]] - 1.96 * auroc_se, auroc@y.values[[1]] + 1.96 * auroc_se)
          ci_string <- paste ("[", signif(auroc_ci,2)[1], ", ", signif(auroc_ci,2)[2], "]", sep="")  

          percentAUC <-  ((auroc@y.values[[1]] - 0.5) * 100) / (goldauc@y.values[[1]] - 0.5)
          xright <- 1.0; ytop <- 0.65; txtcol <- "grey20";
          text (labels=paste ("AUC=", signif(auroc@y.values[[1]],2), sep=""), x=xright, y=ytop, cex=1.2, adj=c(1,1), col=txtcol)
          text (labels=paste(signif(percentAUC,2), "%", sep=""), x=xright, y=ytop-0.075, cex=1.2, adj=c(1,1), col=txtcol)
          text (labels=paste("r=", signif(spearman,2), sep=""),  x=xright, y=ytop-0.15,  cex=1.2, adj=c(1,1), col=txtcol)
          text (labels=paste("mean.Diff=", signif(mean(diffs),2), sep=""),x=xright, y=ytop-0.225, cex=1.2, adj=c(1,1), col=txtcol)
          text (labels=paste("criterion=", signif(mean(k$response)-3,2), sep=""),x=xright, y=ytop-0.300, cex=1.2, adj=c(1,1), col=txtcol)
          
          text (labels=plotlabel, x=0.025, y=0.925, cex=3, adj=c(0,0), col="black")

# response time boxplot
          par (bty="n", tcl=-0.15, las=1, mar=c(5,2.5,1,0), mgp=c(1.5,0.25,0))
          lat <- k[k$latency < 30,]
          plot (x=-1, y=-1, ylim=c(0,30), xlim=c(0.5,5.5), ylab="response latency (s)", xlab="response",
          cex.lab = 1.4, pty="n", xaxt="n", bty="n")
          lat$response <- factor (lat$response, levels=c(1,2,3,4,5))
          with (lat,boxplot (latency~response, range=1, outline=FALSE, boxwex=0.4, col="darkgreen", add=TRUE,
                names=c("dh", "ph", "ns", "pd", "dd")))
          text (x=seq(from=1, to=5), y=0, labels=hist(k$resp, breaks=c(0,1,2,3,4,5), plot=FALSE)$counts, cex=0.5)
          dev.off() 
          }
    
    for (i in 1:length(filenames)) {
        plotROCCurveForDamian (filenames[i], plotlabel <- LETTERS[i])
        }
    
    
   
