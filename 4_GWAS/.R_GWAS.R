
# ------------------------------------------------------------------
# ==================================================================
#                         GWAS Analysis Script
# ==================================================================
# ------------------------------------------------------------------

# Read in the Command arguments into the R environment  
	commandArgs()-> args
	args[6]->WorkingDir
	args[7]->VCF2PGEN
	args[8]->Sex_Input
	args[9]->GWAS_Memory
	args[10]->GWAS_Walltime
	args[11]->GWASSubDir
	args[12]->PLINK_OPTIONS
	args[13]->GWASPhenoName
	args[14]->GWAS_Threads
	args[15]->GWASRunName
	args[16]->BaseName
	args[17]->Pheno_File
	args[18]->VCF_Input
	
	
	'plink2'->plink
	
	#args


	# Load R Prerequisite Packages
		cat('\n\nLoading Prerequisite Packages\n')
		cat('==================================\n\n')

		library(data.table)
		library(qqman)
		library(stringr)
		library(manhattanly)

	# Set Working Directory
		setwd(WorkingDir)
	
# ========================================
# Convert VCF to Dosage Plink Option:
# ========================================
		
if (VCF2PGEN=="T" || VCF2PGEN=="t")
	{
		# Convert VCF to Plink Dosage PGEN
		cat("\n\nConverting VCF to Plink Dosage PGEN:\n")
		cat("============================================\n")
		
		system(paste0("time ", plink, " --vcf ", VCF_Input, " --id-delim _ --update-sex ", Sex_Input, " col-num=5 --memory ",GWAS_Memory, "000 require --make-pgen --out ./4_GWAS/Datasets/", BaseName))

		#time plink --vcf ${VCF_Input} --id-delim _ --update-sex ${Sex_Input} col-num=5 --memory GWAS_Memory000 require --make-pgen --out ./4_GWAS/Datasets/${BaseName}
		
	} else if (VCF2PGEN=="F" || VCF2PGEN=="f") {
		# Do Not Convert VCF to Plink Dosage PGEN
		cat("\n\nWill Not Convert VCF to Plink Dosage PGEN:\n")
		cat("==================================================\n")
		
	} else {
		# Return Error Message -- User Input Not Recognized
		cat("\n\nUser Input Not Recognized: Specify Either T or F in Settings.conf -- Exiting...\n")
		cat("==============================================================================\n")
	}		
	
		
# ========================================
# Perform GWAS on the PGEN:
# ========================================
	
# Pre-GWAS Check
# ---------------
	cat("\n\nPerforming Pre-GWAS Checks\n")
	cat("================================\n")
	
	# Check PGEN file is present
		PGEN_Check <- file_test("-f", paste0("./4_GWAS/Datasets/", BaseName, ".pgen"))
		cat(paste("\nChecking for PGEN existence in Dataset Folder:", PGEN_Check, "\n"))
		cat("--------------------------------------------------\n")
		paste0("./4_GWAS/Datasets/", BaseName, ".pgen")
	
	# Check PHENO file is present
		Pheno_Check <-file_test("-f", paste0("./4_GWAS/Phenotype/", Pheno_File))
		cat(paste("\n\nChecking for Pheno file existence in Phenotype Folder:", Pheno_Check, "\n"))
		cat("--------------------------------------------------\n")
		paste0("./4_GWAS/Phenotype/", Pheno_File)
	
	# Check Sample Sex file is present
		Sex_Check <-file_test("-f", paste0(Sex_Input))
		cat(paste("\n\nChecking for Sample-Sex file existence in Phenotype Folder:", Sex_Check, "\n"))
		cat("--------------------------------------------------\n")
		paste0(Sex_Input)
		
		
