#!/bin/bash


# =================
## IMPORTANT NOTES:
# =================

# The bed/bim/fam trio must have the proper variant ID's as identified by NCBI (otherwise fixing the data to the reference will likely not work)
# You also need to make sure that you have the proper reference build in relation to your genetic data you are trying to fix (don't try and fix GRCh37 data to a GRCh38 reference)

# =================
## DEPENDENCIES:
# =================

# BCFtools v1.8 or later and the BCFtools plugin +fixref
# htslib v1.8 or later -- which is a BCFTools dependency



# Splash Screen
# --------------
	source .TitleSplash.txt
	printf "$Logo"

# Source from .config files (Program options via Settings.conf & Program execs via Programs.conf)
# ----------------------------
	source Settings.conf
	
	# Load Odysseys Dependencies -- pick from several methods
	if [ "${OdysseySetup,,}" == "one" ]; then
		echo
		printf "\n\nLoading Odyssey's Singularity Container Image \n\n"
		source ./Configuration/Setup/Programs-Singularity.conf
	
	elif [ "${OdysseySetup,,}" == "two" ]; then
		echo
		printf "\n\nLoading Odyssey's Manually Configured Dependencies \n\n"
		source ./Configuration/Setup/Programs-Manual.conf
	else

		echo
		echo User Input Not Recognized -- Please specify One or Two
		echo Exiting Dependency Loading
		echo
		exit
	fi


# Set Working Directory
# -------------------------------------------------
echo
echo Changing to Working Directory
echo ----------------------------------------------
echo ${WorkingDir}

	cd ${WorkingDir}

	
#Get the BaseName of the Data Placed in the PLACE_DATA_2B_FIXED_HERE -- must have a Plink .bim file in the folder
RawData="$(ls ./0_DataPrepModule/PLACE_DATA_2B_FIXED_HERE/*.bim | awk -F/ '{print $NF}' | awk -F'.' '{print $1}')"

# Controls whether BCFTools +Fixref is performed on the dataset

