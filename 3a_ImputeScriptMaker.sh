#!/bin/bash 


## Overview:
## ==================

## This script will:
	# 1) Create the Bash scripts used to execute Imputation jobs (autosomal and the X chromosome) on a system
	# 2) Submit the Bash scripts to the HPC queue at the user's request
	
## ==========================================================================================


# Call Variables from Config file
# ----------------------------
	source Programs.conf
	source Config.conf
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

	cd ${WorkingDir}


# ======================================================================================================
# ======================================================================================================
#                                       Error Check
# ======================================================================================================
# ======================================================================================================


# Perform Error Analysis on Phasing Step -- grep looks for .out files containing 'Killed', 'Aborted', 'segmentation', or 'error'
# -----------------------------

if [ "${PhasingErrorAnalysis}" == "T" ]; then

	echo
	echo --------------------------------------------------------
	echo Performing Error Analysis on Phasing Jobs:
	echo --------------------------------------------------------
	echo 
	echo
	echo Phasing jobs that should be reviewed are listed:
	echo It may take a while to scan all the .out files
	echo ==============================================
	echo
	find ./Phase/${BaseName}/Scripts2Shapeit -maxdepth 1 -type f -print | xargs grep -rli 'Killed\|Aborted\|segmentation\|error' | sort -V
	echo
	echo ==============================================
	echo

# Examine the failed files?
	echo
	echo "The files listed above appeared to have failed." 
	echo "Would you like more details on why they failed (this will print the line that contains the error for each failed file)?"
	echo "(yes/no)?"
	echo --------------------------------------------------
	read UserInput1
	echo
	echo
	
	if [ "${UserInput1}" == "yes" ]; then
		
		echo
		echo "Outputting more details on failed file/s..."
		echo ===========================================
		echo
		find ./Phase/${BaseName}/Scripts2Shapeit -maxdepth 1 -type f -print | xargs grep -ri 'Killed\|Aborted\|segmentation\|error' | sort -V
		echo
		echo ===========================================
	
	else
		if [ "${UserInput1}" == "no" ]; then
		
		echo "Alright, will not output more details on failed file/s"
		echo =========================================================
		echo

		else
			echo "Input not recognized -- specify either 'yes' or 'no' -- exiting Error Analysis"
			echo ================================================================================
			echo
		fi
	fi
	
# Re-submit the failed scripts
	echo
	echo "Would you like to resubmit the failed scripts?" 
	echo "Script/s will be submitted to an HPS if specified in Conf.conf otherwise will submit via a simple 'sh' command"
	echo "(yes/no)?"
	echo --------------------------------------------------
	read UserInput2
	echo
	echo
	
	if [ "${UserInput2}" == "yes" ]; then
		
		if [ "${HPS_Submit,,}" == "t" ]; then

		
			echo
			echo Re-Submitting Failed Scripts to HPS...
			echo ===========================================
			echo
			# The following line does a lot: 
			# 1) looks in the script directory that also contains output logs 
			# 2) find .out files that contain the words 'Killed', 'Aborted', 'segmentation', or 'error'
			# 3,4) Sorts the .out files and subs .out for .sh to get the script
			# 5) Within .sh should be a manual execution command that starts with '# qsub', grep finds the line and trims the off the '# ' to get the qsub command and saves it to ReSubmitPhaseJobs.txt
				find ./Phase/${BaseName}/Scripts2Shapeit -maxdepth 1 -type f -print | xargs grep -rli 'Killed\|Aborted\|segmentation\|error' | sort -V | sed 's/.out/.sh/g' | xargs grep -r 'qsub' | sed 's/.*# //' > ReSubmitPhaseJobs.txt
				
				# Manually read in scripts that need to be re-run (comment out previous command if you want to use this manual override				
					#cat Scripts2Resubmit.txt | sort -V | sed 's/.out/.sh/g' | xargs grep -r 'qsub' | sed 's/.*# //' > ReSubmitPhaseJobs.txt
			
			# Remove the errored .out file (otherwise the new .out will be appended to the old and the error will never be reported as fixed)
				find ./Phase/${BaseName}/Scripts2Shapeit -maxdepth 1 -type f -print | xargs grep -rli 'Killed\|Aborted\|segmentation\|error' | sort -V | xargs rm -f
		
			# Read the file that contains the scripts that need to be re-submitted and submit then via Bash to the HPS queue
				cat ReSubmitPhaseJobs.txt | bash
			
			# Remove ReSubmitJobs.txt
				rm -f ReSubmitPhaseJobs.txt
		
			echo
			echo ===========================================
			echo
		
		else
			echo
			echo Re-Submitting Failed Scripts to Desktop...
			echo ===========================================
			echo
			# The following line does a lot: 
			# 1) looks in the script directory that also contains output 
			# 2) find .out files that contain the words 'Killed', 'Aborted', 'segmentation', or 'error'
			# 3,4) Sorts the .out files and subs .out for .sh to get the script
			# 5) Within .sh should be a manual execution command that starts with 'time ', grep finds the line and saves it to ReSubmitPhaseJobs.txt
				find ./Phase/${BaseName}/Scripts2Shapeit -maxdepth 1 -type f -print | xargs grep -rli 'Killed\|Aborted\|segmentation\|error' | sort -V | sed 's/.out/.sh/g' | xargs grep -r 'time ' > ReSubmitPhaseJobs.txt
		
			# Remove the errored .out file (otherwise the new .out will be appended to the old and the error will never be reported as fixed)
				find ./Phase/${BaseName}/Scripts2Shapeit -maxdepth 1 -type f -print | xargs grep -rli 'Killed\|Aborted\|segmentation\|error' | sort -V | xargs rm -f
		
			# Read the file that contains the scripts that need to be re-submitted and submit then via sh to the Linux workstation
				cat ReSubmitPhaseJobs.txt | sh
			
			# Remove ReSubmitJobs.txt
				rm -f ReSubmitPhaseJobs.txt
		
			echo
			echo ===========================================
			echo
		fi
			
			
	
	else
		if [ "${UserInput2}" == "no" ]; then
		
		echo "Alright, will not Re-Submit Failed Script/s"
		echo ==============================================
		echo
		echo

		else
			echo "Input Not Recognized -- Specify Either 'yes' or 'no' -- Exiting Re-Submission"
			echo ==============================================================================
			echo
			echo
		fi
	fi
