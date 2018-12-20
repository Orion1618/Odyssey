	# Load R ( Uncomment these lines for interactive version only)
		#module load r/3.3.1
		#R
		
		# Update all packages -- it helps if things are up-to-date since this will prevent depreciation errors

		#install.packages( 
    	#	lib  = lib <- .libPaths()[1],
    	#	pkgs = as.data.frame(installed.packages(lib), stringsAsFactors=FALSE)$Package,
		#	type = 'source')

	
	
	# Tries to load the packages if they don't exist (install location is not included as this can't be automated)
		#This should have been done already as specified in Programs.conf, but if its not then this will try and automate the install

		#if(!require(tidyverse)) {install.packages('tidyverse', dependencies=T, repos='https://ftp.ussg.iu.edu/CRAN/', lib ='/gpfs/home/r/y/ryeller/Carbonate/Programs/R/R-3.5.1/library')}

		#if(!require(data.table)) {install.packages('data.table', repos='https://ftp.ussg.iu.edu/CRAN/', dependencies=TRUE)}
		
		#if(!require(qqman)) {install.packages('qqman', repos='https://ftp.ussg.iu.edu/CRAN/', dependencies=TRUE)}
		
		#if(!require(manhattanly)) {install.packages('manhattanly', repos='https://ftp.ussg.iu.edu/CRAN/', dependencies=TRUE)}
		

	# Load R Prerequisite Packages
		system('echo Loading Prerequisite Packages')
    
		library(data.table)
		library(qqman)
		library(stringr)
		library(manhattanly)


	#Navigate to the GWAS Folder Output Folder

		setwd('${GWASSubDir}')
		getwd()

	#Get Log File From Plink Output
		system(paste0(\"ls \", getwd(), \"/*.log\", \"| awk -F/ '{print \$NF}'\"), intern=TRUE)->ConcatenatedLogName
		system(paste0(\"ls \", getwd(), \"/*.log\"), intern=TRUE)->FullLogName

		system(paste0(\"grep 'Results written to ' \", FullLogName), intern=TRUE)->OutputFileUnclean

	#Get the Output from the LogFile
		str_extract_all(OutputFileUnclean, \"([^/]*.\$)\")->ResultsOutputFile
		str_extract_all(ResultsOutputFile, \"^(.*? )\")->ResultsOutputFile 
        trimws(ResultsOutputFile)->ResultsOutputFile

	#Load the Results Data:
		fread(paste0(getwd(), '/', ResultsOutputFile), header = T, na.strings='NA')->GWASResults


	# Trim data to exclude NA pvalues
		system('echo Trimming data to exclude null p-values')
		TrimAnalysis<-GWASResults[which(GWASResults\$P!='NA'), ]

	# Return number of rows in datasheet to append to CSV output name
		nrow(TrimAnalysis)->ntests

	# Calculate Multiple Testing Criteria
		system('echo Add Multiple Testing Adjustments')
	
	# Perform Multiple Testing Correction (Bonferroni and Benjamini-Hochberg)	
		TrimAnalysis\$Bonf = p.adjust(TrimAnalysis\$P, method = 'bonferroni')
		TrimAnalysis\$BH = p.adjust(TrimAnalysis\$P, method = 'BH')
      
	# Order the Results by unadjusted p-values
		TrimAnalysis<-TrimAnalysis[order(TrimAnalysis\$P)]

	# Extract the 10000 lowest unadjusted p-values
		TrimAnalysis[1:10000,]->AbbreviatedResults
      

	# Fix any non-R-standard names and rename the columns as such (Chrom is one of these columns)
		make.names(colnames(AbbreviatedResults))->colnames(AbbreviatedResults)
		colnames(AbbreviatedResults)[colnames(AbbreviatedResults)=='X.CHROM'] <- 'CHROM'

	# Replace non-numeric 'X' in chr column and replace with 23
		AbbreviatedResults\$CHROM[AbbreviatedResults\$CHROM=='X']<-23

	# Check to see if columns are factors or numeric
		#str(AbbreviatedResults)

	# Makes the Chromosome Column numeric (since we've replaced the 'OX' entrie with 23)
		as.numeric(AbbreviatedResults\$CHROM)->AbbreviatedResults\$CHROM

	# Write the results to a CSV in the Results Folder	
		system('echo Writing Results to Results Folder')
		write.csv(AbbreviatedResults, file=paste0(getwd(),'/', 'AbbrevResults','_',ntests,'_Top10000Results.csv'), row.names=F)
	
	# Write the results to a Tab Delimited .txt in the Results Folder	
		write.table(AbbreviatedResults, file=paste0(getwd(),'/', 'AbbrevResults','_',ntests,'_Top10000Results.txt'), row.names=F, quote=F, sep='\t')


	# Create qqPlot from the trimmed dataset (dataset that doesn't contain null p-values and filtered for low info scores)
		system('echo Creating qqPlot from Trimmed Dataset')

	options(bitmapType='cairo') 
	png(paste0(getwd(), '/', '${GWASRunName}_QQ_Plot.png'))
		qq(TrimAnalysis\$P, main = paste0('QQPlot'))
	dev.off()
	
	# Create Plotly Manhattan Plot
	# ==============================
		# Using the AbbreviatedResults  
		# Using Bonferroni genome-wide significance line (as deemed by the number of tests run by the TrimAnalysis dataset)
		# TrimAnalysis dataset only removes the tests that were deemed NA by SNPTEST or p-values whose info score <0.7


	# Make pretty colors for the Manhattan plot chromosome points
		rainbow(13)->colors
  
	# Create Manhattan Plot
		#Set Genome-wide line to the Bonferroni adjustment using # of tests reported in TrimAnalysis Dataset
	#Don't set title
		ShapeShift_Manhattan = manhattanly(manhattanr(AbbreviatedResults, title=' ', chr = 'CHROM', bp = 'POS', p = 'P', snp = 'ID', annotation1='POS', annotation2 = 'Bonf'), col=c(colors))

	# Visualize the Manhattan Plot
		#ShapeShift_Manhattan

	# Save Manhattan-Plot to Results Folder
		# Plotely Dependencies will be plotted in the Directory where plot is saved
			htmlwidgets::saveWidget(ShapeShift_Manhattan, paste0(getwd(), '/${GWASRunName}_Manhattan-Plot.html'), libdir = paste0(getwd(), '/1PlotlyDependencies/'), selfcontained=FALSE) 

	# GZip the original results file    
		system(paste0('gzip ', getwd(), '/', ResultsOutputFile))

		system('echo Phew, Finished!')