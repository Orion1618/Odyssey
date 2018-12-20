
# Overview:
# -=-=-=-=-=-

# This script will analyse PCA eigenval/eigenvec files output from Plink --pca analyses
# Specifically this script will:
  # 1) Remove outliers as determined by a set of reference samples of desired ancestry provided in a .csv that
      # was present in the PCA analysis (the FID and IID must be in the .CSV separated by comma or tab).
        # Outliers are removed based on principal components that contribute a specified percentage of total variance
        # Outliers are classified as those that lie outside a specified standard deviation of the centroid on N dimmensions
      
  # 2) Outliers are determined and plotted against the designated reference population (specified by the user via .csv),
      # and the individuals that were kept (ie. that fell withing the specified STDEV of the Ref-Pop calculated centroid)
  # 3) The list of outliers are recorded and output to a .csv file



# Load Libraries
  library(data.table)
  library(tidyr)
  library(ggplot2)
  #library(tidyverse)

  #Set Working Directory
    #setwd('/N/dc2/scratch/ryeller/Odyssey/PopStratModule/PCA_Analyses/HGDP-Euro_PCA')
  
  # Read in the Command arguments into the R environment  
    commandArgs()->args
    #args #View the arguments
  

# Load Eigenvector File
  #Eigenvector <- fread(file.choose(), sep='auto', data.table = T)
  #system(paste0("ls ", getwd(), "/*.eigenvec"), intern=TRUE)->EigenvectorFile
  system(paste0("ls ", args[6], "/*.eigenvec"), intern=TRUE)->EigenvectorFile
  Eigenvector <- fread(EigenvectorFile, sep='auto', data.table = T)
    



# Load Eigenvalue File
  #Eigenvalue <- fread(file.choose(), sep='auto', data.table = T)
  #system(paste0("ls ", getwd(), "/*.eigenval"), intern=TRUE)->EigenvalueFile
  system(paste0("ls ", args[6], "/*.eigenval"), intern=TRUE)->EigenvalueFile
  Eigenvalue <- fread(EigenvalueFile, sep='auto', data.table = T)

# Only Keep the Eigenvalues and Vectors that contribute more than 1% to the total variance in the dataset

#Calculates the percent variance of each Principal Component
  names(Eigenvalue)<-c('EigenValue')
  Eigenvalue$PercentVar=Eigenvalue$EigenValue/sum(Eigenvalue$EigenValue)

# Labels the Eigenvalue by principal component number  
  Eigenvalue[, PC := paste0("PC",seq_len(.N))]

# Keeps the Eigenvalues that contribute more than X % to the total variance observed
  #(Concat.Eigenvalue = Eigenvalue[Eigenvalue$PercentVar > 0.01, ])
  message('Eigenvalues that were Kept')
  message('--------------------------------')
  message(' ')
  
  (Concat.Eigenvalue = Eigenvalue[Eigenvalue$PercentVar > as.numeric(args[7]), ])

  message(' ')

  
# Counts the number of Eigenvalues to keep (adds 2 due to the FID and IID column) to get columns to keep
  nrow(Concat.Eigenvalue)+2->Columns2Keep

# Trims Eigenvectors to Number of Eigenvalues that are being kept
  Eigenvector[ ,1:Columns2Keep]-> Eigenvector


# Renames the header of Eigenvector to reflect the FID, IID, and the percent variance per PC
  PercentVarHeader <- c('FID', 'IID')
  PercentVarHeader <- c(PercentVarHeader, as.character(t(Concat.Eigenvalue[, 3])))
  names(Eigenvector)<-PercentVarHeader
  
# Makes the Chromosome Column as a character
  as.character(Eigenvector$FID)-> Eigenvector$FID
  as.character(Eigenvector$IID)-> Eigenvector$IID
  
  
  
  message('EigenVector Preview')
  message('--------------------------------')
  message(' ')
  Eigenvector
  message(' ')

# Calculate the Centroid of a Given Sample Set

# Load the Euro Sample List from the PopStratHelper Excel Doc  
  #CentroidSamples <- fread(file.choose(), sep='auto', header = F)
  #system(paste0("ls ", getwd(), "/*.csv"), intern=TRUE)->CentroidSamplesList
  system(paste0("ls ", args[6], "/*.csv"), intern=TRUE)->CentroidSamplesList
  CentroidSamples <- fread(CentroidSamplesList, sep='auto', data.table = T)
  
  names(CentroidSamples)<-c('FID', 'IID')
    
  # Makes the Chromosome Column as a character
      as.character(CentroidSamples$FID)-> CentroidSamples$FID
      as.character(CentroidSamples$IID)-> CentroidSamples$IID
  
