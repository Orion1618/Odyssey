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
	echo Converting VCF Dosage file specified in Config.conf via file path to a Plink Dosage PGEN
	echo

		VCF_Input=$ManualVCFInput
		Sex_Input=$ManualSexInput
		
	cd ${WorkingDir}

	
else

	echo
	echo Performing Default GWAS File Input
	echo ----------------------------------- 
	echo Converting VCF Dosage File specified in Config.conf by the Imputation Project to a Plink Dosage PGEN
	echo

		VCF_Input=$"`find ./3_Impute/${ImputationProject2Analyze}/ConcatImputation -maxdepth 1 -type f -name '1DONE*'`"
		Sex_Input=$"`find ./1_Target/${ImputationProject2Analyze} -maxdepth 1 -type f -name 'Ody1_*QC2.fam'`"		

fi


#-------------------------
# Create Plink Script:
#-------------------------


if [ "${VCF2PGEN,,}" == "t" ]; then

	echo
	echo Creating Script to Convert Dosage VCF to PGEN 
	echo And also running the GWAS
	echo ----------------------------------------------
	echo


#Script to convert VCF to PGEN Conversion AND Specified GWAS
#------------------------------------------------------------

echo "#!/bin/bash

# Change to Working Directory
cd ${WorkingDir}


# Convert VCF to PGEN

time ${Plink2_Exec} \
--vcf ${VCF_Input} \
--id-delim _ \
--update-sex ${Sex_Input} col-num=5 \
--memory ${Max_Memory}000 require \
--make-pgen \
--out ./4_GWAS/Datasets/${BaseName}

# GWAS Script:

time ${Plink2_Exec} \
${PLINK_OPTIONS} \
--pfile ./4_GWAS/Datasets/${BaseName} \
--pheno ./4_GWAS/Phenotype/${Pheno_File} \
--pheno-name ${GWASPhenoName} \
--threads ${GWAS_Threads} \
--memory ${Max_Memory}000 require \
--out ${GWASSubDir}/${GWASRunName}

## Visualize Data Script that runs R Script
#============================================

	cd ${GWASSubDir}

# Executes the Rscript to analyze and visualize the GWAS analysis
		
	Arg6=${GWASSubDir};
		
	{Rscript} ${GWASSubDir}/1_${GWASRunName}_Analyze-Visualize.R $Arg6"> ${GWASSubDir}/1_${GWASRunName}_Analyze-Visualize.sh

	#Change Permission Level in Order to Run the New Script
		chmod 744 ${GWASSubDir}/1_${GWASRunName}_Analyze-Visualize.sh

elif [ "${VCF2PGEN,,}" == "f" ]; then

	#Script to create Specified GWAS ONLY
	#-------------------------------------

	echo
	echo Creating Script to Run the GWAS
	echo --------------------------------
	echo

echo "#!/bin/bash


# Change to Working Directory
cd ${WorkingDir}

# GWAS Script:

time ${Plink2_Exec} \
${PLINK_OPTIONS} \
--pfile ./4_GWAS/Datasets/${BaseName} \
--pheno ./4_GWAS/Phenotype/${Pheno_File} \
--pheno-name ${GWASPhenoName} \
--threads ${GWAS_Threads} \
--memory ${Max_Memory}000 require \
--out ${GWASSubDir}/${GWASRunName}

## Visualize Data Script that runs R Script
#============================================

	cd ${GWASSubDir}

# Executes the Rscript to analyze and visualize the GWAS analysis

	Arg6=${GWASSubDir};

	{Rscript} ${GWASSubDir}/1_${GWASRunName}_Analyze-Visualize.R $Arg6

	# Move GWAS Results into 5_QuickResults Folder
	cp -R ${GWASSubDir}/${GWASRunName} ${WorkingDir}/5_QuickResults/${BaseName}/GWAS_Results/${GWASRunName}/"> ${GWASSubDir}/1_${GWASRunName}_Analyze-Visualize.sh

	#Change Permission Level in Order to Run the New Script
		chmod 744 ${GWASSubDir}/1_${GWASRunName}_Analyze-Visualize.sh

else

	echo
	echo User Input Not Recognized -- Please specify T or F
	echo Exiting script creation
	echo

fi


# Execute GWAS?
#----------------

if [ "${ExecuteGWASScripts,,}" == "t" ]; then


		if [ "${HPS_Submit,,}" == "t" ]; then

			echo
			echo Submitting Plink Analysis and R Visualization scripts to HPC Queue
			echo
				qsub -l nodes=1:ppn=${GWAS_Threads},vmem=${Max_Memory}gb,walltime=${Max_Walltime} -M ${Email} -m ae -j oe -o ${GWASSubDir}/Plink.out -N ${GWASRunName} ${GWASSubDir}/1_${GWASRunName}_Analyze-Visualize.sh

		elif [ "${HPS_Submit,,}" == "f" ]; then
			echo
			echo Submitting Plink Analysis and R Visualization scripts to Desktop Queue
			echo
				sh ${GWASSubDir}/1_${GWASRunName}_Analyze-Visualize.sh
				
		else
				echo
				echo User Input Not Recognized -- Please specify T or F
				echo Exiting script submission
				echo
	
		fi
fi	
	


	
# Termination Message
	echo
	echo
	echo "Done!"
	echo ---------
	echo
	echo
	
