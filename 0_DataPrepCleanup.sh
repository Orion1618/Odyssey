#!/bin/bash

## Overview:
## ==================

# DataCleanup is a multi-function command that will do the following for a SINGLE bed/bim/fam trio:
#	1) Download all the Reference Data (and the index files) to properly align and format the genetic data
#	2) Format/fix the genetic data in the following ways:
#		a) Fixes strand orientation by swapping Ref/Alt alleles based upon the SNP reference ID's
#		b) Corrects coordinates if necessary
#		c) Converts multi-allelic variants into biallelic variants if possible
#		d) Removes the variants that cannot be "fixed" to the reference build
#	3) Sorts the newly created BCF file (since correcting coordinates may create an unsorted BCF file)
#	4) Converts the new sorted and reference aligned BCF file back into a Plink bed/bim/fam trio for use in the Odyssey Pipeline

#=================
## IMPORTANT NOTES:
#=================

# The bed/bim/fam trio must have the proper variant ID's as identified by NCBI (otherwise fixing the data to the reference will likely not work)
# You also need to make sure that you have the proper reference build in relation to your genetic data you are trying to fix (don't try and fix GRCh37 data to a GRCh38 reference)
# Execute the script from the directory it is currently housed in (ie ./Odyssey/DataPrepModule/)

#=================
## DEPENDENCIES:
#=================

# BCFtools v1.8 or later and the BCFtools plugin +fixref
# htslib v1.8 or later
# Either manually add these programs to your .bash_profile or specify the BCFtools executable file in the Programs.conf file

	echo
	echo ==================================
	echo ----------------------------------
	echo Odyssey v1.0 -- Updated 7-10-2018 
	echo ----------------------------------
	echo ==================================
	echo



# Call Variables from Config file
# ----------------------------
	source Programs.conf
	source Config.conf

# Set Working Directory
# -------------------------------------------------
echo
echo Changing to Working Directory
echo ----------------------------------------------
echo ${WorkingDir}

	cd ${WorkingDir}

	
#Get the BaseName of the Data Placed in the PLACE_DATA_2B_FIXED_HERE
RawData="$(ls ./DataPrepModule/PLACE_DATA_2B_FIXED_HERE/*.bim | awk -F/ '{print $NF}' | awk -F'.' '{print $1}')"


# Download all the Reference Data to Reformat the files
# ----------------------------------------------------------------------------

if [ "${DownloadRef}" == "T" ]; then

	echo Downloading Reference Data and index files from 1000 Genomes and NCBI
	echo ----------------------------------------------

	
	wget --directory-prefix=./DataPrepModule/RefAnnotationData/ ftp://ftp.1000genomes.ebi.ac.uk/vol1/ftp/technical/reference/human_g1k_v37.fasta.gz
	gunzip -d ./DataPrepModule/RefAnnotationData/human_g1k_v37.fasta.gz
	wget --directory-prefix=./DataPrepModule/RefAnnotationData/ ftp://ftp.1000genomes.ebi.ac.uk/vol1/ftp/technical/reference/human_g1k_v37.fasta.fai

# Download the annotation files (make sure the the build version is correct) to flip/fix the alleles
	wget --directory-prefix=./DataPrepModule/RefAnnotationData/ ftp://ftp.ncbi.nih.gov/snp/organisms/human_9606_b150_GRCh37p13/VCF/All_20170710.vcf.gz
	wget --directory-prefix=./DataPrepModule/RefAnnotationData/ ftp://ftp.ncbi.nih.gov/snp/organisms/human_9606_b150_GRCh37p13/VCF/All_20170710.vcf.gz.tbi


fi



# STEP 1: Convert the Plink BED/BIM/FAM into a VCF into a BCF so that it may be fixed with BCFtools
# --------------------------------------------------------------------------------------------------

if [ "${DataPrepStep1}" == "T" ]; then
	
	
	# Convert Plink file into a VCF
	
	printf "\n\nConverting $RawData Plink files into VCF format \n"
	echo ----------------------------------------------
	echo
	echo

	$Plink_Exec --bfile ./DataPrepModule/PLACE_DATA_2B_FIXED_HERE/$RawData --recode vcf --out ./DataPrepModule/DataFixStep1_${RawData}

# Convert from a VCF into a BCF and also rename the chromosomes to match the reference fasta (where [chr]23 is X, 24 is Y, etc.)
	
	printf "\n\nConverting VCF into a BCF with chromosome names that match the reference .fasta annotation \nNOTE: You may need to manually adjust ./Odyssey/DataPrepModule/RefAnnotationData/PlinkChrRename.txt depending on the fasta reference you use in order to match the chromosome names \n"
	echo ----------------------------------------------
	echo
	echo

	bcftools annotate -Ob --rename-chrs ./DataPrepModule/RefAnnotationData/PlinkChrRename.txt ./DataPrepModule/DataFixStep1_${RawData}.vcf > ./DataPrepModule/DataFixStep1_${RawData}.bcf

fi




