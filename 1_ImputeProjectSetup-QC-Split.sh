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


# Create Project Folder within Target Directory
# -------------------------------------------------
	echo
	echo Creating Project Folder within Target Directory
	echo ----------------------------------------------
	echo 
		mkdir -p ./1_Target/${BaseName}


# Move Data from 'PLACE_NEW_PROJECT_TARGET_DATA_HERE' folder into Project Directory
# ----------------------------------------------------------------------------------

# Look into the PLACE_NEW_PROJECT_TARGET_DATA_HERE Folder and record the name of the Plink dataset
	Cohort_InputFileName="$(ls ./1_Target/PLACE_NEW_PROJECT_TARGET_DATA_HERE/*.bim | awk -F/ '{print $NF}'| awk -F'.' '{print $1}')"

	echo
	echo
	echo "Moving target files from the 'PLACE_NEW_PROJECT_TARGET_DATA_HERE' folder into the Project Folder: ${BaseName}"
	echo ---------------------------------------------------------
	echo
	echo

# Move it
	mv ./1_Target/PLACE_NEW_PROJECT_TARGET_DATA_HERE/* ./1_Target/${BaseName}

	sleep 2

# Also change the permission levels for the data in the Target Directory so it is readable, writable, and executable by the owner of the folder
	chmod -R 700 ./1_Target/

	
# QC (2 Steps): this will exclude genotypes before people (prioritizing people over variants)
# ----------------------------------------------------------------------------------
	echo
	echo
	echo "Perfoming QC Step 1 -- Removing Poorly Genotyped Genotypes"
	echo -----------------------------------------------------------
	echo
	echo
	
	${Plink_Exec} --allow-no-sex --bfile ./1_Target/${BaseName}/${Cohort_InputFileName} --geno ${GenoQC} --hwe ${HweQC} --maf ${MafQC} --make-bed --out ./1_Target/${BaseName}/Ody1_${BaseName}_Pre-ImputeQC1

	echo
	echo
	echo "Perfoming QC Step 2 -- Removing Poorly Genotyped Individuals"
	echo -----------------------------------------------------------
	echo
	echo

	${Plink_Exec} --allow-no-sex --bfile ./1_Target/${BaseName}/Ody1_${BaseName}_Pre-ImputeQC1 --mind ${MindQC} --make-bed --out ./1_Target/${BaseName}/Ody1_${BaseName}_Pre-ImputeQC2
	
	
# Splitting BED/bim/fam by chromosome (goes through all 26 chromosomes by default)
# ----------------------------------------------------------------------------------
for chr in {1..26}; do
	echo
	echo
	echo "Processing ${BaseName}_Pre-ImputeQC2 Plink Dataset -- Isolating Chromosome ${chr}"
	echo ----------------------------------------------------------------------------
	echo
	echo
	$Plink_Exec --bfile ./1_Target/${BaseName}/Ody1_${BaseName}_Pre-ImputeQC2 --chr ${chr} --make-bed --out ./1_Target/${BaseName}/Ody2_${BaseName}_PhaseReady.chr${chr}
	
done

	
# Termination Message
	echo
	echo ============
	echo " Phew Done!"
	echo ============
	echo
	echo
	
	
