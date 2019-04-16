
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
  library(plotly)
  library(RColorBrewer)

#Set Working Directory
	#(MANUAL) setwd('./Odyssey/PopStratModule/PCA_Analyses/Troublemakers2')

# Read in the Command arguments into the R environment  
  commandArgs()->args
  
  args[6]->PCA_Output
  as.character(PCA_Output)->PCA_Output
    #(Manual -- Set PCA Output Directory) '/home/ryeller/scratch/GitRepos/Odyssey/SubModules/PopStratModule/PCA_Analyses/TroubleMakers/' ->PCA_Output
  
  args[7]->PC_VariancePerc
  as.numeric(PC_VariancePerc)-> PC_VariancePerc
	#(Manual -- Set PC Variance Criteria) 0.01 ->PC_VariancePerc
  
  args[8]->PC_StdDev
   as.numeric(PC_StdDev)-> PC_StdDev
	#(Manual -- Set PCA Output Directory) 2->PC_StdDev

  args[9]->PC_IQRMax
  as.numeric(PC_IQRMax)-> PC_IQRMax
	#(Manual -- Set PCA Output Directory) 0.9->PC_IQRMax

  args[10]->PC_IQRMin
  as.numeric(PC_IQRMin)-> PC_IQRMin
	#(Manual -- Set PCA Output Directory) 0.1->PC_IQRMin

# --------- Load Files -------------

# Load Eigenvector File
  #(MANUAL) Eigenvector <- fread(file.choose(), sep='auto', data.table = T)
  #(MANUAL2) system(paste0("ls ", getwd(), "/*.eigenvec"), intern=TRUE)->EigenvectorFile
  system(paste0("ls ", PCA_Output, "/*.eigenvec"), intern=TRUE)->EigenvectorFile
  Eigenvector <- fread(EigenvectorFile, sep='auto', data.table = T)



# Load Eigenvalue File
  #(MANUAL) Eigenvalue <- fread(file.choose(), sep='auto', data.table = T)
  #(MANUAL2) system(paste0("ls ", getwd(), "/*.eigenval"), intern=TRUE)->EigenvalueFile
  system(paste0("ls ", PCA_Output, "/*.eigenval"), intern=TRUE)->EigenvalueFile
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

  (Concat.Eigenvalue = Eigenvalue[Eigenvalue$PercentVar > as.numeric(PC_VariancePerc), ])
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
  system(paste0("ls ", PCA_Output, "/*.csv"), intern=TRUE)->CentroidSamplesList
  CentroidSamples <- fread(CentroidSamplesList, sep='auto', data.table = T, header=F)

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

# -------------- Calculate the Mean, Median, SD, and IQR of the Centroid of a Given Sample Set ----------------
  
# Calculate the Centroid Means for the multi-dimensional data
  message('Centroid Means for N Dimensions')
  message('--------------------------------')

	(colMeans(CentroidSamples[, -1:-2])->CentroidAVE)
	
	  message(' \n\n')

# Calculate the Centroid Medians for the multi-dimensional data
	message('Centroid Medians for N Dimensions')
	message('--------------------------------')
  
		lapply(CentroidSamples[, -1:-2], IQR) -> CentroidMEDIAN
		(as.data.frame(CentroidMEDIAN))
	
	message('\n\n')