fi


# ======================================================================================================
# ======================================================================================================
#                                    Imputation Script Creation
# ======================================================================================================
# ======================================================================================================


# Creates the Impute directory and also Lustre Stripes it to accomidate for large file folders (prevents the file folder from completely filling up a drive)
	
printf "\nCreating Imputation Project Folder within Impute Directory \n"

	mkdir -p ./Impute/${BaseName}
	
	# Use Lustre Stripping?
	if [ "${LustreStrip,,}" == "t" ]; then

		lfs setstripe -c 5 ./Impute/${BaseName}

	fi

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


# ---------------------------------------------
## Toggle whether to Impute the Autosomes (Chr1-22)
# ---------------------------------------------


if [ "${ImputeAutosomes,,}" == "t" ]; then 

	#Set Chromosome Start and End Parameters
	for chr in `eval echo {$ImputeChrStart..$ImputeChrEnd}`; do

		printf "\nProcessing Chromosome ${chr} Scripts \n"
		echo -----------------------------------
		echo

		#Search the reference directory for the chromosome specific reference map, legend, and hap files and create their respective variables on the fly
		echo "Looking in ./Reference For Reference Files "
		echo "Found the following references for Chromosome ${chr}: "

		GeneticMap="$(ls ./Reference/ | egrep --ignore-case ".*map.*chr${chr}[^[:digit:]]{1}.*|.*chr${chr}[^[:digit:]]{1}.*map.*")"
			printf "   Genetic Map File: $GeneticMap \n"
		HapFile="$(ls ./Reference/ | egrep --ignore-case ".*chr${chr}[^[:digit:]]{1}.*hap\.gz")"
			printf "   Haplotpe File: $HapFile \n"
		LegendFile="$(ls ./Reference/ | egrep --ignore-case ".*chr${chr}[^[:digit:]]{1}.*legend\.gz")"
			printf "   Legend File: $LegendFile \n \n"	

		# Check to see if all reference files + genetic map exist
		if [[ -f ./Reference/${GeneticMap} && -f ./Reference/${HapFile} && -f ./Reference/${LegendFile} ]] ; then
		
			# Create bash files to segment chromosomes by position and create imputation scripts
			echo
			echo All Necessary Reference Files Present for Chr${chr}
			echo Segmenting Chromosome and Creating Scripts
			echo	

			# Change to Working Directory
			cd ${WorkingDir}

			# Figure out how many chunks there are per chromosome by doing some algebra on the genetic map file
			maxPos=$(gawk '$1!="position" {print $1}' ./Reference/${GeneticMap} | sort -n | tail -n 1);
			nrChunk=$(expr ${maxPos} "/" 5000000);
			nrChunk2=$(expr ${nrChunk} "+" 1);
			start="0";

			## Make each chunk an imputation job and setup the script
			# --------------------------------------------------------

			for chunk in $(seq 1 $nrChunk2); do
				endchr=$(expr $start "+" 5000000);
				startchr=$(expr $start "+" 1);

	
