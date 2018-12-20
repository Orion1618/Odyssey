#!/bin/bash

## Overview:
## ==================

## This script will:
	# 1) Create the Bash scripts used to execute Phasing jobs (autosomal and the X chromosome) on a system
	# 2) Submit the Bash scripts to the HPC queue at the user's request
	
## Advanced Customization:
	# Setup the torque commands using the right amount of resources
	# These parameters are listed under the tag below:
		## ????????????????????????????????????
		## Alter Script for HPC if necessary
        ## ????????????????????????????????????
			   

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
	
echo
echo Creating Imputation Project Folder within Phase Directory
echo
	mkdir -p ./Phase/${BaseName}
	lfs setstripe -c 2 ./Phase/${BaseName}
	mkdir -p ./Phase/${BaseName}/Scripts2Shapeit
	
echo
echo Creating Phasing Scripts
echo
	
for chr in {1..22}; do

#Search the reference directory for the chromosome specific reference map and create the GeneticMap variable on the fly
	GeneticMap="$(find ./Reference/ -iname "*genetic_map*chr${chr}_*")"
	
## -------------------------------------------
## Phasing Script Creation for HPC (Chr1-22)
## -------------------------------------------
	
## ????????????????????????????????????
## Alter Script for HPC if necessary
## ????????????????????????????????????

echo "#!/bin/bash
#PBS -l nodes=1:ppn=${PhasingThreads},vmem=32gb
#PBS -l walltime=10:00:00
#PBS -M ${Email}
#PBS -m ae
#PBS -j oe 
#PBS -o ${WorkingDir}Phase/${BaseName}/Scripts2Shapeit/${BaseName}_Chr${chr}_P.out
#PBS -N PChr${chr}_${BaseName}

cd ${WorkingDir}

time ${Shapeit2_Exec} \
--thread ${PhasingThreads} \
--input-bed ./Target/${BaseName}/Ody2_${BaseName}_PhaseReady.chr${chr} \
--input-map ${GeneticMap} \
--output-max ./Phase/${BaseName}/Ody3_${BaseName}_Chr${chr}_Phased \
--output-log ./Phase/${BaseName}/Ody3_${BaseName}_Chr${chr}_Phased.log" > ./Phase/${BaseName}/Scripts2Shapeit/${BaseName}_Chr${chr}_P.sh


# Toggle that will turn script submission on/off
# -----------------------------------------------

if [ "${ExecutePhasingScripts}" == "T" ]; then

echo
echo Submitting batch script to Queue
echo

qsub ./Phase/${BaseName}/Scripts2Shapeit/${BaseName}_Chr${chr}_P.sh
sleep 0.5

fi

done



## ---------------------------------------
## Extra Step to Phase the X Chromosome
## ---------------------------------------

if [ "${PhaseX}" == "T" ]; then

## -------------------------------------------
## Phasing Script Creation for HPC (Chr23/X)
## -------------------------------------------

# Search the reference directory for the X chromosome specific reference map and create the GeneticMapX variable on the fly
GeneticMapX="$(find ./Reference/ -iname "*genetic_map*nonPAR*")"

## ????????????????????????????????????
## Alter Script for HPC if necessary
## ????????????????????????????????????

echo "#!/bin/bash
#PBS -l nodes=1:ppn=${PhasingThreads},vmem=32gb
#PBS -l walltime=10:00:00
#PBS -M ${Email}
#PBS -m ae
#PBS -j oe
#PBS -o ${WorkingDir}Phase/${BaseName}/Scripts2Shapeit/${BaseName}_Chr23_P.out
#PBS -N PChr23_${BaseName}


cd ${WorkingDir}

time ${Shapeit2_Exec} \
--thread ${PhasingThreads} \
--chrX \
--input-bed ./Target/${BaseName}/Ody2_${BaseName}_PhaseReady.chr23 \
--input-map ${GeneticMapX} \
--output-max ./Phase/${BaseName}/Ody3_${BaseName}_Chr23_Phased \
--output-log ./Phase/${BaseName}/Ody3_${BaseName}_Chr23_Phased.log" > ./Phase/${BaseName}/Scripts2Shapeit/${BaseName}_Chr23_P.sh


# Toggle that will turn script submission on/off
# -----------------------------------------------

	if [ "${ExecutePhasingScripts}" == "T" ]; then

	echo
	echo Submitting batch script to Queue
	echo

	qsub ./Phase/${BaseName}/Scripts2Shapeit/${BaseName}_Chr23_P.sh
	fi
fi	

echo
echo Done!
echo

