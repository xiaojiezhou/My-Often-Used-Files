




############
#USER INPUT
############

path<-"Q:\\clinical\\Biometrics\\XiaojieZhou\\SAS_R Code\\R Code\\Barplot1\\Plots"

setwd(path)

require(XLConnect)


wb = loadWorkbook("Q:\\clinical\\Biometrics\\HairBiology\\Studies\\2012\\CRB 12-10-106 OSLO\\Xiaojie\\Plots\\Summary - Plots.xlsx", create = TRUE)

indata = readWorksheet(wb, sheet = "BL HDvsLDvsND",  startRow=2, endRow = 36, startCol = 1, endCol = 45, header=TRUE)
dimnames(indata)
indata<-indata[!is.na(indata[,1]),]


indata = indata[,c(2:5,15,17,26,33,40)]
head(indata)

indata$MeasureGroup<-retains(indata$MeasureGroup)
indata$NewMeasure<-retains(indata$NewMeasure)
indata$Pvalue.Diff.ALL.DATA = c2n.pvalue(indata$Pvalue.Diff.ALL.DATA)
indata$Pvalue.Diff.ALL.DATA.1 = c2n.pvalue(indata$Pvalue.Diff.ALL.DATA.1)
indata$Pvalue.Diff.ALL.DATA.2 = c2n.pvalue(indata$Pvalue.Diff.ALL.DATA.2)


names(indata)[7]<-paste("Pvalue.HDvsLD")
names(indata)[8]<-paste("Pvalue.HDvsND")
names(indata)[9]<-paste("Pvalue.LDvsND")

# add pvalue HD vs ND; 


DvsND = readWorksheet(wb, sheet = "BL DvsND",  startRow=3, endRow = 23, startCol = 1, endCol = 30, header=TRUE)
DvsND = DvsND[,c(4,27)]
DvsND$NewMeasure<-retains(DvsND$NewMeasure)
DvsND[,2] = c2n.pvalue(DvsND[,2])
DvsND<-DvsND[!is.na(DvsND[,2]),]
names(DvsND)[2]<-paste("Pvalue.DvsND")
head(DvsND)

#Left outer: merge(x = df1, y = df2, by = "CustomerId", all.x=TRUE)
BL = merge(x = indata, y = DvsND, by = "NewMeasure", all.x=TRUE)
BL$Pvalue.DvsND[BL$Population!="HghDndrff"]=NA
BL=BL[order(BL$MeasureGroup, BL$NewMeasure, BL$Population),]
BL=BL[with(BL, order(MeasureGroup, NewMeasure, Population)),]


dimnames(BL)
head(BL)


library(gplots)

##################################################################
#### Prepare data for plotting #####


names(BL)[5]<-paste("bar.height")
names(BL)[6]<-paste("se")

names(BL)[4]<-paste("trts")
names(BL)[1]<-paste("group1.names")
# names(BL)[3]<-paste("group2.names")

names(BL)[10]<-paste("cfb.probt")
names(BL)[10]<-paste("trtcmp.pvalue")


####################
# png(file="Baseline Value - ASFS Ins.png", width = 800, height = 600)
 par(mfrow=c(1,3), mar=c(10,4,3,3), oma=c(0,0,8,0))

