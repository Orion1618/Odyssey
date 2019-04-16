#!/bin/bash

# Overview: Syncs your Reference Dataset with a custom genetic dataset (or more generally, combines 2 genetic datasets based on their commonalities) 

# How it works: Takes bed/bim/fam files from 2 datasets (located in the Original dataset directory)
#		and performs an inner-merge (retains variants that are common between both)
#		It does this by taking the .bim files for each of the datasets and performs an "extract" Plink command on the opposite dataset
#		Merging is then performed, including all the flips/removals that are needed to merge the two datasets.
#		File cleanup is then performed

# Link to download 1000 Genomes Reference Set: ftp://ftp.1000genomes.ebi.ac.uk/vol1/ftp/release/20130502/

#======================================
# Call Variables from Config File:
#======================================

source PopStratConfig.conf
source ../../.TitleSplash.txt

#======================================


# Splash Screen
# --------------
printf "$Logo"

printf "
          ========================================
          ----------------------------------------
          --- Population Stratification Add-In ---
          ----------------------------------------
          ========================================\n\n\n"


#Change to Working Directory then PopStrat Directory

echo
echo Changing to Pop Strat Directory
echo ----------------------------------------------
	
	
	#Get the PopStrat subdirectory as a Variable for the R script
	#-----------------------------------------
		cd $WorkingDir
		cd ./SubModules/PopStratModule
		PopStratDir=$(pwd)
		cd ${PopStratDir}
		echo ${PopStratDir}


# ----------------------------------------------------------------------------------	
# Step 1 Variant Extract:
# ----------------------------------------------------------------------------------

if [ "${VariantExtract,,}" == "t" ]; then

#Create Additional PopStrat Module Folders if they don't already exist

	echo
	echo
	echo Creating PopStrat Module Folders
	echo ----------------------------------------------
	echo 

		mkdir -p ./Merged_Target-Ref_Datasets/
		mkdir -p ./Merged_Target-Ref_Datasets-TEMP/
		mkdir -p ./PCA_Analyses/

	# Convert .bims into lists of variants (column 2 of .bim) for Ref Dataset
		echo
		echo Converting Reference Dataset Bim into a List of Variants
		echo ==================================================================
		echo
		echo
			awk -F "\t" '{print $2}' ./PLACE_Target-Ref_Datasets_HERE/${RefDataset}.bim > ./Merged_Target-Ref_Datasets-TEMP/${RefDataset}.variants

	# Convert .bims into lists of variants (column 2 of .bim) for Target Dataset
		echo
		echo Converting Target Dataset Bim into a List of Variants
		echo ==================================================================
		echo
		echo
			awk -F "\t" '{print $2}' ./PLACE_Target-Ref_Datasets_HERE/${TargetDataset}.bim > ./Merged_Target-Ref_Datasets-TEMP/${TargetDataset}.variants

	# Extract the variants of the Reference Dataset from the Target Dataset

		echo
		echo
		echo ==================================================================
		echo Extracting the variants of the Reference Dataset from the Custom Dataset
		echo ==================================================================
		echo
		
			${PlinkExec} --bfile ./PLACE_Target-Ref_Datasets_HERE/${TargetDataset} --extract ./Merged_Target-Ref_Datasets-TEMP/${RefDataset}.variants  --memory ${Max_Memory}000 --make-bed --out ./Merged_Target-Ref_Datasets-TEMP/1_${TargetDataset}_Compatible

	# Extract the variants of the Target Dataset from the Reference Dataset
	
		echo
		echo
		echo ==================================================================
		echo Extracting the variants of the Target Dataset from the Reference Dataset
		echo ==================================================================
		echo
		
			${PlinkExec} --bfile ./PLACE_Target-Ref_Datasets_HERE/${RefDataset} --extract ./Merged_Target-Ref_Datasets-TEMP/${TargetDataset}.variants  --memory ${Max_Memory}000 --make-bed --out ./Merged_Target-Ref_Datasets-TEMP/1_${RefDataset}_Compatible
fi

# ----------------------------------------------------------------------------------
# Step 2 Attempt Merger of 2 Compatible Datasets:
# ----------------------------------------------------------------------------------