echo "#!/bin/bash

cd ${WorkingDir}

# Impute Command to Impute Chromosome
	# Manual Command to Run:
	# qsub -l nodes=1:ppn=1,vmem=${Max_Memory}gb,walltime=${ImputeWalltime} -M ${Email} -m a -j oe -o ${WorkingDir}Impute/${BaseName}/Scripts2Impute/Chr${chr}_Chunk${chunk}_${BaseName}_I.out -N IChr${chr}_ck${chunk}_${BaseName} ./Impute/${BaseName}/Scripts2Impute/Chr${chr}_Chunk${chunk}_${BaseName}_I.sh


# Impute 4
	# Currently enabled to impute the autosomal chromosomes
time ${Impute_Exec4} \
-g ./Phase/${BaseName}/Ody3_${BaseName}_Chr${chr}_Phased.haps \
-s ./Impute/${BaseName}/${BaseName}.sample \
-m ./Reference/${GeneticMap} \
-h ./Reference/${HapFile} \
-l ./Reference/${LegendFile} \
-int ${startchr} ${endchr} \
-maf_align -Ne 20000 \
-o ./Impute/${BaseName}/RawImputation/Ody4_${BaseName}_Chr${chr}_Chunk${chunk}

# Legacy Impute2
	# Currently disabled to impute the autosomal chromosomes
	# Remove the hashtag from the Impute2 command below and comment out (include a hastag before) the Impute4 command above to run Impute2 for the autosomal chromosomes

#time ${Impute_Exec2} \
-known_haps_g ./Phase/${BaseName}/Ody3_${BaseName}_Chr${chr}_Phased.haps \
-sample_g ./Impute/${BaseName}/${BaseName}.sample \
-m ./Reference/${GeneticMap} \
-h ./Reference/${HapFile} \
-l ./Reference/${LegendFile} \
-int ${startchr} ${endchr} \
-Ne 20000 \
-o ./Impute/${BaseName}/RawImputation/Ody4_${BaseName}_Chr${chr}_Chunk${chunk}" > ./Impute/${BaseName}/Scripts2Impute/Chr${chr}_Chunk${chunk}_${BaseName}_I.sh


				start=${endchr};


				# Toggle that will turn script submission on/off
				# -----------------------------------------------

				if [ "${ExecuteImputationScripts,,}" == "t" ]; then
	
					if [ "${HPS_Submit,,}" == "t" ]; then

						echo
						echo Submitting Impute script to HPC Queue
						echo
						qsub -l nodes=1:ppn=1,vmem=${Max_Memory}gb,walltime=${ImputeWalltime} -M ${Email} -m a -j oe -o ${WorkingDir}Impute/${BaseName}/Scripts2Impute/Chr${chr}_Chunk${chunk}_${BaseName}_I.out -N IChr${chr}_ck${chunk}_${BaseName} ./Impute/${BaseName}/Scripts2Impute/Chr${chr}_Chunk${chunk}_${BaseName}_I.sh
					else
		
						echo
						echo Submitting Impute script to Desktop Queue
						echo
						sh ./Impute/${BaseName}/Scripts2Impute/Chr${chr}_Chunk${chunk}_${BaseName}_I.sh > ${WorkingDir}Impute/${BaseName}/Scripts2Impute/Chr${chr}_Chunk${chunk}_${BaseName}_I.out

			
					fi	
				fi
			done
	
		else
			echo
			echo All Necessary Reference Files Not Present
			echo Will Not Segment or Create Scripts
			echo
		fi
	done
fi



# ---------------------------------------------
## Toggle whether to Impute the X Chromosome
# ---------------------------------------------