# List Missing Files if Missing
if (PGEN_Check == "TRUE" && Pheno_Check == "TRUE" && Sex_Check == "TRUE")
	{
	# Passed File Check Continue
		cat("\n\nAll Necessary Files Files are present. Proceeding with GWAS:\n")
		cat("==============================================================\n")
				
	# Perform the GWAS
	# ------------------
	
	# Set PGEN path as variable
		PGEN_FILE_PATH <- paste0("./4_GWAS/Datasets/", BaseName)
	
	# Set Pheno path as variable
		PHENO_FILE_PATH <- paste0("./4_GWAS/Phenotype/", Pheno_File)
		
	# Run GWAS using all the variables specified in Settings.conf
		system(paste0(plink, " --pfile ", PGEN_FILE_PATH, " --pheno ",PHENO_FILE_PATH, " --pheno-name ", GWASPhenoName, " ", PLINK_OPTIONS, " --threads ", GWAS_Threads, " --memory ", GWAS_Memory, "000 require --out ", GWASSubDir, "/", GWASRunName))
	cat("\n=================================================\n\n\n")
	
# ========================================
# Analyze -- Visualize GWAS Results:
# ========================================	
cat(paste0('\nBeginning Analysis of GWAS Results:\n'))
cat("=================================================\n")

	#Navigate to the GWAS Folder Output Folder

		cat(paste0('\n\nChanging to GWAS Directory: \n', GWASSubDir))
		setwd(GWASSubDir)
		cat('\n----------------------------------\n\n')

# Gather Necessary Files for GWAS
	cat(paste0('\nLooking Up Files for GWAS Analysis\n'))
	cat('----------------------------------\n\n')		
	
	#Get Log File From Plink Output
		system(paste0("ls ", getwd(), "/*.log", "| awk -F/ '{print $NF}'"), intern=TRUE)->ConcatenatedLogName
		system(paste0("ls ", getwd(), "/*.log"), intern=TRUE)->FullLogName
		system(paste0("grep 'Results written to ' ", FullLogName), intern=TRUE)->OutputFileUnclean

	#Get the Output from the LogFile
		str_extract_all(OutputFileUnclean, "([^/]*.$)")->ResultsOutputFile
		str_extract_all(ResultsOutputFile, "^(.*? )")->ResultsOutputFile 
		trimws(ResultsOutputFile)->ResultsOutputFile

	#Load the Results Data:
		cat(paste0('\nLoading Plink GWAS Analysis File\n'))
		cat('----------------------------------\n\n')		
	
		fread(paste0(getwd(), '/', ResultsOutputFile), header = T, na.strings='NA')->GWASResults

# Clean Input Files
	# Trim data to exclude NA pvalues
		cat('\nTrimming data to exclude null p-values\n')
		cat('----------------------------------\n\n')
		TrimAnalysis<-GWASResults[which(GWASResults$P!='NA'), ]

	# Return number of rows in datasheet to append to CSV output name
		nrow(TrimAnalysis)->ntests

	# Calculate Multiple Testing Criteria
		cat('\nAdding Multiple Testing Adjustments: Bonferroni and Benjamini-Hochberg\n')
		cat('----------------------------------\n\n')
	
	# Perform Multiple Testing Correction (Bonferroni and Benjamini-Hochberg)	
		TrimAnalysis$Bonf = p.adjust(TrimAnalysis$P, method = 'bonferroni')
		TrimAnalysis$BH = p.adjust(TrimAnalysis$P, method = 'BH')
      
	# Order the Results by unadjusted p-values
		TrimAnalysis<-TrimAnalysis[order(TrimAnalysis$P)]

	# Extract the 10000 lowest unadjusted p-values
		TrimAnalysis[1:10000,]->AbbreviatedResults
      

	# Fix any non-R-standard names and rename the columns as such (Chrom is one of these columns)
		make.names(colnames(AbbreviatedResults))->colnames(AbbreviatedResults)
		colnames(AbbreviatedResults)[colnames(AbbreviatedResults)=='X.CHROM'] <- 'CHROM'

	# Replace non-numeric 'X' in chr column and replace with 23
		AbbreviatedResults$CHROM[AbbreviatedResults$CHROM=='X']<-23

	# Check to see if columns are factors or numeric
		#str(AbbreviatedResults)

	# Makes the Chromosome Column numeric (since we've replaced the 'OX' entry with 23)
		as.numeric(AbbreviatedResults$CHROM)->AbbreviatedResults$CHROM

	# Write the results to a CSV in the Results Folder	
		cat('\n\nWriting Results to Results Folder\n')
		cat('----------------------------------\n\n')
		write.csv(AbbreviatedResults, file=paste0(getwd(),'/', 'AbbrevResults','_',ntests,'_Top10000Results.csv'), row.names=F)
	
	# Write the results to a Tab Delimited .txt in the Results Folder	
		write.table(AbbreviatedResults, file=paste0(getwd(),'/', 'AbbrevResults','_',ntests,'_Top10000Results.txt'), row.names=F, quote=F, sep='\t')


	# Create qqPlot from the trimmed dataset (dataset that doesn't contain null p-values and filtered for low info scores)
		cat('\nCreating qqPlot from Trimmed Dataset\n')
		cat('----------------------------------\n\n')

		options(bitmapType='cairo') 
		png(paste0(getwd(), '/', GWASRunName, '_QQ_Plot.png'))
			qq(TrimAnalysis$P, main = paste0('QQPlot'))
		dev.off()
	
	# Create Plotly Manhattan Plot
	# ==============================
		# Using the AbbreviatedResults  
		# Using Bonferroni genome-wide significance line (as deemed by the number of tests run by the TrimAnalysis dataset)
		# TrimAnalysis dataset only removes the tests that were deemed NA by SNPTEST or p-values whose info score <0.7

		cat('\nCreating Interactive Plotly Manhattan Plot\n')
		cat('\nOutput is an Interactive .html that must be viewed in the same location as its corresponding 1PlotlyDependencies directory\n')
		cat('-------------------------------------------\n\n')

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
			htmlwidgets::saveWidget(ShapeShift_Manhattan, paste0(getwd(), '/',GWASRunName, '_Manhattan-Plot.html'), libdir = paste0(getwd(), '/1PlotlyDependencies/'), selfcontained=FALSE) 

	# GZip the original results file    
		cat('\nZipping the Plink Results file\n')
		cat('----------------------------------\n\n')

		system(paste0('gzip ', getwd(), '/', ResultsOutputFile))
		
	# Move GWAS Results into 5_QuickResults Folder -- create the directory from the BaseName variable if one does not yet exist
		cat('\nCopying Results to 5_QuickResults Folder\n')
		cat('-------------------------------------------\n\n')
		
		system(paste0('mkdir -p ', WorkingDir, '5_QuickResults/', BaseName, '/GWAS_Results/', GWASRunName, '/'))
		system(paste0('cp -R ', GWASSubDir, '/', ' ', WorkingDir, '5_QuickResults/', BaseName, '/GWAS_Results/', GWASRunName, '/'))

		cat('\nFinished with Data Analysis -- Visualization!\n\n')

} else {
	# Did not Pass File Check: List Files that are Present
	cat("\n\nAll GWAS Files are NOT Present: Exiting\n")
	cat("==========================================\n")
}