#------#
bar.spc <-c(1,1,1)
bar.color<-c("deepskyblue4", "aliceblue","purple")
plotdata=BL[BL$group1.name=="Org_AsfsTotal" ,]
bar.plot1(trts=plotdata$trts, 
          text1.side=3,
          text1.line=-3.5,
          text1.names=  paste("p(HD vs LD) =",plotdata$Pvalue.HDvsLD[!is.na(plotdata$Pvalue.HDvsLD)]),
          text1.hpos=c(2.5),

          text2.side=3,
          text2.line=-2,
          text2.names= paste("p(D vs ND) =", plotdata$trtcmp.pvalue[!is.na(plotdata$trtcmp.pvalue)]),
          text2.hpos=c(2.5),
          
          bar.color=bar.color,
          ymax=35,
          ylabel.left=("ASFS")

#------#
bar.spc <-c(1,1)
bar.color<-c("deepskyblue4", "aliceblue")
plotdata=BL[BL$group1.name=="Log10_AquaTewl" ,]
bar.plot1(trts=plotdata$trts, 
          text3.side=3,
          text3.line=-3.5,
          text3.names= paste("p(HD vs LD) =", plotdata$Pvalue.HDvsLD[!is.na(plotdata$Pvalue.HDvsLD)]),
          text3.hpos=c(1.5),
          bar.color=bar.color,
          ylabel.left="Aqua Tewl (log10)", 
          ymin=1.2,
          ymax=1.4)

plotdata=BL[BL$group1.name=="Org_ScalpSense" ,]
bar.plot1(trts=plotdata$trts, 
          text3.side=3,
          text3.line=-3.5,
          text3.names=  paste("p(HD vs LD)=",plotdata$Pvalue.HDvsLD[!is.na(plotdata$Pvalue.HDvsLD)]),
          text3.hpos=c(1.5),
          bar.color=bar.color,
          ylabel.left="Scalp Sense")

title("Baseline Values", outer=TRUE, cex.main=3)
dev.off()


############## Function Begin: Simple Bar Function ############
bar.plot1 <- function(trts=plotdata$trts, 
                      text1.names= c("", ""),
                      text1.hpos=c(1,3),
                      text1.side=1,
                      text1.line=1,
                      text2.names= c("", ""),
                      text2.hpos=c(1,3),
                      text2.side=1,
                      text2.line=-1,
                      text3.names= c("", ""),
                      text3.hpos=c(1,3),
                      text3.side=3,
                      text3.line=1,
                      text4.names= c("", ""),
                      text4.hpos=c(1,3),
                      text4.side=3,
                      text4.line=-1,
                     bar.height=plotdata$bar.height, 
                     ci.u = plotdata$bar.height +  plotdata$se,
                     ci.l = plotdata$bar.height -  plotdata$se,                    
                     bar.color=bar.color, 
                     bar.spc=bar.spc, 
                     ymin=floor(min(plotdata$bar.height-plotdata$se)), 
                     ymax=ceiling(max(plotdata$bar.height+plotdata$se)), 
                     ylabel.left="Left Label", 
                     arrow="--------------------------", 
                     ylable.right="",
                     main.title="", 
                     subtitle=""){
  
  
  ntrts = length(trts)
  ntext1 = length(text1.names)
  ntext2 = length(text2.names)
  ntext3 = length(text3.names)
  ntext4 = length(text4.names)
    
  bp<-barplot2(as.numeric(bar.height), col=bar.color, 
               space=bar.spc,xpd=F,plot.ci = TRUE,ci.l = ci.l, ci.u = ci.u,
               plot.grid = TRUE,cex.axis = 1, ylim=c(ymin,ymax))
  
  mtext(side=2, text=paste(ylabel.left), cex=1.5, line=2.2,font=2)
  mtext(side=4, text=paste(arrow), line=1, cex=2)
  mtext(side=4, text=paste(ylable.right),line=1.5, cex=1.5,font=4)
  
  
  #  Add text1-text4
  for (i in 1:ntext1){
    # i=1
    mtext(side = text1.side, at=bp[text1.hpos[i]], text=paste(text1.names[i]), cex=1, font=4, adj=NA, line=text1.line, col="deepskyblue4")
  }
  #  Add text2
  for (i in 1:ntext2){
    mtext(side = text2.side, at=bp[text2.hpos[i]], text=paste(text2.names[i]), cex=1, font=4, adj=NA, line=text2.line,col="blue")
  }
  #  Add text3
  for (i in 1:ntext3){
    mtext(side = text3.side, at=bp[text3.hpos[i]], text=paste(text3.names[i]), cex=1, font=4, adj=0, line=text3.line, col="deepskyblue4")
  }
  #  Add text4
  for (i in 1:ntext4){
   mtext(side = text4.side, at=bp[text4.hpos[i]], text=paste(text4.names[i]), cex=1.2, font=2, adj=NA, line=text4.line,col="green")
  }
  
  # Add Trt label 
  #---------------Paramerter may need to adjust----------------#
  ##### trt.yadj: adjust vertically  #####
  ##### trt.xadj: adjust horizontally  #####
  #------------------------------------------------------------#  
  trt.xadj<-0.75
  trt.yadj<-0.05
  for (tr in 1:length(trts)){  #  tr<-1
    text(x=bp[tr],y=ymin-trt.yadj*(max(bar.height)-min(bar.height)), 
         paste(trts[tr]),pos=4, col="black",cex=1.5,srt=-55, xpd=TRUE,font=4)        
  }
  
  box()
  
  # Main title (Top) & subtitle (bottom)
  title(paste(main.title), sub=paste(subtitle), cex.main=2, font.main = 4, col.main="black",  
                          cex.sub=1, font.sub=3, col.sub="black" )  

}
############## Function End: Simple Bar Function ############