# Setup Primary key for CentroidSamplesList
  setkeyv(CentroidSamples, c('FID', 'IID'))
# Setup Primary key for Eigenvectors
  setkeyv(Eigenvector, c('FID', 'IID'))

# Do InnerJoin to keep the Samples that will be used to Calculate the centroid of the PC's      
  CentroidSamples <- merge(Eigenvector, CentroidSamples, all = F)

# Calculate the Centroid for the multi-dimensional data
  message('Centroid Averages for N Dimensions')
  message('--------------------------------')

  (colMeans(CentroidSamples[, -1:-2])->CentroidAVE)
  
  message(' ')
  message(' ')
  
# Calculate STDEV of the Centroid points
  message('Centroid STDEV for N Dimensions')
  message('--------------------------------')

  (apply(CentroidSamples[, -1:-2], 2, sd)->CentroidSTDEV)
 
  message(' ')
  message(' ')
  
# Calculate Outlier Cutoffs (+/- Given STDEV)
  message('Max Centroid Cutoff')
  message('--------------------------------')

  (CentroidAVE+as.numeric(args[8])*CentroidSTDEV->MaxCutoff  )
  #(CentroidAVE+3*CentroidSTDEV->MaxCutoff  )
  
  message(' ')
  message(' ')
  
  message('Min Centroid Cutoff')
  message('--------------------------------')
  
  (CentroidAVE-as.numeric(args[8])*CentroidSTDEV->MinCutoff  )
  #(CentroidAVE-3*CentroidSTDEV->MinCutoff  )
  
  message('')
  message(' ')
  

# Removes those values in EigenVector that lie outside of a User-Specified STDEV

#Set DataTable to DataFrame
  setDF(Eigenvector)

# Determine number of PC to Analyze
  length(grep("PC", colnames(Eigenvector)))->PC2Analyze

# Keep the entries that are within the STDEV bounds
  OutliersRemoved <- Eigenvector[rowSums(mapply(between, Eigenvector[ grep("PC", colnames(Eigenvector)) ], MinCutoff, MaxCutoff)) >= PC2Analyze,]

# Get the table of outliers
  setdiff(Eigenvector, OutliersRemoved) -> Outliers 
  


#Start Plotting

# Plot the centroid samples as one color and the unknown samples as another color

  CentroidSamples$Group <- "RefPop"
  OutliersRemoved$Group <- "4Analysis"
  Outliers$Group <- "Outliers"

# Combine Dataset for Scatter Plot
  rbind.data.frame(CentroidSamples, OutliersRemoved) -> PlotMe
  rbind.data.frame(PlotMe, Outliers) -> PlotMe


# output plot as PNG
  
  message('')
  message(' ')
  message('Outputting PCA Plot')
  message('--------------------------------')
  
  options(bitmapType='cairo') 
  png(paste0(args[6], '/', 'PCA_Plot.png'))
  #png(paste0(getwd(), '/', 'PCA_Plot.png'))
  
# Change point shapes by the levels of cyl
  ggplot(PlotMe, aes(x=PC1, y=PC2, shape=Group, color=Group)) +
    geom_point()
  
  
  dev.off()
  
# Output outlying samples to exclude as well as entire Ref-Target Eigenvector Table:
  write.table(Outliers[ ,1:2], file=paste0(args[6],'/', 'AncestryOutliers.txt'), row.names=F, col.names = F, sep = "\t", quote = F )
  write.table(PlotMe, file=paste0(args[6],'/', 'PCA_CompleteTable.txt'), row.names=F, col.names = T, sep = "\t", quote = F )
  

  #write.table(Outliers[ ,1:2], file=paste0(getwd(),'/', 'AncestryOutliers.txt'), row.names=F, col.names = F, sep = "\t", quote = F )
  #write.table(PlotMe, file=paste0(getwd(),'/', 'PCA_CompleteTable.txt'), row.names=F, col.names = T, sep = "\t", quote = F )
  
  message('')
  message('--------------------------------')
  message('Done!')
  message('--------------------------------')
  message('')

