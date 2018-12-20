#!/bin/bash

# Overview:
# ----------------
# This script will:
# 1) Setup the Imputation Project Folder and will move the target data from the 'PLACE_NEW_PROJECT_TARGET_DATA_HERE' folder into the Project Folder
# 2) Take the Plink (bed/bim/fam format) file from the Imputation Project folder and run Pre-Imputation QC (which includes Plink QC Steps):
	# --geno 0.05
	# --hwe 0.000001
	# --maf 0.025
	# Followed by --mind 0.05 (due to PLINK order of operations this command needs to be run separately)

# 3) Splits up the Project data into their respective chromosomes (e.g. 1-26, since this is the PLINK default).

# You will need to provide the initial name of the file (ie. the BaseName) in the config file but from here on out
# the names will be pre-determined by the Imputation/Phasing pipeline

	echo
	echo ==================================
	echo ----------------------------------
	echo Odyssey v1.0 -- Updated 7-10-2018 
	echo ----------------------------------
	echo ==================================
	echo

# Call Variables from Config
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


# Create Project Folder within Target Directory
# -------------------------------------------------
echo
echo Creating Project Folder within Target Directory
echo
	mkdir -p ./Target/${BaseName}


# Move Data from 'PLACE_NEW_PROJECT_TARGET_DATA_HERE' folder into Project Directory
# ----------------------------------------------------------------------------------

# Look into the PLACE_NEW_PROJECT_TARGET_DATA_HERE Folder and record the name of the Plink dataset
Cohort_InputFileName="$(ls ./Target/PLACE_NEW_PROJECT_TARGET_DATA_HERE/*.bim | awk -F/ '{print $NF}'| awk -F'.' '{print $1}')"

echo
echo
echo "Moving target files from the 'PLACE_NEW_PROJECT_TARGET_DATA_HERE' folder into the Project Folder: ${BaseName}"
echo ---------------------------------------------------------
echo
echo

mv ./Target/PLACE_NEW_PROJECT_TARGET_DATA_HERE/* ./Target/${BaseName}

sleep 2

# Also change the permission levels for the data in the Target Directory so it is readable, writable, and executable by the owner of the folder
chmod -R 700 ./Target/

	
# QC (2 Steps): this will exclude genotypes before people (prioritizing people over variants)
# ----------------------------------------------------------------------------------
	echo
	echo
	echo "Perfoming QC Step 1 -- Removing Poorly Genotyped Genotypes"
	echo -----------------------------------------------------------
	echo
	echo
	
	${Plink_Exec} --allow-no-sex --bfile ./Target/${BaseName}/${Cohort_InputFileName} --geno 0.05 --hwe 0.000001 --maf 0.025 --make-bed --out ./Target/${BaseName}/Ody1_${BaseName}_Pre-ImputeQC1

	echo
	echo
	echo "Perfoming QC Step 2 -- Removing Poorly Genotyped Individuals"
	echo -----------------------------------------------------------
	echo
	echo

	${Plink_Exec} --allow-no-sex --bfile ./Target/${BaseName}/Ody1_${BaseName}_Pre-ImputeQC1 --mind 0.05 --make-bed --out ./Target/${BaseName}/Ody1_${BaseName}_Pre-ImputeQC2
	
	
# Splitting BED/bim/fam by chromosome (goes through all 26 chromosomes by default)
# ----------------------------------------------------------------------------------
for chr in {1..26}; do
	echo
	echo
	echo "Processing ${BaseName}_Pre-ImputeQC2 Plink Dataset... Isolating Chromosome ${chr}"
	echo ----------------------------------------------------------------------------
	echo
	echo
	$Plink_Exec --bfile ./Target/${BaseName}/Ody1_${BaseName}_Pre-ImputeQC2 --chr ${chr} --make-bed --out ./Target/${BaseName}/Ody2_${BaseName}_PhaseReady.chr${chr}
	
done