# STEP 2: Align Input File to the Reference Annotation (Fix with BCFtools)
# --------------------------------------------------------------------------------------------------

if [ "${DataPrepStep2}" == "T" ]; then

# Run bcftools +fixref to see the number of wrong SNPs
	printf "\nRun bcftools +fixref to first view the number of correctly annotated/aligned variants to the Reference annotation \n"
	echo ----------------------------------------------
	echo
	echo

	bcftools +fixref ./DataPrepModule/DataFixStep1_${RawData}.bcf -- -f ./DataPrepModule/RefAnnotationData/human_g1k_v37.fasta

# Run bcftools to fix/swap the allels based on the downloaded annotation file
	printf "\nRun bcftools +fixref to fix allels based on the downloaded annotation file \n"
	echo ----------------------------------------------
	echo
	echo

	bcftools +fixref ./DataPrepModule/DataFixStep1_${RawData}.bcf -Ob -o ./DataPrepModule/DataFixStep2_${RawData}-RefFixed.bcf -- -d -f ./DataPrepModule/RefAnnotationData/human_g1k_v37.fasta -i ./DataPrepModule/RefAnnotationData/All_20170710.vcf.gz

# Rerun the bcftool +fixref check to see if the file has been fixed and all unmatched alleles have been dropped
	printf "\nRun bcftools +fixref to see if the file has been fixed - all alleles are matched and all unmatched alleles have been dropped \n"
	echo ----------------------------------------------
	echo
	echo

	bcftools +fixref ./DataPrepModule/DataFixStep2_${RawData}-RefFixed.bcf -- -f ./DataPrepModule/RefAnnotationData/human_g1k_v37.fasta
	
fi


# STEP 3: Sort the Ref-Aligned BCF output and convert back into Plink format for Odyssey Pipeline
# --------------------------------------------------------------------------------------------------

if [ "${DataPrepStep3}" == "T" ]; then


# Sort the BCF output
	printf "\nSorting the BCF output since fixing it may have made it unsorted \n"
	echo ----------------------------------------------
	echo
	echo

	(bcftools view -h ./DataPrepModule/DataFixStep2_${RawData}-RefFixed.bcf; bcftools view -H ./DataPrepModule/DataFixStep2_${RawData}-RefFixed.bcf | sort -k1,1d -k2,2n;) | bcftools view -Ob -o ./DataPrepModule/DataFixStep3_${RawData}-RefFixedSorted.bcf

# Convert BCF back into Plink .bed/.bim/.fam for Shapeit2 Phasing
	printf "\nConverting Fixed and Sorted BCF back into Plink format -- bed/bim/fam \n"
	echo ----------------------------------------------
	echo
	echo

	plink --bcf ./DataPrepModule/DataFixStep3_${RawData}-RefFixedSorted.bcf --make-bed --out ./DataPrepModule/DataFixStep3_${RawData}-RefFixSorted
	

# Finally Remove any positional duplicates 
	# i.e. same position and alleles, but differently named variants since Shapeit will not tolerate these


	printf "\n Finding Positional and Allelic Duplicates \n"
	echo ----------------------------------------------
	echo
	echo

	plink --bfile ./DataPrepModule/DataFixStep3_${RawData}-RefFixSorted --list-duplicate-vars ids-only suppress-first --out ./DataPrepModule/Dups2Remove
	
	printf "\n Removing Positional and Allelic Duplicates \n"
	echo ----------------------------------------------
	echo
	echo

	plink --bfile ./DataPrepModule/DataFixStep3_${RawData}-RefFixSorted --exclude ./DataPrepModule/Dups2Remove.dupvar --make-bed --out ./DataPrepModule/DataFixStep4_${RawData}-RefFixSortedNoDups
	

# Add back in the sex information
	printf "\n Restoring Sample Sex Information \n"
	echo ----------------------------------------------
	echo
	echo
	
	plink --bfile ./DataPrepModule/DataFixStep4_${RawData}-RefFixSortedNoDups --update-sex ./DataPrepModule//PLACE_DATA_2B_FIXED_HERE/${RawData}.fam 3 --make-bed --out ./Target/PLACE_NEW_PROJECT_TARGET_DATA_HERE/DataFixStep5_${RawData}-PhaseReady
	


	echo 
	echo ----------------------------------------------
	printf "Analysis Ready Data - DataFixStep5_${RawData}-PhaseReady - Output to ./Odyssey/Target/PLACE_NEW_PROJECT_TARGET_DATA_HERE/DataFixStep5_${RawData}-PhaseReady \n"
	echo ----------------------------------------------



fi

# After Step: Cleanup File Intermediates 
# --------------------------------------------------------------------------------------------------

if [ "${SaveDataPrepIntermeds}" == "F" ]; then

	echo 
	echo ----------------------------------------------
	echo Tidying Up -- Cleanup Up Intermediate Files
	echo ----------------------------------------------


rm ./DataPrepModule/DataFixStep*

fi

printf "\nDONE!\n\n"