if [ "${PerformFixref,,}" == "t" ]; then
	echo "Performing BCFTools +Fixref on dataset in ./0_DataPrepModule/PLACE_DATA_2B_FIXED_HERE/"
		echo ----------------------------------------------
		
	#Make Temp Directory in which all Temp files will populate
		mkdir -p ./0_DataPrepModule/TEMP

	# Download all the Reference Data to Reformat the files
	# ----------------------------------------------------------------------------
	
	if [ "${DownloadRef,,}" == "t" ]; then
	
		echo
		echo Downloading Reference Data and index files from 1K Genomes and NCBI
		echo ----------------------------------------------
	
		echo Downloading: ftp://ftp.1000genomes.ebi.ac.uk/vol1/ftp/technical/reference/human_g1k_v37.fasta.gz
		echo
		wget --directory-prefix=./0_DataPrepModule/RefAnnotationData/ ftp://ftp.1000genomes.ebi.ac.uk/vol1/ftp/technical/reference/human_g1k_v37.fasta.gz
		wget --directory-prefix=./0_DataPrepModule/RefAnnotationData/ ftp://ftp.1000genomes.ebi.ac.uk/vol1/ftp/technical/reference/human_g1k_v37.fasta.fai	
		
		# Unzip Fasta file
		${gunzip_Exec} -d ./0_DataPrepModule/RefAnnotationData/human_g1k_v37.fasta.gz
		
		# Rezip Fasta File in bgzip
		${bgzip_Exec} ./0_DataPrepModule/RefAnnotationData/human_g1k_v37.fasta
		rm ./0_DataPrepModule/RefAnnotationData/human_g1k_v37.fasta
		
	
	# Download the annotation files (make sure the the build version is correct) to flip/fix the alleles
		echo
		echo Downloading ftp://ftp.ncbi.nih.gov/snp/organisms/human_9606_b150_GRCh37p13/VCF/All_20170710.vcf.gz
		echo
		wget --directory-prefix=./0_DataPrepModule/RefAnnotationData/ ftp://ftp.ncbi.nih.gov/snp/organisms/human_9606_b150_GRCh37p13/VCF/All_20170710.vcf.gz
		wget --directory-prefix=./0_DataPrepModule/RefAnnotationData/ ftp://ftp.ncbi.nih.gov/snp/organisms/human_9606_b150_GRCh37p13/VCF/All_20170710.vcf.gz.tbi
	
	
	fi
	
	
	
	# STEP 1: Convert the Plink BED/BIM/FAM into a VCF into a BCF so that it may be fixed with BCFtools
	# --------------------------------------------------------------------------------------------------
	
	if [ "${DataPrepStep1,,}" == "t" ]; then
		
		
		# Convert Plink file into a VCF
		
		printf "\n\nConverting $RawData Plink files into VCF format \n"
		echo ----------------------------------------------
		echo
		echo
	
		${Plink_Exec} --bfile ./0_DataPrepModule/PLACE_DATA_2B_FIXED_HERE/$RawData --recode vcf --out ./0_DataPrepModule/TEMP/DataFixStep1_${RawData}
	
	# Convert from a VCF into a BCF and also rename the chromosomes to match the reference fasta (where [chr]23 is X, 24 is Y, etc.)
		
		printf "\n\nConverting VCF into a BCF with chromosome names that match the reference .fasta annotation \n\nNOTE: You may need to manually adjust ./Odyssey/0_DataPrepModule/RefAnnotationData/PlinkChrRename.txt depending on the fasta reference you use in order to match the chromosome names \n"
		echo ----------------------------------------------
		echo
		echo
	
		bcftools annotate -Ob --rename-chrs ./0_DataPrepModule/RefAnnotationData/PlinkChrRename.txt ./0_DataPrepModule/TEMP/DataFixStep1_${RawData}.vcf > ./0_DataPrepModule/TEMP/DataFixStep1_${RawData}.bcf
	
	fi
	
	
	
	
	# STEP 2: Align Input File to the Reference Annotation (Fix with BCFtools)
	# --------------------------------------------------------------------------------------------------
	
	if [ "${DataPrepStep2,,}" == "t" ]; then
	
	# Run bcftools +fixref to see the number of wrong SNPs
		printf "\n\nRun bcftools +fixref to first view the number of correctly annotated/aligned variants to the Reference annotation \n"
		echo ----------------------------------------------
		echo
		echo
	
		bcftools +fixref ./0_DataPrepModule/TEMP/DataFixStep1_${RawData}.bcf -- -f ./0_DataPrepModule/RefAnnotationData/human_g1k_v37.fasta.gz
	
	# Run bcftools to fix/swap the allels based on the downloaded annotation file
		printf "\n\nRun bcftools +fixref to fix allels based on the downloaded annotation file \n"
		echo ----------------------------------------------
		echo
		echo
	
		bcftools +fixref ./0_DataPrepModule/TEMP/DataFixStep1_${RawData}.bcf -Ob -o ./0_DataPrepModule/TEMP/DataFixStep2_${RawData}-RefFixed.bcf -- -d -f ./0_DataPrepModule/RefAnnotationData/human_g1k_v37.fasta.gz -i ./0_DataPrepModule/RefAnnotationData/All_20170710.vcf.gz
	
	# Rerun the bcftool +fixref check to see if the file has been fixed and all unmatched alleles have been dropped
		printf "\n\nRun bcftools +fixref to see if the file has been fixed - all alleles are matched and all unmatched alleles have been dropped \n"
		echo ----------------------------------------------
		echo
		echo
	
		bcftools +fixref ./0_DataPrepModule/TEMP/DataFixStep2_${RawData}-RefFixed.bcf -- -f ./0_DataPrepModule/RefAnnotationData/human_g1k_v37.fasta.gz
		
	fi
	
	
	# STEP 3: Sort the Ref-Aligned BCF output and convert back into Plink format for Odyssey Pipeline
	# --------------------------------------------------------------------------------------------------
	
	if [ "${DataPrepStep3,,}" == "t" ]; then
	
	
	# Sort the BCF output
		printf "\n\nSorting the BCF output since fixing it may have made it unsorted \n"
		echo ----------------------------------------------
	
		(bcftools view -h ./0_DataPrepModule/TEMP/DataFixStep2_${RawData}-RefFixed.bcf; bcftools view -H ./0_DataPrepModule/TEMP/DataFixStep2_${RawData}-RefFixed.bcf | sort -k1,1d -k2,2n;) | bcftools view -Ob -o ./0_DataPrepModule/TEMP/DataFixStep3_${RawData}-RefFixedSorted.bcf
		
		printf "Done \n\n\n"
	
	# Convert BCF back into Plink .bed/.bim/.fam for Shapeit2 Phasing
		printf "\n\nConverting Fixed and Sorted BCF back into Plink .bed/.bim/.fam \n"
		echo ----------------------------------------------
		echo
		echo
	
		${Plink_Exec} --bcf ./0_DataPrepModule/TEMP/DataFixStep3_${RawData}-RefFixedSorted.bcf --make-bed --out ./0_DataPrepModule/TEMP/DataFixStep3_${RawData}-RefFixSorted
		
		
	# Finally Remove any positional duplicates 
		# i.e. same position and alleles, but differently named variants since Shapeit will not tolerate these
	
	
		printf "\n\nFinding Positional and Allelic Duplicates \n"
		echo ----------------------------------------------
		echo
		echo
	
		${Plink_Exec} --bfile ./0_DataPrepModule/TEMP/DataFixStep3_${RawData}-RefFixSorted --list-duplicate-vars ids-only suppress-first --out ./0_DataPrepModule/TEMP/Dups2Remove
		
		# Report Number of duplicates:
		DuplicateNumber="$(wc ./0_DataPrepModule/TEMP/Dups2Remove.dupvar | awk '{print $1}')"
		
		printf "\n\nRemoving Positional and Allelic Duplicates if they exist\nFound ${DuplicateNumber} Duplicate Variant/s\n"
		echo ----------------------------------------------
		echo
		echo
	
		${Plink_Exec} --bfile ./0_DataPrepModule/TEMP/DataFixStep3_${RawData}-RefFixSorted --exclude ./0_DataPrepModule/TEMP/Dups2Remove.dupvar --make-bed --out ./0_DataPrepModule/TEMP/DataFixStep4_${RawData}-RefFixSortedNoDups
		
		
		
	
	# Add back in the sex information
		printf "\n\nRestoring Sample Sex Information \n"
		echo ----------------------------------------------
		echo
		echo
		
		${Plink_Exec} --bfile ./0_DataPrepModule/TEMP/DataFixStep4_${RawData}-RefFixSortedNoDups --update-sex ./0_DataPrepModule/PLACE_DATA_2B_FIXED_HERE/${RawData}.fam 3 --make-bed --out ./1_Target/PLACE_NEW_PROJECT_TARGET_DATA_HERE/DataFixStep5_${RawData}-PhaseReady
		

		echo
		echo
		echo ----------------------------------------------
		printf "Analysis Ready Data -- DataFixStep5_${RawData}-PhaseReady -- Output to --> ./Odyssey/1_Target/PLACE_NEW_PROJECT_TARGET_DATA_HERE/DataFixStep5_${RawData}-PhaseReady \n"
		echo ----------------------------------------------
	
	
	
	fi
	
	# After Step: Cleanup File Intermediates 
	# --------------------------------------------------------------------------------------------------
	
	if [ "${SaveDataPrepIntermeds,,}" == "f" ]; then
	
		echo 
		echo ----------------------------------------------
		echo Tidying Up -- Cleanup Intermediate Files
		echo ----------------------------------------------
	
		if [ -d "./0_DataPrepModule/TEMP" ]; then rm -r ./0_DataPrepModule/TEMP; fi

		#rm ./0_DataPrepModule/DataFixStep*
	
	fi
	
