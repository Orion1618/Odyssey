#!/bin/bash 


## Overview:
## ==================

## This script will:
	# 1) Create the Bash scripts used to execute Imputation jobs (autosomal and the X chromosome) on a system
	# 2) Submit the Bash scripts to the HPC queue at the user's request
	

## Advanced Customization:
	# Setup the torque commands using the right amount of resources
	# These parameters are listed under the tag:
			   ## ????????????????????????????????????
			   ## Alter Script for HPC if necessary
               ## ????????????????????????????????????
			   

## ==========================================================================================


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


# Perform Error Analysis on Phasing Step (grep looks for log files containing 'error' or 'segmentation')
# -----------------------------

if [ "${PhasingErrorAnalysis}" == "T" ]; then

	echo
	echo Performing Error Analysis on Phasing Step:
	echo ----------------------------------------------
	echo 
	echo Phasing Segments that should be reviewed are listed below:
	echo ==============================================
	echo
	grep 'segmentation\|error' ./Phase/${BaseName}/Scripts2Phase
	echo
	echo ==============================================
	echo
fi


# Creates the Impute directory and also Lustre Stripes it to accomidate for large file folders (prevents the file folder from completely filling up a drive)
	
printf "\n>>Creating Imputation Project Folder within Impute Directory \n"

	mkdir -p ./Impute/${BaseName}
	lfs setstripe -c 2 ./Impute/${BaseName}
	mkdir -p ./Impute/${BaseName}/Scripts2Impute
	mkdir -p ./Impute/${BaseName}/RawImputation


# Generate a properly formatted Sample file from Shapeit2 output to be used with Impute4

	#Get a single sample file from the Phase folder
SHAPEIT_SAMPLE_FILE="$(ls ./Phase/${BaseName}/*.sample | head -1)"

echo
echo Modifying Sample File: 
echo $SHAPEIT_SAMPLE_FILE 
echo to be used with Impute4
echo -----------------------------------
echo
awk 'BEGIN{FS=" "}{print $1,$2,$3,$6}' OFS=' ' $SHAPEIT_SAMPLE_FILE > ./Impute/${BaseName}/${BaseName}.sample


# Initialize Imputation Script Creation
#---------------------------------------

#Set Chromosome Start and End Parameters
	
for chr in `eval echo {$ImputeChrStart..$ImputeChrEnd}`; do

printf "\nProcessing Chromosome ${chr} Scripts \n"
echo -----------------------------------
echo

#Search the reference directory for the chromosome specific reference map, legend, and hap files and create their respective variables on the fly

printf "Looking in ./Reference For Reference Files \n\nFound the following references for Chromosome ${chr}: \n"	
	
	GeneticMap="$(ls ./Reference/ | egrep --ignore-case ".*map.*chr${chr}[^[:digit:]]{1}.*|.*chr${chr}[^[:digit:]]{1}.*map.*")"
	printf "$GeneticMap \n"
	HapFile="$(ls ./Reference/ | egrep --ignore-case ".*hap.*chr${chr}[^[:digit:]]{1}.*|.*chr${chr}[^[:digit:]]{1}.*hap.*")"
	printf "$HapFile \n"
	LegendFile="$(ls ./Reference/ | egrep --ignore-case ".*legend.*chr${chr}[^[:digit:]]{1}.*|.*chr${chr}[^[:digit:]]{1}.*legend.*")"
	printf "$LegendFile \n \n"
	

cd ${WorkingDir}

## Figure out how many chunks there are per chromosome by doing some algebra on the genetic map file

	maxPos=$(gawk '$1!="position" {print $1}' ./Reference/${GeneticMap} | sort -n | tail -n 1);
	nrChunk=$(expr ${maxPos} "/" 5000000);
	nrChunk2=$(expr ${nrChunk} "+" 1);
	start="0";

## Make each chunk an imputation job and setup the script
# --------------------------------------------------------

	for chunk in $(seq 1 $nrChunk2); do
		endchr=$(expr $start "+" 5000000);
		startchr=$(expr $start "+" 1);

## ????????????????????????????????????
## Alter Script for HPC if necessary
## ????????????????????????????????????
		
echo "#!/bin/bash
#PBS -l nodes=1:ppn=1,vmem=24gb
#PBS -l walltime=5:00:00
#PBS -M ${Email}
#PBS -m a
#PBS -j oe
#PBS -o ${WorkingDir}Impute/${BaseName}/Scripts2Impute/Chr${chr}_Chunk${chunk}_${BaseName}_I.out
#PBS -N IChr${chr}_ck${chunk}_${BaseName}

cd ${WorkingDir}