# Calculate STDEV for the multi-dimensional data
	message('Centroid STDEV for N Dimensions')
	message('--------------------------------')

	(apply(CentroidSamples[, -1:-2], 2, sd)->CentroidSTDEV)
	
	message('\n\n')
  
 # Calculate SD Outlier Cutoffs (+/- Given STDEV)
	message('Min Centroid SD Cutoff')
	message('--------------------------------')

		(CentroidAVE-as.numeric(PC_StdDev)*CentroidSTDEV->MinCutoff  )
			#(MANUAL -- set STDEV -- default == 3) (CentroidAVE-3*CentroidSTDEV->MinCutoff  )
	message('\n\n')
  
	message('Max Centroid SD Cutoff')
	message('--------------------------------')

		(CentroidAVE+(as.numeric(PC_StdDev)*CentroidSTDEV)->MaxCutoff  )
			#(MANUAL -- set STDEV -- default == 3) (CentroidAVE+3*CentroidSTDEV->MaxCutoff  )
	message('\n\n')
  
  
  
 # Calculate IQR Cutoffs (+/- Given IQR's)
	message('Min Centroid IQR Cutoff -- [%] [raw values]')
	message('--------------------------------')
		lapply(CentroidSamples[, -1:-2],quantile,probs=PC_IQRMin) -> CentroidIQRMin
			(as.data.frame(CentroidIQRMin))
  
	message('\n\n')

	message('Max Centroid IQR Cutoff -- [%] [raw values]')
	message('--------------------------------')	
		lapply(CentroidSamples[, -1:-2],quantile,probs=PC_IQRMax) -> CentroidIQRMax
			(as.data.frame(CentroidIQRMax))

	message('\n\n')





# -------------------- Removes the Outliers -------------------

# Or Remove Individual EigenVectors that lie outside of the User-Specified Centroid (either via SD or IQR)
  
#Set DataTable to DataFrame
  setDF(Eigenvector)

# Determine number of PC to Analyze
  length(grep("PC", colnames(Eigenvector)))->PC2Analyze

# Keep the entries that are within the STDEV bounds
	OutliersRemoved_SD <- Eigenvector[rowSums(mapply(between, Eigenvector[ grep("PC", colnames(Eigenvector)) ], MinCutoff, MaxCutoff)) >= PC2Analyze,]
	
	write.table(OutliersRemoved_SD[,1:2], file=paste0(PCA_Output, '/', 'OutliersRemoved_SD.txt'), row.names = F, col.names = F, quote = F)
  
 # Keep the entries that are within the IQR bounds
	OutliersRemoved_IQR <- Eigenvector[rowSums(mapply(between, Eigenvector[ grep("PC", colnames(Eigenvector)) ], CentroidIQRMin, CentroidIQRMax)) >= PC2Analyze,]
  
	write.table(OutliersRemoved_IQR[,1:2], file=paste0(PCA_Output, '/', 'OutliersRemoved_IQR.txt'), row.names = F, col.names = F, quote = F)


# Get the table of SD Outliers
  #(Legacy Code) Eigenvector[!(Eigenvector$IID %in% OutliersRemoved_SD$IID ),] -> Outliers
	Outliers_SD<- anti_join(Eigenvector, OutliersRemoved_SD, by= c('FID', 'IID'))
	
	write.table(Outliers_SD[,1:2], file=paste0(PCA_Output, '/', 'CompleteOutliers_SD.txt'), row.names = F, col.names = F, quote = F)
  
 # Get the table of IQR Outliers
	Outliers_IQR <- anti_join(Eigenvector, OutliersRemoved_IQR, by= c('FID', 'IID'))
  
	write.table(Outliers_IQR[,1:2], file=paste0(PCA_Output, '/', 'CompleteOutliers_IQR.txt'), row.names = F, col.names = F, quote = F)


# ----------------------- Start Plotting the Standard Deviation Graphs ----------------------------

# Remove Referenece People  from Outliers Removed to Get just those for analysis
  JustAnalysis_SD<- anti_join(OutliersRemoved_SD, CentroidSamples, by= c('FID', 'IID'))

# Label the Individuals as Reference, Outliers, or Samples for Analysis
  CentroidSamples$Group <- "RefPop"
  JustAnalysis_SD$Group <- "4Analysis"
  Outliers_SD$Group <- "Outliers"

  
# Combine Dataset for Scatter Plot
  rbind.data.frame(CentroidSamples, JustAnalysis_SD) -> PlotMe_SD
  rbind.data.frame(PlotMe_SD, Outliers_SD) -> PlotMe_SD


