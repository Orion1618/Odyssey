#!/bin/bash


# Source from .config files (Program options via Settings.conf & Program execs via Programs.conf)
# ----------------------------
	
	source ./Settings.conf
	
	# Set Working Directory
# -------------------------------------------------
echo
echo Changing to Working Directory
echo ----------------------------------------------
echo ${WorkingDir}

	cd ${WorkingDir}
	# Load Odysseys Dependencies -- pick from several methods
	if [ "${OdysseySetup,,}" == "one" ]; then
		echo
		printf "\n\n Loading Odyssey's Singularity Container Image \n\n"
		source ./Configuration/Setup/Programs-Singularity.conf
	
	elif [ "${OdysseySetup,,}" == "two" ]; then
		echo
		printf "\n\n Loading Odyssey's Manually Configured Dependencies \n\n"
		source ./Configuration/Setup/Programs-Manual.conf
	else

		echo
		echo User Input Not Recognized -- Please specify One or Two
		echo Exiting Dependency Loading
		echo
		exit
	fi


source .TitleSplash.txt


# Splash Screen
# --------------
printf "$Logo"

# Convert to Plink Chromosome Naming Scheme of 1,2,23 to chr1,chr2,chr23 
	#NAME="$(ls ${WorkingDir}0_DataPrepModule/Remapping_Made_Easy-SubModule/*.bim | awk -F'.' '{print $1}')"

	NAME1="$(find ./0_DataPrepModule/Remapping_Made_Easy-SubModule/ -name '*.bim' -printf '%P\n')"
	NAME="${NAME1%%.*}"






$Plink_Exec --bfile ${WorkingDir}0_DataPrepModule/Remapping_Made_Easy-SubModule/${NAME} --make-bed --output-chr chrM --out ${WorkingDir}0_DataPrepModule/Remapping_Made_Easy-SubModule/1_${NAME}_ChrRenamed


#Turn a the Plink Bim file into a BED (not a Plink .bed) file (Named BED2 so as not to confuse Plink)
awk 'BEGIN{FS="\t"}{print $1,$4,($4+1),$2}' OFS='\t' ./0_DataPrepModule/Remapping_Made_Easy-SubModule/1_${NAME}_ChrRenamed.bim > ./0_DataPrepModule/Remapping_Made_Easy-SubModule/1_${NAME}_ChrRenamed.BED2