if [ "${AttemptMerger,,}" == "t" ]; then

	echo
	echo
	echo ==================================================================
	echo Attempting to Merge the RefDataset and the Custom Dataset
	echo ==================================================================
	echo
		${PlinkExec} --bfile ./Merged_Target-Ref_Datasets-TEMP/1_${RefDataset}_Compatible --bmerge ./Merged_Target-Ref_Datasets-TEMP/1_${TargetDataset}_Compatible --memory ${Max_Memory}000 --make-bed --out ./Merged_Target-Ref_Datasets-TEMP/3a_${RefDataset}-${TargetDataset}_Merged

fi



# ----------------------------------------------------------------------------------
# Step 3 Troubleshoot Merger Attempt by Flipping SNPs, Removing SNPs, & then Re-Merging:
# ----------------------------------------------------------------------------------

if [ "${FlipTarget,,}" == "t" ]; then


	# Flipping Target Dataset to Try to Align to Reference Dataset
	
	echo
	echo
	echo ==================================================================
	echo Flipping Target Dataset to Try to Align to Reference Dataset
	echo ==================================================================
	echo	
		${PlinkExec} --bfile ./Merged_Target-Ref_Datasets-TEMP/1_${TargetDataset}_Compatible --flip ./Merged_Target-Ref_Datasets-TEMP/3a_${RefDataset}-${TargetDataset}_Merged-merge.missnp --make-bed --out ./Merged_Target-Ref_Datasets-TEMP/2a_${TargetDataset}_CompatibleFlip

	echo
	echo
	echo ==================================================================
	echo "Target Dataset Flipped Based on ./Merged_Target-Ref_Datasets-TEMP/3a_${RefDataset}-${TargetDataset}_Merged-merge.missnp"
	echo ==================================================================
	echo
		sleep 0.5
		
	
	# Merge the RefDataset and the Flipped Target Dataset
	echo
	echo
	echo ==================================================================
	echo Attempting to Merge the RefDataset and the Flipped Target Dataset
	echo ==================================================================
	echo
		${PlinkExec} --bfile ./Merged_Target-Ref_Datasets-TEMP/1_${RefDataset}_Compatible --bmerge ./Merged_Target-Ref_Datasets-TEMP/2a_${TargetDataset}_CompatibleFlip --make-bed --out ./Merged_Target-Ref_Datasets-TEMP/3b_${RefDataset}-${TargetDataset}_Merged
		sleep 0.5
	
	# Remove Remaining Problematic SNPS if there are any and Re-Attempting Merger
	if ls ./Merged_Target-Ref_Datasets-TEMP/3b_${RefDataset}-${TargetDataset}_Merged-merge.missnp 1> /dev/null 2>&1; then
	
		echo
		echo
		echo ==================================================================
		echo Removing Remaining Problematic SNPS
		echo ==================================================================
		echo
		
		#Remove Problematic Variants
			${PlinkExec} --bfile ./Merged_Target-Ref_Datasets-TEMP/2a_${TargetDataset}_CompatibleFlip --exclude ./Merged_Target-Ref_Datasets-TEMP/3b_${RefDataset}-${TargetDataset}_Merged-merge.missnp --make-bed --out ./Merged_Target-Ref_Datasets-TEMP/2b_${TargetDataset}_CompatibleFlip-TroubleVariantsRm
	
		echo
		echo
		echo ==================================================================
		echo Re-Attempting Merger of RefDataset and the Flipped/Problematic-Variants-Removed Target Dataset
		echo ==================================================================
		echo
		
		#Re-attempt Merged with RefDataset and Target Datset that has been flipped and the Problematic (Triallelic) Variants Removed
			${PlinkExec} --bfile ./Merged_Target-Ref_Datasets-TEMP/1_${RefDataset}_Compatible --bmerge ./Merged_Target-Ref_Datasets-TEMP/2b_${TargetDataset}_CompatibleFlip-TroubleVariantsRm --make-bed --out ./Merged_Target-Ref_Datasets/3b_${RefDataset}-${TargetDataset}_Merged
	
	else
		echo
		echo
		echo =================================================================
		echo "No Problematic SNPs to Remove -- Horray! Moving ./Merged_Target-Ref_Datasets-TEMP/3_${RefDataset}-${TargetDataset}_Merged Files to  ./Merged_Target-Ref_Datasets/"
		echo =================================================================
		echo
		mv ./Merged_Target-Ref_Datasets-TEMP/3b_${RefDataset}-${TargetDataset}_Merged* ./Merged_Target-Ref_Datasets/
	fi