elif [ "${PerformFixref,,}" == "f" ]; then

	#Make Temp Directory in which all Temp files will populate
		mkdir -p ./0_DataPrepModule/TEMP

		
	# Finally Remove any positional duplicates 
		# i.e. same position and alleles, but differently named variants since Shapeit will not tolerate these
	
		printf "\n\nFinding Positional and Allelic Duplicates \n"
		echo ----------------------------------------------
		echo
		echo
	
		${Plink_Exec} --bfile ./0_DataPrepModule/PLACE_DATA_2B_FIXED_HERE/${RawData} --list-duplicate-vars ids-only suppress-first --out ./0_DataPrepModule/TEMP/Dups2Remove
		
		printf "\n\nRemoving Positional and Allelic Duplicates \n"
		echo ----------------------------------------------
		echo
		echo
	
		${Plink_Exec} --bfile ./0_DataPrepModule/PLACE_DATA_2B_FIXED_HERE/${RawData} --exclude ./0_DataPrepModule/TEMP/Dups2Remove.dupvar --make-bed --out ./1_Target/PLACE_NEW_PROJECT_TARGET_DATA_HERE/DataFixStep5_${RawData}-PhaseReady
		
	if [ "${SaveDataPrepIntermeds,,}" == "f" ]; then
	
		echo 
		echo ----------------------------------------------
		echo Tidying Up -- Cleanup Intermediate Files
		echo ----------------------------------------------
	
		if [ -d "./0_DataPrepModule/TEMP" ]; then rm -r ./0_DataPrepModule/TEMP; fi
		#rm ./0_DataPrepModule/DataFixStep*
	
	fi
		
		
		echo
		echo
		echo ----------------------------------------------
		printf "Analysis Ready Data -- DataFixStep5_${RawData}-PhaseReady -- Output to --> ./Odyssey/1_Target/PLACE_NEW_PROJECT_TARGET_DATA_HERE/DataFixStep5_${RawData}-PhaseReady \n"
		echo ----------------------------------------------
	
