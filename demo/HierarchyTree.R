############################################################
#############    COMPUTE THE HIERARCHY TREE    ############
############################################################

  
library(rchic)
library(stringr)
require(tcltk) || stop("tcltk support is absent")


#select file
fileName <- tclvalue(tkgetOpenFile())

if (!nchar(fileName)) {
  tkmessageBox(message = "No file was selected!")
  setwd(initDirectory)
} else{
  
  
  
  #read the file
  dataCSV<-read.csv(fileName, sep=";")
  data2transac(dataCSV)
  callAsirules()
  readRulesComputeAndDisplayHierarchy()
  
}