fi



# ----------------------------------------------------------------------------------	
# Step 4: Prune Dataset to Include Those Not in LD as Much
# ----------------------------------------------------------------------------------

if [ "${PrepData,,}" == "t" ]; then

#Create PCA Analysis Folder within ./Odyssey/PopStratModule if it doesn't already exist

	echo
	echo
	echo Creating PCA Analysis Folder
	echo ----------------------------------------------
	echo ${WorkingDir}PopStratModule/${PCA_Analysis_Name}

		mkdir -p ./PCA_Analyses/${PCA_Analysis_Name}
		

		# QC Dataset for Missingness and HWE
	
	echo
	echo
	echo ===========================================================================
	echo Perform General QC prior to LD pruning and PCA Analysis
	echo "Dataset used is: ./Merged_Target-Ref_Datasets/3_${RefDataset}-${TargetDataset}_Merged"
	echo Plink QC Criteria: --hwe 0.0001 --mind 0.05 --geno 0.05
	echo ===========================================================================
	echo
		${PlinkExec} --bfile ./Merged_Target-Ref_Datasets/3b_${RefDataset}-${TargetDataset}_Merged --hwe 0.0001 --mind 0.1 --geno 0.1 --make-bed --out ./Merged_Target-Ref_Datasets/4_${RefDataset}-${TargetDataset}_QCMerged		

# Identify Variants in Target-Reference Merged Dataset that are in high LD
	
	echo
	echo
	echo ===========================================================================
	echo ID Variants in Target-Ref Merged Dataset [From Step 3] that are in high LD
	echo "Dataset used is: ./Merged_Target-Ref_Datasets/4_${RefDataset}-${TargetDataset}_QCMerged"
	echo Plink LD Command Criteria: --indep-pairwise 1500 150 0.4
	echo ===========================================================================
	echo
		${PlinkExec} --bfile ./Merged_Target-Ref_Datasets/4_${RefDataset}-${TargetDataset}_QCMerged --indep-pairwise 1500 150 0.4 --out ./Merged_Target-Ref_Datasets/4_${RefDataset}-${TargetDataset}_QCMerged

# Remove the Pruned Variants found in the previous step from the final EigenReady Target/Ref Merged Dataset
	
	echo
	echo
	echo ==================================================================
	echo Pruning Dataset based on variants found in prune.in file
	echo ==================================================================
	echo
		${PlinkExec} --bfile ./Merged_Target-Ref_Datasets/4_${RefDataset}-${TargetDataset}_QCMerged --extract ./Merged_Target-Ref_Datasets/4_${RefDataset}-${TargetDataset}_QCMerged.prune.in --make-bed --out ./PCA_Analyses/${PCA_Analysis_Name}/5_${RefDataset}-${TargetDataset}_PCAReady

fi


# ----------------------------------------------------------------------------------
# Step 5: Perform PCA on Merged Dataset
# ----------------------------------------------------------------------------------

if [ "${Perform_PCA,,}" == "t" ]; then

# Perform PCA on Pruned Merged Target-Ref Dataset
	
	echo
	echo
	echo ==================================================================
	echo Performing PCA on the Following Pruned Merged Target-Ref Dataset:
	echo "./PCA_Analyses/${PCA_Analysis_Name}/5_${RefDataset}-${TargetDataset}_PCAReady"
	echo Default Plink QC Performed Prior to Analysis: --mind 0.1 --geno 0.1
	echo ==================================================================
	echo
		${PlinkExec} --bfile ./PCA_Analyses/${PCA_Analysis_Name}/5_${RefDataset}-${TargetDataset}_PCAReady --pca --mind 0.1 --geno 0.1 --out ./PCA_Analyses/${PCA_Analysis_Name}/5_${RefDataset}-${TargetDataset}_PCAReady

		
