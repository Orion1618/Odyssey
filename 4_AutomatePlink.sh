#!/bin/bash

## Overview:
## ==================

## This script will:
# 1. Setup a GWAS Project with the GWAS Folder
# 2. Call a dosage VCF from the Imputation Project
# 3. Perform a GWAS analysis on the data given a phenotype file
# 4. Visualize the analysis using R


# Call Variables from Config file
# ----------------------------
	source Programs.conf
	source Config.conf
	source .TitleSplash.txt


# Splash Screen
# --------------
printf "$Logo"

	
# Set Working Directory
# -------------------------------------------------
	echo
	echo Changing to Working Directory
	echo ----------------------------------------------
	echo ${WorkingDir}
	echo
	
		cd ${WorkingDir}

	echo
	echo Creating Scripts/Results/Output/Dataset Folder within the GWAS Project Directory
	echo ---------------------------------------------------------------------------------
	echo

		mkdir -p ./GWAS/${GWASRunName}_Analysis
		mkdir -p ./GWAS/Datasets
		

	
#Get the GWAS subdirectory as a Variable for R script
#-----------------------------------------

    cd ./GWAS/${GWASRunName}_Analysis
    GWASSubDir=$(pwd)
	cd ${WorkingDir}
	

#Get the DosageVCF to be analyzed and load into a variable for the R script
#-----------------------------------------
if [ "${GWASOverride,,}" == "t" ]; then

	echo
	echo Performing Manual GWAS File Input
	echo ---------------------------------- 
	echo Converting VCF Dosage file specified in Config.conf via file path to a Plink Dosage PGEN
	echo

		VCF_Input=$ManualVCFInput
		Sex_Input=$ManualSexInput
		
	cd ${WorkingDir}

	
else

	echo
	echo Performing Default GWAS File Input
	echo ----------------------------------- 
	echo Converting VCF Dosage File specified in Config.conf by the Imputation Project to a Plink Dosage PGEN
	echo

		VCF_Input=$"`find ./Impute/${ImputationProject2Analyze}/ConcatImputation -maxdepth 1 -type f -name '1DONE*'`"
		Sex_Input=$"`find ./Target/${ImputationProject2Analyze} -maxdepth 1 -type f -name 'Ody1_*QC2.fam'`"		

fi



#-----------------------------------------
# Create Script to Visualize output in R
#-----------------------------------------

echo "
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

		system('echo Phew, Finished!')"> ${GWASSubDir}/2_R-WorkerFile.r



#-------------------------
# Create Plink Script:
#-------------------------


if [ "${VCF2PGEN,,}" == "t" ]; then

	echo
	echo Creating Script to Convert Dosage VCF to PGEN 
	echo And also running the GWAS
	echo ----------------------------------------------
	echo


	#Script to convert VCF to PGEN Conversion AND Specified GWAS
	#------------------------------------------------------------

	echo "#!/bin/bash

# Change to Working Directory
cd ${WorkingDir}


# Convert VCF to PGEN

time ${Plink2_Exec} \
--vcf ${VCF_Input} \
--id-delim _ \
--update-sex ${Sex_Input} col-num=5 \
--memory ${Max_Memory}000 require \
--make-pgen \
--out ./GWAS/Datasets/${BaseName}

# GWAS Script:

time ${Plink2_Exec} \
${PLINK_OPTIONS} \
--pfile ./GWAS/Datasets/${BaseName} \
--pheno ./GWAS/Phenotype/${Pheno_File} \
--pheno-name ${GWASPhenoName} \
--threads ${GWAS_Threads} \
--memory ${Max_Memory}000 require \
--out ${GWASSubDir}/${GWASRunName}

## Visualize Data Script that runs R Script
#============================================

	cd ${GWASSubDir}
	

	# Executes the R CMD batch command to analyze and visualize the GWAS analysis
		${R_Exec} CMD BATCH --no-save 2_R-WorkerFile.r"> ${GWASSubDir}/1_${GWASRunName}_Analyze-Visualize.sh

	#Change Permission Level in Order to Run the New Script
		chmod 744 ${GWASSubDir}/1_${GWASRunName}_Analyze-Visualize.sh

elif [ "${VCF2PGEN,,}" == "f" ]; then

	#Script to create Specified GWAS ONLY
	#-------------------------------------

	echo
	echo Creating Script to Run the GWAS
	echo --------------------------------
	echo

echo "#!/bin/bash


# Change to Working Directory
cd ${WorkingDir}

# GWAS Script:

time ${Plink2_Exec} \
${PLINK_OPTIONS} \
--pfile ./GWAS/Datasets/${BaseName} \
--pheno ./GWAS/Phenotype/${Pheno_File} \
--pheno-name ${GWASPhenoName} \
--threads ${GWAS_Threads} \
--memory ${Max_Memory}000 require \
--out ${GWASSubDir}/${GWASRunName}

## Visualize Data Script that runs R Script
#============================================

	cd ${GWASSubDir}
	

	# Executes the R CMD batch command to analyze and visualize the GWAS analysis
		${R_Exec} CMD BATCH --no-save 2_R-WorkerFile.r"> ${GWASSubDir}/1_${GWASRunName}_Analyze-Visualize.sh

	#Change Permission Level in Order to Run the New Script
		chmod 744 ${GWASSubDir}/1_${GWASRunName}_Analyze-Visualize.sh

else

	echo
	echo User Input Not Recognized -- Please specify T or F
	echo Exiting script creation
	echo

fi


# Execute GWAS?
#----------------

if [ "${ExecuteGWASScripts,,}" == "t" ]; then


		if [ "${HPS_Submit,,}" == "t" ]; then

			echo
			echo Submitting Plink Analysis and R Visualization scripts to HPC Queue
			echo
				qsub -l nodes=1:ppn=${GWAS_Threads},vmem=${Max_Memory}gb,walltime=${Max_Walltime} -M ${Email} -m ae -j oe -o ${GWASSubDir}/Plink.out -N ${GWASRunName} ${GWASSubDir}/1_${GWASRunName}_Analyze-Visualize.sh

		elif [ "${HPS_Submit,,}" == "f" ]; then
			echo
			echo Submitting Plink Analysis and R Visualization scripts to Desktop Queue
			echo
				sh ${GWASSubDir}/1_${GWASRunName}_Analyze-Visualize.sh
				
		else
				echo
				echo User Input Not Recognized -- Please specify T or F
				echo Exiting script submission
				echo
	
		fi
fi	
	


	
# Termination Message
	echo
	echo
	echo "Done!"
	echo ---------
	echo
	echo
	


        
        