# Output plot as PNG
# -------------------

  message('')
  message(' ')
  message('Outputting PCA Plot for SD Based Pop Strat')
  message('-------------------------------------------')

  options(bitmapType='cairo') 
  png(paste0(PCA_Output, '/', 'PCA-sd_Plot.png'))
  #(MANUAL -- plots in current working directory) png(paste0(getwd(), '/', 'PCA-sd_Plot.png'))

  
# Change point shapes by the levels of cyl
  ggplot(PlotMe_SD, aes(x=PC1, y=PC2, shape=Group, color=Group)) +
  geom_point()


  dev.off()

# Output outlying samples to exclude as well as entire Ref-Target Eigenvector Table:
  write.table(Outliers_SD[ ,1:2], file=paste0(PCA_Output,'/', 'AncestryOutliers-sd.txt'), row.names=F, col.names = F, sep = "\t", quote = F )
  
  write.table(PlotMe_SD, file=paste0(PCA_Output,'/', 'PCA-sd_CompleteTable.txt'), row.names=F, col.names = T, sep = "\t", quote = F )

  #(MANUAL -- writes to current working directory) write.table(Outliers[ ,1:2], file=paste0(getwd(),'/', 'AncestryOutliers-sd.txt'), row.names=F, col.names = F, sep = "\t", quote = F )
  #(MANUAL -- writes to current working directory) write.table(PlotMe, file=paste0(getwd(),'/', 'PCA-sd_CompleteTable.txt'), row.names=F, col.names = T, sep = "\t", quote = F )
  
  
# Output plot as Interactive Plotly
# -----------------------------------

#Load in the eigenvector file (should contain headers -- e.g. PC1, PC2, PC3, and Grouping variable as Group)
	#(MANUAL -- Load eigenvector + grouping file)  Plotme <- fread(file.choose(), sep='auto', data.table = T, header=T)

# Make pretty colors groups
	n <- 60
	qual_col_pals = brewer.pal.info[brewer.pal.info$category == 'qual',]
	col_vector = unlist(mapply(brewer.pal, qual_col_pals$maxcolors, rownames(qual_col_pals)))


# Make the ploty 3D scatterplot (using PC1=X, PC2=Y, PC3=Z, using the most destinctive color categories -- up to 60 color groups)

p_SD <- plot_ly(PlotMe_SD, x = ~PC1, y = ~PC2, z = ~PC3, color = ~Group, colors = "Set1", marker = list(size=2),
 text = ~paste0('FID:IID', FID, ":", IID)) %>%
  add_markers() %>%
  layout(scene = list(xaxis = list(title = 'PC1'),
                      yaxis = list(title = 'PC2'),
                      zaxis = list(title = 'PC3')))
					  
					  
# Make as many colors as there are samples
#p <- plot_ly(PlotMe, x = ~PC1, y = ~PC2, z = ~PC3, color = ~Group, colors = sample(col_vector, 3), marker = list(size=2),
 #text = ~paste0('FID:IID', FID, ":", IID)) %>%
  #add_markers() %>%
  #layout(scene = list(xaxis = list(title = 'PC1'),
   #                   yaxis = list(title = 'PC2'),
    #                  zaxis = list(title = 'PC3')))

# visualize the Plot locally on R
	#p

# Save Plot to current working directory
# Plotely Dependencies will be plotted in the Directory where plot is saved
	htmlwidgets::saveWidget(p_SD, paste0(PCA_Output, '/PCA-sd_Plot.html'), libdir = paste0(PCA_Output, '/1PlotlyDependencies/'), selfcontained=FALSE) 

  message('')
  message(' ')
  message('Summary of Standard Deviation PopStrat')
  message('========================================')
  message(paste('Individuals used as a reference:', nrow(CentroidSamples) ))
  message(paste('Individuals deemed as outliers from given standard deviation (includes Samples from Ref Set and Target Set):',nrow(Outliers_SD) ))
  message(paste('Individuals kept for analysis:', nrow(OutliersRemoved_SD)))
  message('')
  message('')
  
  
  # ----------------------- Start Plotting the IQR Graphs ----------------------------

