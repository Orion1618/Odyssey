#!/bin/bash


#This script will take the NCBI created annotation .BED file and use Plink to remove those variants that couldn't be remapped
#It will also use Plink to remap the Plink file with the annotation file created from NCBI
#Most of the file naming is automated (so you won't have to input variables) as long as the NCBI annotation file has the following (default) format: remapped_[filename].BED


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


#Gets the Name of the Plink files that have been renamed under the new chromosomal naming scheme
	#NAME="$(ls ./0_DataPrepModule/Remapping_Made_Easy-SubModule/1*Renamed.bim | awk -F'.' '{print}'|awk '{print substr($1,3);}')"

	NAME1="$(find ./0_DataPrepModule/Remapping_Made_Easy-SubModule/ -name '1*Renamed.bim' -printf '%P\n')"
	NAME="${NAME1%%.*}"





#Gets the Full Name of the NCBI remapped BED2 file (should begin with remapped and end with .BED2)
	#NCBI_NAME="$(ls remapped*.BED2)"

	NCBI_NAME1="$(find ./0_DataPrepModule/Remapping_Made_Easy-SubModule/ -name 'remapped*.BED2' -printf '%P\n')"
	NCBI_NAME="${NCBI_NAME1%%.*}"


#Extracts the RSID numbers of those variants that have successfully been remapped (collected from the 4th column of the NCBI remapped_[FileName].BED)
awk 'BEGIN{FS="\t"}{print $4}' OFS='\t' ./0_DataPrepModule/Remapping_Made_Easy-SubModule/remapped*.BED2 > ./0_DataPrepModule/Remapping_Made_Easy-SubModule/SuccessfullyRemapped.list


#Trims the Renamed Plink file to include only those variants that were successfully remaped by NCBI and listed in SuccessfullyRemapped.list
plink --bfile ./0_DataPrepModule/Remapping_Made_Easy-SubModule/1_${NAME} --extract ./0_DataPrepModule/Remapping_Made_Easy-SubModule/SuccessfullyRemapped.list --make-bed --out ./0_DataPrepModule/Remapping_Made_Easy-SubModule/2_${NAME}_Filtered





#Plink Updates the Genetic Map Coordinates and Chromosomes according to the NCBI remapped[FileName].BED2
plink --bfile ./0_DataPrepModule/Remapping_Made_Easy-SubModule/2_${NAME}_Filtered --update-chr ./0_DataPrepModule/Remapping_Made_Easy-SubModule/${NCBI_NAME} 1 4 --update-map ./0_DataPrepModule/Remapping_Made_Easy-SubModule/${NCBI_NAME} 2 4 --make-bed --out ./0_DataPrepModule/Remapping_Made_Easy-SubModule/3_${NAME}_Remapped

#WARNING: This step will show you if there are any chromsomes that Plink cannot handle (e.g. chr4_ctg9_hap1)
#If you get an error on this step you may have to modify/cleanup the remapped_[FileName].BED2 file.
	#Fixing naming errors becomes very tricky to automate so you are kind of on your own to fix this...however
	#Running 0c_Modify_BED_File.sh may fix your problem as it will remove all BED entries that contain an underline (which is used often when describing contigs)
	#Do not run this script blindly however without understanding the cause of your error


#Convert back to a Plink Chromosome Naming Scheme (e.g. 1,2,23)
plink --bfile ./0_DataPrepModule/Remapping_Made_Easy-SubModule/3_${NAME}_Remapped --make-bed --output-chr 26 --out ./0_DataPrepModule/Remapping_Made_Easy-SubModule/4_${NAME}_RemapComplete