else

	echo
	echo User Input Not Recognized -- Please specify T or F
	echo Exiting
	echo


fi


# Visualize genomic data for missingness, heterozygosity, and relatedness
if [ "${DataVisualization,,}" == "t" ]; then
	printf "\n\n===================================================\n"
	printf "Data QC-Visualization\n----------------\n\nPreparing to perform QC analysis on the SINGLE Plink .bed/.bim/.fam dataset within:\n./1_Target/PLACE_NEW_PROJECT_TARGET_DATA_HERE/\n\nNOTE: If no data is present, then this analysis will be skipped \n\nAll Data and Plots will be saved to ./1_Target/PLACE_NEW_PROJECT_TARGET_DATA_HERE"
	printf "\n--------------------------------\n\n"

	# Executes the Rscript to analyze and visualize the GWAS analysis

		Arg6="${WorkingDir}";
		Arg7="${X11}";

		${Rscript} ./1_Target/.1_PreGWAS-QC.R $Arg6 $Arg7

	# Copy the Analysis Data to the Quick Results Folder
		echo
		echo
		echo "Copying Analysis Data and Visualizations to Quick Results Folder"
		echo ------------------------------------------------------------------
		cp -R ${WorkingDir}1_Target/PLACE_NEW_PROJECT_TARGET_DATA_HERE/Dataset_QC-Visualization ${WorkingDir}5_QuickResults/${BaseName}/

elif [ "${DataVisualization,,}" == "f" ]; then

	echo
	echo "Skipping Data Visualization and QC"
	echo ----------------------------------------------

else

	echo
	echo User Input Not Recognized -- Please specify T or F
	echo Exiting
	echo

fi

	
# Termination Message
	echo
	echo ============
	echo " Phew Done!"
	echo ============
	echo
	echo
	
