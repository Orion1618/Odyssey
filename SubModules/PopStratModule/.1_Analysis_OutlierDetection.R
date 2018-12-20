
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

# NOTE: Commented out sections labeled (MANUAL) are for manual interactive execution


# --------- Setup -------------

# Load the Libraries
  library(data.table)
  library(tidyr)
  library(ggplot2)
  library(tidyverse)

#Set Working Directory
	#(MANUAL) setwd('/N/dc2/scratch/ryeller/Odyssey/PopStratModule/PCA_Analyses/HGDP-Euro_PCA')

# Read in the Command arguments into the R environment  
  commandArgs()->args

# --------- Load Files -------------

# Load Eigenvector File
  #(MANUAL) Eigenvector <- fread(file.choose(), sep='auto', data.table = T)
  #(MANUAL2) system(paste0("ls ", getwd(), "/*.eigenvec"), intern=TRUE)->EigenvectorFile
  system(paste0("ls ", args[6], "/*.eigenvec"), intern=TRUE)->EigenvectorFile
  Eigenvector <- fread(EigenvectorFile, sep='auto', data.table = T)



# Load Eigenvalue File
  #(MANUAL) Eigenvalue <- fread(file.choose(), sep='auto', data.table = T)
  #(MANUAL2) system(paste0("ls ", getwd(), "/*.eigenval"), intern=TRUE)->EigenvalueFile
  system(paste0("ls ", args[6], "/*.eigenval"), intern=TRUE)->EigenvalueFile
  Eigenvalue <- fread(EigenvalueFile, sep='auto', data.table = T)


# ------------- Keep Eigenvalues that Contribute Significantly to Total Variance ----------------

  
# Calculates the percent variance of each Principal Component
  names(Eigenvalue)<-c('EigenValue')
  Eigenvalue$PercentVar=Eigenvalue$EigenValue/sum(Eigenvalue$EigenValue)

# Labels the Eigenvalue by principal component number  
  Eigenvalue[, PC := paste0("PC",seq_len(.N))]

# Keeps the Eigenvalues that contribute more than X % to the total variance observed

  message('Eigenvalues that were Kept')
  message('--------------------------------')
  message(' ')

  (Concat.Eigenvalue = Eigenvalue[Eigenvalue$PercentVar > as.numeric(args[7]), ])
  #(MANUAL - set Percent Variance to Keep - default == 0.01)(Concat.Eigenvalue = Eigenvalue[Eigenvalue$PercentVar > 0.01, ])
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

# -------------- Calculate the Centroid (Exclusion Criteria) of a Given Sample Set ----------------

# Load the Euro Sample List from the PopStratHelper Excel Doc  
  #(MANUAL) CentroidSamples <- fread(file.choose(), sep='auto', header = F)
  #(MANUAL2) system(paste0("ls ", getwd(), "/*.csv"), intern=TRUE)->CentroidSamplesList
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
  #(MANUAL -- set STDEV -- default == 3) (CentroidAVE+3*CentroidSTDEV->MaxCutoff  )

  message(' ')
  message(' ')

  message('Min Centroid Cutoff')
  message('--------------------------------')

  (CentroidAVE-as.numeric(args[8])*CentroidSTDEV->MinCutoff  )
  #(MANUAL -- set STDEV -- default == 3) (CentroidAVE-3*CentroidSTDEV->MinCutoff  )

  message('')
  message(' ')


# ----------- Removes the Outliers ------------
# Or Remove Individual EigenVectors that lie outside of the User-Specified Centroid
  
#Set DataTable to DataFrame
  setDF(Eigenvector)

# Determine number of PC to Analyze
  length(grep("PC", colnames(Eigenvector)))->PC2Analyze

# Keep the entries that are within the STDEV bounds
  OutliersRemoved <- Eigenvector[rowSums(mapply(between, Eigenvector[ grep("PC", colnames(Eigenvector)) ], MinCutoff, MaxCutoff)) >= PC2Analyze,]


# Get the table of outliers
  #(Legacy Code) Eigenvector[!(Eigenvector$IID %in% OutliersRemoved$IID ),] -> Outliers
  Outliers<- anti_join(Eigenvector, OutliersRemoved, by= c('FID', 'IID'))



# --------- Start Plotting -------------

# Remove Referenece People  from Outliers Removed to Get just those for analysis
  JustAnalysis<- anti_join(OutliersRemoved, CentroidSamples, by= c('FID', 'IID'))

# Label the Individuals as Reference, Outliers, or Samples for Analysis
  CentroidSamples$Group <- "RefPop"
  JustAnalysis$Group <- "4Analysis"
  Outliers$Group <- "Outliers"

  
# Combine Dataset for Scatter Plot
  rbind.data.frame(CentroidSamples, JustAnalysis) -> PlotMe
  rbind.data.frame(PlotMe, Outliers) -> PlotMe


# Output plot as PNG

  message('')
  message(' ')
  message('Outputting PCA Plot')
  message('--------------------------------')

  options(bitmapType='cairo') 
  png(paste0(args[6], '/', 'PCA_Plot.png'))
  #(MANUAL -- plots in current working directory) png(paste0(getwd(), '/', 'PCA_Plot.png'))

  
# Change point shapes by the levels of cyl
  ggplot(PlotMe, aes(x=PC1, y=PC2, shape=Group, color=Group)) +
  geom_point()


  dev.off()

# Output outlying samples to exclude as well as entire Ref-Target Eigenvector Table:
  write.table(Outliers[ ,1:2], file=paste0(args[6],'/', 'AncestryOutliers.txt'), row.names=F, col.names = F, sep = "\t", quote = F )
  write.table(PlotMe, file=paste0(args[6],'/', 'PCA_CompleteTable.txt'), row.names=F, col.names = T, sep = "\t", quote = F )

  #(MANUAL -- writes to current working directory) write.table(Outliers[ ,1:2], file=paste0(getwd(),'/', 'AncestryOutliers.txt'), row.names=F, col.names = F, sep = "\t", quote = F )
  #(MANUAL -- writes to current working directory) write.table(PlotMe, file=paste0(getwd(),'/', 'PCA_CompleteTable.txt'), row.names=F, col.names = T, sep = "\t", quote = F )

  message('')
  message(' ')
  message('Summary of PopStrat')
  message('======================')
  message(paste('Individuals used as a reference:', nrow(CentroidSamples) ))
  message(paste('Individuals deemed as outliers (includes Samples from Ref Set and Target Set):',nrow(Outliers) ))
  message(paste('Individuals kept for analysis:', nrow(OutliersRemoved)))
  message('')
  message('')


  message('')
  message('--------------------------------')
  message('Done!')
  message('--------------------------------')
  message('')

