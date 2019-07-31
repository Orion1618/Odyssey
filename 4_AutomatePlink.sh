#!/bin/bash

## Overview:
## ==================

## This script will:
# 1. Setup a GWAS Project with the GWAS Folder
# 2. Call a dosage VCF from the Imputation Project
# 3. Perform a GWAS analysis on the data given a phenotype file
# 4. Visualize the analysis using R


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

		mkdir -p ./4_GWAS/${GWASRunName}_Analysis
		mkdir -p ./4_GWAS/Datasets
		

	
#Get the GWAS subdirectory as a Variable for R script
#-----------------------------------------

    cd ./4_GWAS/${GWASRunName}_Analysis
    GWASSubDir=$(pwd)
	cd ${WorkingDir}
	

#Get the DosageVCF to be analyzed and load into a variable for the R script
#-----------------------------------------
if [ "${GWASOverride,,}" == "t" ]; then

	echo
	echo Performing Manual GWAS File Input
	echo ---------------------------------- 
	echo Getting VCF Dosage file specified in Settings.conf via file path to a Plink Dosage PGEN
	echo

		VCF_Input=$ManualVCFInput
		Sex_Input=$ManualSexInput
		
	
else

	echo
	echo Performing Default GWAS File Input
	echo ----------------------------------- 
	echo Getting VCF Dosage File specified in Settings.conf by the Imputation Project to a Plink Dosage PGEN
	echo

		VCF_Input=$"`find ./3_Impute/${ImputationProject2Analyze}/ConcatImputation -maxdepth 1 -type f -name '1Imputed*'`"
		Sex_Input=$"`find ./1_Target/${ImputationProject2Analyze} -maxdepth 1 -type f -name 'Ody1_*QC2.fam'`"		

fi


# Begin Setting up the Rscript for the GWAS Analysis
#-----------------------------------------------------


# Load all the variables that will be used to create the PGEN and or run the GWAS and visualize results

# Variables to Pass to the Rscript specified in Settings.conf
Arg6="${WorkingDir}";
Arg7="${VCF2PGEN}";
Arg8="${Sex_Input}";
Arg9="${GWAS_Memory}";
Arg10="${GWAS_Walltime}";
Arg11="${GWASSubDir}";
Arg12="${PLINK_OPTIONS}";
Arg13="${GWASPhenoName}";
Arg14="${GWAS_Threads}";
Arg15="${GWASRunName}";
Arg16="${GWASDatasetName}";
Arg17="${Pheno_File}";
# Arg18 can be blank if not converting from a VCF to a PGEN
Arg18="${VCF_Input}";


# Output to a script within the GWAS Sub Directory

echo "#!/bin/bash


# Change to Working Directory
cd ${WorkingDir}



# GWAS Rscript:
${Rscript} ./4_GWAS/.R_GWAS.R $Arg6 $Arg7 $Arg8 $Arg9 $Arg10 $Arg11 '$Arg12' $Arg13 $Arg14 $Arg15 $Arg16 $Arg17 $Arg18" > ${GWASSubDir}/1_${GWASRunName}_Analyze-Visualize.sh

# Change Permission Level in Order to Run the New Script
	chmod 744 ${GWASSubDir}/1_${GWASRunName}_Analyze-Visualize.sh



# Execute GWAS?
#----------------

if [ "${ExecuteGWASScripts,,}" == "t" ]; then


		if [ "${HPS_Submit,,}" == "t" ]; then

			echo
			echo Submitting GWAS script to HPC Queue
			echo
				qsub -l nodes=1:ppn=${GWAS_Threads},vmem=${GWAS_Memory}gb,walltime=${GWAS_Walltime} -M ${Email} -m ae -j oe -o ${GWASSubDir}/${GWASRunName}.out1 -N ${GWASRunName} ${GWASSubDir}/1_${GWASRunName}_Analyze-Visualize.sh

		elif [ "${HPS_Submit,,}" == "f" ]; then
			echo
			echo Submitting GWAS script to Desktop Queue
			echo
				bash ${GWASSubDir}/1_${GWASRunName}_Analyze-Visualize.sh
				
		else
				echo
				echo User Input Not Recognized -- Please specify T or F
				echo Exiting script submission
				echo
	
		fi
fi	
	


	
# Termination Message
	echo
	echo ============
	printf " Phew Done!\n"
	echo ============
	echo
	echo
	