time ${Impute_Exec4} \
-g ./Phase/${BaseName}/Ody3_${BaseName}_Chr${chr}_Phased.haps \
-s ./Impute/${BaseName}/${BaseName}.sample \
-m ./Reference/${GeneticMap} \
-h ./Reference/${HapFile} \
-l ./Reference/${LegendFile} \
-int ${startchr} ${endchr} \
-maf_align -Ne 20000 \
-o ./Impute/${BaseName}/RawImputation/Ody4_${BaseName}_Chr${chr}_Chunk${chunk}" > ./Impute/${BaseName}/Scripts2Impute/Chr${chr}_Chunk${chunk}_${BaseName}_I.sh

start=${endchr};


# Toggle that will turn script submission on/off
# -----------------------------------------------

if [ "${ExecuteImputationScripts}" == "T" ]; then

printf " \nSubmitting batch script to Queue \n"	
	
	qsub ./Impute/${BaseName}/Scripts2Impute/Chr${chr}_Chunk${chunk}_${BaseName}_I.sh
	sleep 0.1

fi
	
	done
	
done



# ---------------------------------------------
## Toggle whether to Impute the X Chromosome
# ---------------------------------------------

if [ "${ImputeX}" == "T" ]; then
printf "\nProcessing X Chromosome Scripts \n"
echo -----------------------------------
echo


# Search the reference directory for the X chromosome specific reference map, legend, and hap files and create their respective variables on the fly
	printf "Looking in ./Reference For Reference Files \n\nFound the following references for Chromosome X (identified by ${XChromIdentifier}): \n"	
		
	XGeneticMap="$(ls ./Reference/ | egrep --ignore-case ".*map.*${XChromIdentifier}.*|.*${XChromIdentifier}.*map.*")"
	printf "$XGeneticMap \n"
	XHapFile="$(ls ./Reference/ | egrep --ignore-case ".*hap.*${XChromIdentifier}.*|.*${XChromIdentifier}.*hap.*")"
	printf "$XHapFile \n"
	XLegendFile="$(ls ./Reference/ | egrep --ignore-case ".*legend.*${XChromIdentifier}.*|.*${XChromIdentifier}.*legend.*")"
	printf "$XLegendFile \n \n"

	


## Figure out how many chunks there are on the X Chromosome by doing some algebra on the genetic map file
#----------------------------------------------------------------------------------------------------------

	maxPos=$(gawk '$1!="position" {print $1}' ./Reference/${XGeneticMap} | sort -n | tail -n 1);
	nrChunk=$(expr ${maxPos} "/" 5000000);
	nrChunk2=$(expr ${nrChunk} "+" 1);
	start="0";
	
## Make each chunk an imputation job and setup script
# ----------------------------------------------------

	for chunk in $(seq 1 $nrChunk2); do
		endchr=$(expr $start "+" 5000000);
		startchr=$(expr $start "+" 1);

## ????????????????????????????????????
## Alter Script for HPC if necessary
## ????????????????????????????????????
		
echo "#!/bin/bash
#PBS -l nodes=1:ppn=1,vmem=24gb
#PBS -l walltime=5:00:00
#PBS -M ${Email}
#PBS -m a
#PBS -j oe
#PBS -o ${WorkingDir}Impute/${BaseName}/Scripts2Impute/Chr23_Chunk${chunk}_${BaseName}_I.out
#PBS -N IChr23_ck${chunk}_${BaseName}

cd ${WorkingDir}

#Impute4 X chromosome command (currently non functional with the Nonpar X)

#time ${Impute_Exec4} \
-chrX \
-g ./Phase/${BaseName}/Ody3_${BaseName}_Chr23_Phased.haps \
-s ./Impute/${BaseName}/${BaseName}.sample \
-m ./Reference/${XGeneticMap} \
-h ./Reference/${XHapFile} \
-l ./Reference/${XLegendFile} \
-int ${startchr} ${endchr} \
-maf_align -Ne 20000 \
-o ./Impute/${BaseName}/RawImputation/Ody4_${BaseName}_Chr23_Chunk${chunk}


#Legacy Impute2 file (functional with the Nonpar X)

time ${Impute_Exec2} \
-chrX \
-known_haps_g ./Phase/${BaseName}/Ody3_${BaseName}_Chr23_Phased.haps \
-sample_g ./Impute/${BaseName}/${BaseName}.sample \
-m ./Reference/${XGeneticMap} \
-h ./Reference/${XHapFile} \
-l ./Reference/${XLegendFile} \
-int ${startchr} ${endchr} \
-Ne 20000 \
-o ./Impute/${BaseName}/RawImputation/Ody4_${BaseName}_Chr23_Chunk${chunk}.gen" > ./Impute/${BaseName}/Scripts2Impute/Chr23_Chunk${chunk}_${BaseName}_I.sh



	start=${endchr};
	
# Toggle that will turn script submission on/off
# -----------------------------------------------

if [ "${ExecuteImputationScripts}" == "T" ]; then

printf "\nSubmitting batch script to Queue \n"	
	
	qsub ./Impute/${BaseName}/Scripts2Impute/Chr23_Chunk${chunk}_${BaseName}_I.sh
	sleep 0.1

fi
	done
#exit
fi

printf "\nPhew! Done! \n\n"