fi


# ----------------------------------------------------------------------------------
# Step 6: Perform Analysis on PCA Run Completed from Step 5
# ----------------------------------------------------------------------------------

if [ "${Analyze_PCA,,}" == "t" ]; then

# Copy Hidden R Analysis File from PopStrat Directory to Specified PCA Analysis Folder

	echo
	echo 
	echo Copying R Analysis Script to Analysis Folder
	echo ----------------------------------------------
	echo
		cp .1_Analysis_OutlierDetection.R ./PCA_Analyses/${PCA_Analysis_Name}/.1_Analysis_OutlierDetection.R
	# Change permissions to be able to execute it		
		chmod -f 700 ./PCA_Analyses/${PCA_Analysis_Name}/.1_Analysis_OutlierDetection.R

# Perform Pre-Analysis Check to see if all Necessary Files are Present to Perform the Analysis/Visualization

	echo
	echo 
	echo Performing Pre-Analysis/Visualization Check for Necessary Files
	echo ---------------------------------------------------------------
	
	# Check for .R files
	if [ -f ./PCA_Analyses/${PCA_Analysis_Name}/.1_Analysis_OutlierDetection.R ]
	then echo ".R Analysis Script PRESENT"
		# Check for .eigenvalue file
		if ls ./PCA_Analyses/${PCA_Analysis_Name}/*.eigenval 1> /dev/null 2>&1
		then echo ".Eigenvalue File PRESENT"
			# Check for .eigenvector file
			if ls ./PCA_Analyses/${PCA_Analysis_Name}/*.eigenvec 1> /dev/null 2>&1
			then echo ".Eigenvector File PRESENT"
				# Check for Ancestry File (to calculate Centroid)
				if ls ./PCA_Analyses/${PCA_Analysis_Name}/*.csv 1> /dev/null 2>&1
				then echo "Ancestry .CSV File PRESENT"
					# Send the All Systems Go Message:
					echo; printf "\n All Necessary Files Present -- Proceeding with R Analysis/Visualization"
				else printf "Ancestry .CSV File ABSENT -- Upload a .CSV File to the PCA Analysis Folder that Contains Individuals for R to Calculate the Centroid for Your Choosen Ancestral Group \n\n  ---Exiting--- \n\n";exit;fi
			else printf ".Eigenvector File ABSENT -- Check PCA so it Outputs a Eigenvector File \n\n  ---Exiting--- \n\n";exit; fi
		else printf ".Eigenvalue File ABSENT -- Check PCA so it outputs a Eigenvalue file \n\n ---Exiting--- \n\n";exit; fi		
	else printf ".R Analysis Script ABSENT -- Copy Hidden .R file from PopStrat Main Directory to PCA Analysis Folder \n\n  ---Exiting--- \n\n";exit;fi

	
	echo
	echo 
	echo Executing Rscript batch script to analyze and visualize the GWAS analysis
	echo ----------------------------------------------
	echo
	

	# Executes the Rscript to analyze and visualize the GWAS analysis

		Arg6="${PopStratDir}/PCA_Analyses/${PCA_Analysis_Name}";
		Arg7="${PC_VariancePerc}"
		Arg8="${PC_StandardDev}"
		Arg9="${PC_IQRMax}"
		Arg10="${PC_IQRMin}"

		
		${Rscript} ./PCA_Analyses/${PCA_Analysis_Name}/.1_Analysis_OutlierDetection.R $Arg6 $Arg7 $Arg8 $Arg9 $Arg10  #> ./PCA_Analyses/${PCA_Analysis_Name}/Analysis_OutlierDetection.Rout



fi	
		




# ----------------------------------------------------------------------------------
# Last Step: Cleanup the File Mess Created in the TEMP Folder:
# ----------------------------------------------------------------------------------


if [ "${Cleanup}" == "T" ]; then

	# Create Folder that will house files used to merge the Ref and Custom Datasets
	# -------------------------------------------------
		echo
		echo Delete TEMP Directory
		echo

		if [ -d ./Merged_Target-Ref_Datasets-TEMP/ ]; then rm -Rf ./Merged_Target-Ref_Datasets-TEMP/; fi



fi