if [ "${ImputeX,,}" == "t" ]; then
	echo Processing X Chromosome Scripts
	echo -----------------------------------
	echo


	# Search the reference directory for the X chromosome specific reference map, legend, and hap files and create their respective variables on the fly
	
		echo "Looking in ./Reference For Reference Files "
		echo "Found the following references for Chromosome X: "

		XGeneticMap="$(ls ./Reference/ | egrep --ignore-case ".*map.*${XChromIdentifier}.*|.*${XChromIdentifier}.*map.*")"
			printf "   Genetic Map: $XGeneticMap \n"
		XHapFile="$(ls ./Reference/ | egrep --ignore-case ".*${XChromIdentifier}.*hap\.gz")"
			printf "   Haplotpe File: $XHapFile \n"
		XLegendFile="$(ls ./Reference/ | egrep --ignore-case ".*${XChromIdentifier}.*legend\.gz")"
			printf "   Legend File: $XLegendFile \n \n"

	# Check to see if all reference files + genetic map exist
	if [[ -f ./Reference/${XGeneticMap} && -f ./Reference/${XHapFile} && -f ./Reference/${XLegendFile} ]] ; then
		

		# Create bash files to segment chromosomes by position and create imputation scripts
		echo
		echo All Necessary Reference Files Present for ChrX
		echo Segmenting Chromosome and Creating Scripts
		echo
	
	
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

		
echo "#!/bin/bash

cd ${WorkingDir}

# Impute Command to Impute X Chromosome
	# Manual Command to Run:
	# qsub -l nodes=1:ppn=1,vmem=${Max_Memory}gb,walltime=${ImputeWalltime} -M ${Email} -m a -j oe -o ${WorkingDir}Impute/${BaseName}/Scripts2Impute/Chr23_Chunk${chunk}_${BaseName}_I.out -N IChr23_ck${chunk}_${BaseName} ./Impute/${BaseName}/Scripts2Impute/Chr23_Chunk${chunk}_${BaseName}_I.sh

#Impute4 X chromosome command (currently non functional with the Nonpar X)

time ${Impute_Exec4} \
-chrX \
-g ./Phase/${BaseName}/Ody3_${BaseName}_Chr23_Phased.haps \
-s ./Impute/${BaseName}/${BaseName}.sample \
-m ./Reference/${XGeneticMap} \
-h ./Reference/${XHapFile} \
-l ./Reference/${XLegendFile} \
-int ${startchr} ${endchr} \
-maf_align \
-o ./Impute/${BaseName}/RawImputation/Ody4_${BaseName}_Chr23_Chunk${chunk}


#Legacy Impute2 file (functional with the Nonpar X)

#time ${Impute_Exec2} \
-chrX \
-known_haps_g ./Phase/${BaseName}/Ody3_${BaseName}_Chr23_Phased.haps \
-sample_g ./Impute/${BaseName}/${BaseName}.sample \
-m ./Reference/${XGeneticMap} \
-h ./Reference/${XHapFile} \
-l ./Reference/${XLegendFile} \
-int ${startchr} ${endchr} \
-o ./Impute/${BaseName}/RawImputation/Ody4_${BaseName}_Chr23_Chunk${chunk}.gen" > ./Impute/${BaseName}/Scripts2Impute/Chr23_Chunk${chunk}_${BaseName}_I.sh

			start=${endchr};
	
			# Toggle that will turn script submission on/off
			# -----------------------------------------------
			if [ "${ExecuteImputationScripts,,}" == "t" ]; then

	
				if [ "${HPS_Submit,,}" == "t" ]; then

					echo
					echo Submitting Impute script to HPC Queue
					echo
					qsub -l nodes=1:ppn=1,vmem=${Max_Memory}gb,walltime=${ImputeWalltime} -M ${Email} -m a -j oe -o ${WorkingDir}Impute/${BaseName}/Scripts2Impute/Chr23_Chunk${chunk}_${BaseName}_I.out -N IChr23_ck${chunk}_${BaseName} ./Impute/${BaseName}/Scripts2Impute/Chr23_Chunk${chunk}_${BaseName}_I.sh
				elif [ "${HPS_Submit,,}" == "f" ]; then
				
					echo
					echo Submitting Impute script to Desktop Queue
					echo
					sh ./Impute/${BaseName}/Scripts2Impute/Chr23_Chunk${chunk}_${BaseName}_I.sh > ${WorkingDir}Impute/${BaseName}/Scripts2Impute/Chr23_Chunk${chunk}_${BaseName}_I.out

				else
				
					echo
					echo User Input Not Recognized -- Please specify T or F
					echo Exiting script submission
					echo
				fi
			elif [ "${ExecuteImputationScripts,,}" == "f" ]; then
			
				echo
				echo Not Submitting Scripts
				echo
			
			else
				echo
				echo User Input Not Recognized -- Please specify T or F
				echo Exiting script submission
				echo
			fi
		done
	else
		echo
		echo All Necessary Reference Files Not Present
		echo Will Not Segment or Create Scripts
		echo
	fi	
fi

printf "\nPhew! Done! \n\n"