# Remove Referenece People  from Outliers Removed to Get just those for analysis
  JustAnalysis_IQR<- anti_join(OutliersRemoved_IQR, CentroidSamples, by= c('FID', 'IID'))

# Label the Individuals as Reference, Outliers, or Samples for Analysis
  #CentroidSamples$Group <- "RefPop"
  JustAnalysis_IQR$Group <- "4Analysis"
  Outliers_IQR$Group <- "Outliers"

  
# Combine Dataset for Scatter Plot
  rbind.data.frame(CentroidSamples, JustAnalysis_IQR) -> PlotMe_IQR
  rbind.data.frame(PlotMe_IQR, Outliers_IQR) -> PlotMe_IQR


# Output plot as PNG
# -------------------

  message('')
  message(' ')
  message('Outputting PCA Plot')
  message('--------------------------------')

  options(bitmapType='cairo') 
  png(paste0(PCA_Output, '/', 'PCA-iqr_Plot.png'))
  #(MANUAL -- plots in current working directory) png(paste0(getwd(), '/', 'PCA-iqr_Plot.png'))

  
# Change point shapes by the levels of cyl
  ggplot(PlotMe_IQR, aes(x=PC1, y=PC2, shape=Group, color=Group)) +
  geom_point()


  dev.off()

# Output outlying samples to exclude as well as entire Ref-Target Eigenvector Table:
  write.table(Outliers_IQR[ ,1:2], file=paste0(PCA_Output,'/', 'AncestryOutliers-iqr.txt'), row.names=F, col.names = F, sep = "\t", quote = F )
  write.table(PlotMe_IQR, file=paste0(PCA_Output,'/', 'PCA-iqr_CompleteTable.txt'), row.names=F, col.names = T, sep = "\t", quote = F )

 
# Output plot as Interactive Plotly
# -----------------------------------

#Load in the eigenvector file (should contain headers -- e.g. PC1, PC2, PC3, and Grouping variable as Group)
	#(MANUAL -- Load eigenvector + grouping file)  Plotme_IQR <- fread(file.choose(), sep='auto', data.table = T, header=T)

# Make pretty colors groups
	n <- 60
	qual_col_pals = brewer.pal.info[brewer.pal.info$category == 'qual',]
	col_vector = unlist(mapply(brewer.pal, qual_col_pals$maxcolors, rownames(qual_col_pals)))


# Make the ploty 3D scatterplot (using PC1=X, PC2=Y, PC3=Z, using the most destinctive color categories -- up to 60 color groups)

p_IQR <- plot_ly(PlotMe_IQR, x = ~PC1, y = ~PC2, z = ~PC3, color = ~Group, colors = "Set1", marker = list(size=2),
 text = ~paste0('FID:IID', FID, ":", IID)) %>%
  add_markers() %>%
  layout(scene = list(xaxis = list(title = 'PC1'),
                      yaxis = list(title = 'PC2'),
                      zaxis = list(title = 'PC3')))

# visualize the Plot locally on R
	#p

# Save Plot to current working directory
# Plotely Dependencies will be plotted in the Directory where plot is saved
	htmlwidgets::saveWidget(p_IQR, paste0(PCA_Output, '/PCA-iqr_Plot.html'), libdir = paste0(PCA_Output, '/1PlotlyDependencies/'), selfcontained=FALSE) 
  
  
  
  
  

  message('')
  message(' ')
  message('Summary of Interquartile Range PopStrat')
  message('========================================')
  message(paste('Individuals used as a reference:', nrow(CentroidSamples) ))
  message(paste('Individuals deemed as outliers from given IQR (includes Samples from Ref Set and Target Set):',nrow(Outliers_IQR) ))
  message(paste('Individuals kept for analysis:', nrow(OutliersRemoved_IQR)))
  message('')
  message('')


  message('')
  message('--------------------------------')
  message('Done!')
  message('--------------------------------')
  message('')
  

  
  
  

