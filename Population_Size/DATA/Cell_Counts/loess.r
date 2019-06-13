setwd("/Users/brittany.rife/Desktop/Cell_Counts")

N01<-read.table("N01_Cell_Counts.txt", header=T, sep='\t')
N02<-read.table("N02_Cell_Counts.txt", header=T, sep='\t')
N03<-read.table("N03_Cell_Counts.txt", header=T, sep='\t')
N04<-read.table("N04_Cell_Counts.txt", header=T, sep='\t')
N05<-read.table("N05_Cell_Counts.txt", header=T, sep='\t')
N09<-read.table("N09_Cell_Counts.txt", header=T, sep='\t')
N10<-read.table("N10_Cell_Counts.txt", header=T, sep='\t')
N12<-read.table("N12_Cell_Counts.txt", header=T, sep='\t')

N01.loess<-loess(B ~ Time, N01, control = loess.control(surface = "direct"), span=0.25)
N01.loess.predict<-predict(N01.loess, data.frame(Time = seq(0, 460, 1)), se = TRUE)

N02.loess<-loess(B ~ Time, N02, control = loess.control(surface = "direct"), span=0.25)
N02.loess.predict<-predict(N02.loess, data.frame(Time = seq(0, 204, 1)), se = TRUE)


plot(N01[,3]~N01[,1], type='l', ylim=c(0,500), ann=F)
par(new=T)
plot(N01.loess, type='l', col='red', xaxt='n', ylim=c(0,500), ann=F)
par(new=T)
plot(N01.loess.predict$fit, type='l', col='blue', xaxt='n', ylim=c(0,500))

plot(N02[,3]~N02[,1], type='l', ylim=c(0,500), ann=F)
par(new=T)
plot(N02.loess, type='l', col='red', xaxt='n', ylim=c(0,500), ann=F)
par(new=T)
plot(N02.loess.predict$fit, type='l', col='blue', xaxt='n', ylim=c(0,500))


