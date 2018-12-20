#!/bin/bash 


## Overview:
## ==================

## This script will:
	# Help you create a custom reference dataset from 2 Reference datasets using Impute2 via
		# a) Merging 2 reference panels placed in ./Reference1 and ./Reference2
		# b) Concatenating the .hap.gz and .legend.gz files resulting from the merged reference panel
	# Refer to Merge.conf to setup the variables needed to execute this script
	
## ==========================================================================================

# ======================================================================================================
# ======================================================================================================
# ======================================================================================================
# ======================================================================================================
# ======================================================================================================
# ======================================================================================================

# Call Variables from Config files
# ----------------------------
	source Merge.conf

	
# Set Working Directory
# -------------------------------------------------

	cd ${WorkingDir}
	cd MergeRefSets


# Call Variables from other Config files
# ----------------------------
	source ../.TitleSplash.txt
	source ../Programs.conf

	
# Splash Screen
# --------------
printf "$Logo"


printf "
             ==================================
             ----------------------------------
             ---- CUSTOM REF PANEL CREATOR ----
             ----------------------------------
             ==================================\n\n\n"

echo
echo Current Working Directory
echo ----------------------------------------------
echo ${WorkingDir}



# ======================================================================================================
# ======================================================================================================
#                                       Error Check
# ======================================================================================================
# ======================================================================================================


# Perform Error Analysis on Phasing Step -- grep looks for .out files containing 'Killed' or 'Aborted'
# -----------------------------

if [ "${ErrorAnalysis}" == "T" ]; then

	echo
	echo --------------------------------------------------------
	echo Performing Error Analysis on Merge Reference Procedure:
	echo --------------------------------------------------------
	echo 
	echo
	echo Segments that should be reviewed are listed below:
	echo It may take a while to scan all the .out files
	echo ==============================================
	echo
	find ./MergedRefPanels/Scripts2Impute -maxdepth 1 -type f -print | xargs grep -rli 'Killed\|Aborted\|error' | sort -V
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
		echo Outputting more details on failed files...
		echo ===========================================
		echo
		find ./MergedRefPanels/Scripts2Impute -maxdepth 1 -type f -print | xargs grep -ri 'Killed\|Aborted\|error'
		echo
		echo ===========================================
	
	else
		if [ "${UserInput1}" == "no" ]; then
		
		echo Alright, will not output more details on failed files...
		echo =========================================================
		echo

		else
			echo "Input not recognized -- specify either 'yes' or 'no' -- exiting Error View"
			echo =============================================================================
			echo
		fi
	fi
	
# Re-submit the failed scripts
	echo
	echo "Would you like to resubmit the failed scripts?" 
	echo "Script/s will be submitted to an HPS if specified in Merge.conf otherwise will submit via a simple 'sh' command"
	echo "(yes/no)?"
	echo --------------------------------------------------
	read UserInput2
	echo
	echo
	
	if [ "${UserInput2}" == "yes" ]; then
		
		if [ "${HPS_Submit}" == "T" ]; then

		
			echo
			echo Re-Submitting Failed Scripts to HPS...
			echo ===========================================
			echo
			# The following line does a lot: 
			# 1) looks in the script directory that also contains output 
			# 2) find .out files that contain the words 'Killed' and 'Aborted'
			# 3,4) Sorts the .out files and subs .out for .sh to get the script
			# 5) Within .sh should be a manual execution command that starts with '# qsub', grep finds the line and trims the off the '# ' to get the qsub command and saves it to ReSubmitJobs.txt
				find ./MergedRefPanels/Scripts2Impute -maxdepth 1 -type f -print | xargs grep -rli 'Killed\|Aborted\|error' | sort -V | sed 's/.out/.sh/g' | xargs grep -r 'qsub' | sed 's/.*# //' > ReSubmitJobs.txt
				
				# Manually read in scripts that need to be re-run (comment out previous command if you want to use this manual override				
					#cat Scripts2Resubmit.txt | sort -V | sed 's/.out/.sh/g' | xargs grep -r 'qsub' | sed 's/.*# //' > ReSubmitJobs.txt
			
			# Remove the errored .out file (otherwise the new .out will be appended to the old and the error will never be reported as fixed)
				find ./MergedRefPanels/Scripts2Impute -maxdepth 1 -type f -print | xargs grep -rli 'Killed\|Aborted\|error' | sort -V | xargs rm -f
		
			# Read the file that contains the scripts that need to be re-submitted and submit then via Bash to the HPS queue
				cat ReSubmitJobs.txt | bash
			
			# Remove ReSubmitJobs.txt
				rm -f ReSubmitJobs.txt
		
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
			# 2) find .out files that contain the words 'Killed' and 'Aborted'
			# 3,4) Sorts the .out files and subs .out for .sh to get the script
			# 5) Within .sh should be a manual execution command that starts with 'time ', grep finds the line and saves it to ReSubmitJobs.txt
				find ./MergedRefPanels/Scripts2Impute -maxdepth 1 -type f -print | xargs grep -rli 'Killed\|Aborted\|error' | sort -V | sed 's/.out/.sh/g' | xargs grep -r 'time ' > ReSubmitJobs.txt
		
			# Remove the errored .out file (otherwise the new .out will be appended to the old and the error will never be reported as fixed)
				find ./MergedRefPanels/Scripts2Impute -maxdepth 1 -type f -print | xargs grep -rli 'Killed\|Aborted\|error' | sort -V | xargs rm -f
		
			# Read the file that contains the scripts that need to be re-submitted and submit then via sh to the Linux workstation
				cat ReSubmitJobs.txt | sh
			
			# Remove ReSubmitJobs.txt
				rm -f ReSubmitJobs.txt
		
			echo
			echo ===========================================
			echo
		fi
			
			
	
	else
		if [ "${UserInput2}" == "no" ]; then
		
		echo Alright, will not Re-Submit Failed Scripts...
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
#                                       Merge Ref Using IMPUTE
# ======================================================================================================
# ======================================================================================================

if [ "${MergeRefPanels}" == "T" ]; then



	# Creates the Impute directory and also Lustre Stripes it to accomidate for large file folders (prevents the file folder from completely filling up a drive)
	
	printf "\nCreating MergedRefPanels Folder Within Working Directory\n"
	echo --------------------------------------------------------
		mkdir -p ./MergedRefPanels
	
		# Use Lustre Stripping?
			if [ "${LustreStrip}" == "T" ]; then
				lfs setstripe -c 4 ./MergedRefPanels
			fi
		
		mkdir -p ./MergedRefPanels/Scripts2Impute




	# Initialize Imputation Script Creation
	#---------------------------------------

	#Set Chromosome Start and End Parameters
	
	for chr in `eval echo {$ImputeChrStart..$ImputeChrEnd}`; do

		printf "\nProcessing Chromosome ${chr} Scripts \n"
		echo -----------------------------------
		echo

		#Search the genetic map directory and reference directories for the chromosome specific reference map, legend, and hap files and create their respective variables on the fly

		echo "Looking in ./GeneticMaps/ For Genetic Map Files..."
		echo "Found the following Genetic Map for Chromosome ${chr}: "
			GeneticMap="$(ls ./GeneticMaps/ | egrep --ignore-case ".*map.*chr${chr}[^[:digit:]]{1}.*|.*chr${chr}[^[:digit:]]{1}.*map.*")"
				printf "$GeneticMap \n\n"
	
		echo "Looking in ./Reference1/ For Reference Set 1 Files..."
		echo "Found the following references for Chromosome ${chr}: "	
			HapFile1="$(ls ./Reference1/ | egrep --ignore-case ".*chr${chr}[^[:digit:]]{1}.*hap\.gz")"
				printf "   Haplotpe File: $HapFile1 \n"
			LegendFile1="$(ls ./Reference1/ | egrep --ignore-case ".*chr${chr}[^[:digit:]]{1}.*legend\.gz")"
				printf "   Legend File: $LegendFile1 \n \n"
	
		echo "Looking in ./Reference2/ For Reference Set 2 Files..."
		echo "Found the following references for Chromosome ${chr}: "	
			HapFile2="$(ls ./Reference2/ | egrep --ignore-case ".*chr${chr}[^[:digit:]]{1}.*hap\.gz")"
				printf "   Haplotpe File: $HapFile2 \n"
			LegendFile2="$(ls ./Reference2/ | egrep --ignore-case ".*chr${chr}[^[:digit:]]{1}.*legend\.gz")"
				printf "   Legend File: $LegendFile2 \n \n"

				
		# Check to see if all reference files (from both reference sets) + genetic map exist
		if [[ -f ./GeneticMaps/${GeneticMap} && -f ./Reference1/${HapFile1} && -f ./Reference1/${LegendFile1} && -f ./Reference2/${HapFile2} && -f ./Reference2/${LegendFile2} ]] ; then
		
			# Create bash files to merge reference chromosome
			echo
			echo All Necessary Reference Files Present for Chr${chr}
			echo Segmenting Chromosome and Creating Scripts
			echo		
				

			## Figure out how many chunks there are per chromosome by doing some algebra on the genetic map file
			maxPos=$(gawk '$1!="position" {print $1}' ./GeneticMaps/${GeneticMap} | sort -n | tail -n 1);
			nrChunk=$(expr ${maxPos} "/" 2500000);
			nrChunk2=$(expr ${nrChunk} "+" 1);
			start="0";

			## Make each chunk an imputation job and setup the script
			for chunk in $(seq 1 $nrChunk2); do
			endchr=$(expr $start "+" 2500000);
			startchr=$(expr $start "+" 1);

	
echo "#!/bin/bash

cd ${WorkingDir}
cd MergeRefSets

# Impute2 Command to Merge 2 References
	# Manual Command to Run:
	# qsub -l nodes=1:ppn=1,vmem=${Max_Memory}gb,walltime=${Walltime} -M ${Email} -m abe -j oe -o ./MergedRefPanels/Scripts2Impute/Chr${chr}_Chunk${chunk}_${MergedRefName}_I.out -N IChr${chr}_ck${chunk} ./MergedRefPanels/Scripts2Impute/Chr${chr}_Chunk${chunk}_${MergedRefName}_I.sh

time ${Impute_Exec2} \
-merge_ref_panels_output_ref ./MergedRefPanels/${MergedRefName}_Chr${chr}_Chunk${chunk} \
-m ./GeneticMaps/${GeneticMap} \
-h \
./Reference1/${HapFile1} \
./Reference2/${HapFile2} \
-l \
./Reference1/${LegendFile1} \
./Reference2/${LegendFile2} \
-int ${startchr} ${endchr} \
-o_gz ./MergedRefPanels/Chr${chr}_Chunk${chunk}_${MergedRefName}" > ./MergedRefPanels/Scripts2Impute/Chr${chr}_Chunk${chunk}_${MergedRefName}_I.sh


			start=${endchr};


				# Toggle that will turn script submission on/off
				# -----------------------------------------------

				if [ "${ExecuteRefMergeScripts}" == "T" ]; then

					if [ "${HPS_Submit}" == "T" ]; then

						echo
						echo Submitting Ref Panel Merge script to HPC Queue
						echo
							qsub -l nodes=1:ppn=1,vmem=${Max_Memory}gb,walltime=${Walltime} -M ${Email} -m a -j oe -o ./MergedRefPanels/Scripts2Impute/Chr${chr}_Chunk${chunk}_${MergedRefName}_I.out -N IChr${chr}_ck${chunk} ./MergedRefPanels/Scripts2Impute/Chr${chr}_Chunk${chunk}_${MergedRefName}_I.sh
					else
						echo
						echo Submitting  Ref Panel Merge script to Desktop Queue
						echo
							sh ./MergedRefPanels/Scripts2Impute/Chr${chr}_Chunk${chunk}_${MergedRefName}_I.sh > ./MergedRefPanels/Scripts2Impute/Chr${chr}_Chunk${chunk}_${MergedRefName}_I.out

			
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

	# -------------------------------------------------
	## Toggle whether to Merge/Impute the X Chromosome
	# -------------------------------------------------

	if [ "${ImputeX}" == "T" ]; then
		echo Processing X Chromosome Scripts
		echo -----------------------------------
		echo


		# Search the reference directory for the X chromosome specific reference map, legend, and hap files and create their respective variables on the fly
	
		echo "Looking in ./GeneticMaps/ For Genetic Map Files..."
			XGeneticMap="$(ls ./GeneticMaps/  | egrep --ignore-case ".*map.*${XChromIdentifier}.*|.*${XChromIdentifier}.*map.*")"
				printf "   Genetic Map:$XGeneticMap \n\n"
	
		echo "Looking in ./Reference1/ For Reference Set 1 Files..."
		echo "Found the following references for Chromosome X -- identified by ${XChromIdentifier}: "
	
			XHapFile1="$(ls ./Reference1/ | egrep --ignore-case ".*${XChromIdentifier}.*hap\.gz*")"
				printf "   Haplotpe File:$XHapFile1 \n"
			XLegendFile1="$(ls ./Reference1/ | egrep --ignore-case ".*${XChromIdentifier}.*legend\.gz*")"
				printf "   Legend File:$XLegendFile1 \n \n"
	
	
		echo "Looking in ./Reference2/ For Reference Set 2 Files..."
		echo "Found the following references for Chromosome X -- identified by ${XChromIdentifier}: "
	
			XHapFile2="$(ls ./Reference2/ | egrep --ignore-case ".*${XChromIdentifier}.*hap\.gz")"
				printf "   Haplotpe File:$XHapFile2 \n"
			XLegendFile2="$(ls ./Reference2/ | egrep --ignore-case ".*${XChromIdentifier}.*legend\.gz")"
				printf "   Legend File:$XLegendFile2 \n \n"


		# Check to see if all reference files (from both reference sets) + genetic map exist
	
		if [[ -f ./GeneticMaps/${XGeneticMap} && -f ./Reference1/${XHapFile1} && -f ./Reference1/${XLegendFile1} && -f ./Reference2/${XHapFile2} && -f ./Reference2/${XLegendFile2} ]] ; then


			# Create bash files to merge reference chromosome
		
			echo
			echo All Necessary Reference Files Present
			echo Segmenting Chromosome and Creating Scripts
			echo
		
		
		
			## Figure out how many chunks there are on the X Chromosome by doing some algebra on the genetic map file
			#----------------------------------------------------------------------------------------------------------

			maxPos=$(gawk '$1!="position" {print $1}' ./GeneticMaps/${XGeneticMap} | sort -n | tail -n 1);
			nrChunk=$(expr ${maxPos} "/" 2500000);
			nrChunk2=$(expr ${nrChunk} "+" 1);
			start="0";
	
			## Make each chunk an imputation job and setup script
			# ----------------------------------------------------

			for chunk in $(seq 1 $nrChunk2); do
				endchr=$(expr $start "+" 2500000);
				startchr=$(expr $start "+" 1);

		
echo "#!/bin/bash


cd ${WorkingDir}
cd MergeRefSets

# Impute2 Command to Merge 2 References
	# Manual Submission Command:
	# qsub -l nodes=1:ppn=1,vmem=${Max_Memory}gb,walltime=${Walltime} -M ${Email} -m abe -j oe -o ./MergedRefPanels/Scripts2Impute/Chr23_Chunk${chunk}_${MergedRefName}_I.out -N IChr23_ck${chunk} ./MergedRefPanels/Scripts2Impute/Chr23_Chunk${chunk}_${MergedRefName}_I.sh


time ${Impute_Exec2} \
-merge_ref_panels_output_ref ./MergedRefPanels/${MergedRefName}_Chr23_Chunk${chunk} \
-m ./GeneticMaps/${XGeneticMap} \
-h \
./Reference1/${XHapFile1} \
./Reference2/${XHapFile2} \
-l \
./Reference1/${XLegendFile1} \
./Reference2/${XLegendFile2} \
-int ${startchr} ${endchr} \
-o_gz ./MergedRefPanels/Chr23_Chunk${chunk}_${MergedRefName}" > ./MergedRefPanels/Scripts2Impute/Chr23_Chunk${chunk}_${MergedRefName}_I.sh



				start=${endchr};
	
				# Toggle that will turn script submission on/off
				# -----------------------------------------------

				if [ "${ExecuteRefMergeScripts}" == "T" ]; then

	
					if [ "${HPS_Submit}" == "T" ]; then

						echo
						echo Submitting Impute script to HPC Queue
						echo
							qsub -l nodes=1:ppn=1,vmem=${Max_Memory}gb,walltime=${Walltime} -M ${Email} -m a -j oe -o ./MergedRefPanels/Scripts2Impute/Chr23_Chunk${chunk}_${MergedRefName}_I.out -N IChr23_ck${chunk} ./MergedRefPanels/Scripts2Impute/Chr23_Chunk${chunk}_${MergedRefName}_I.sh
					else
						echo
						echo Submitting Impute script to Desktop Queue
						echo
							sh ./MergedRefPanels/Scripts2Impute/Chr23_Chunk${chunk}_${MergedRefName}_I.sh > ./MergedRefPanels/Scripts2Impute/Chr23_Chunk${chunk}_${MergedRefName}_I.out

					fi

				fi
			done
		
		else
		

			echo
			echo All Necessary Reference Files Not Present
			echo Will Not Segment or Create Scripts
			echo

		fi

	fi


else 
	echo
	echo ------ Told to Skip IMPUTE Merging of Reference Panels 1 and 2 ------
	echo

fi



# ======================================================================================================
# ======================================================================================================
#                        Concatenate the Resulting .legend and .hap files
# ======================================================================================================
# ======================================================================================================


if [ "${ConcatRefPanels}" == "T" ]; then

	# Make Lustre Stripped Directory in which to place merged concatenated files
	#----------------------------------------------------------------------------
	
	echo
	echo Creating Finalized Concat Folder within MergeRefSet Directory
	echo ----------------------------------------------
	echo
		mkdir -p ./MergedRefPanels/FinalizedPanel
			lfs setstripe -c 4 ./MergedRefPanels/FinalizedPanel
	
	
	if [ "${ConcatParallel}" == "T" ]; then
		# This is a GNU Parallel command that first searches for *Chr[#]_* to see if the file exists
			# GNU Parallel (https://www.gnu.org/software/parallel/) must be installed on the system to use this option
			# If GNU-Parallel is installed it will find all the .gen chunks for the chromosome and concatenate them together
			# If the chromosomal file doesn't exist then it will report that it doesn't exist
			# All concatenations are performed in parallel based on the number of CPU cores detected (since concatenation is a light resource command)
		
		# Load GNU-Parallel and execute the parallel command to concatenate in parallel
			
			echo Running Parallel Concatenation with GNU-Parallel
			echo Each CPU will concatenated 8 chromosomes at a time
			echo To change this setting modify the -j option in MergeRef.sh
			echo
			echo You may have to configure GNU-Parallel manually to run on your system
			echo 	See Merge.conf for instructions on how to do this
			echo ---------------------------------------------------------
			echo
			
			
			function ConcatF() {
					cd ${WorkingDir}
					cd MergeRefSets
					cd MergedRefPanels
					
				if ls ./*Chr$1_*.hap.gz 1> /dev/null 2>&1; then 
					
					#Say what chr was concatenated
						printf "\n\nConcatenated .hap.gz and .legend.gz files for Chromosome $1\n\n"
					
					# Find all the chromosomal haplotype segments for a particular chromosome, sort them in order, then concatenate them to a single Chr .hap.gz
						#find ./MergedRefPanels/ -maxdepth 1 -type f -name "*Chr$1_*.hap.gz" |sort -V | cat > ./MergedRefPanels/FinalizedPanel/"$MergedRefName"_Chr$1.hap.gz 
						find -maxdepth 1 -type f -name "*Chr$1_*.hap.gz" |sort -V | xargs cat > ./FinalizedPanel/"$MergedRefName"_Chr$1.hap.gz 
					
					# Find all the chromosomal legend segments for a particular chromosome, sort them in order, unzips them, removes the header and concatenates the legend files to a single Chr .legend.gz file, then re-zips the individual legend files
						#find ./MergedRefPanels/ -maxdepth 1 -type f -name "*Chr$1_*.legend.gz" | sort -V | xargs gzip -d ; find -maxdepth 1 -type f -name "*Chr$1_*.legend" | sort -V | xargs tail -n +2 -q > ./MergedRefPanels/FinalizedPanel/"$MergedRefName"_Chr$1.legend ; gzip ./MergedRefPanels/FinalizedPanel/"$MergedRefName"_Chr$1.legend.gz ; find -maxdepth 1 -type f -name "*Chr$1_*.legend" | sort -V | xargs gzip
						find -maxdepth 1 -type f -name "*Chr$1_*.legend.gz" | sort -V | xargs gzip -d ; find -maxdepth 1 -type f -name "*Chr$1_*.legend" | sort -V | head -1 | xargs head -1 -q > ./FinalizedPanel/"$MergedRefName"_Chr$1.legendheader ; find -maxdepth 1 -type f -name "*Chr$1_*.legend" | sort -V | xargs tail -n +2 -q > ./FinalizedPanel/"$MergedRefName"_Chr$1.legendbulk ; cat ./FinalizedPanel/"$MergedRefName"_Chr$1.legendheader ./FinalizedPanel/"$MergedRefName"_Chr$1.legendbulk > ./FinalizedPanel/"$MergedRefName"_Chr$1.legend ;  gzip ./FinalizedPanel/"$MergedRefName"_Chr$1.legend ; find -maxdepth 1 -type f -name "*Chr$1_*.legend" | sort -V | xargs gzip; rm ./FinalizedPanel/"$MergedRefName"_Chr$1.legendbulk ; rm ./FinalizedPanel/"$MergedRefName"_Chr$1.legendheader

			
				else echo "Files for Chromosome $1 does not exist -- Skipping"
						
				fi
			
			
			}
			
			
			# -------- Configure GNU-Parallel (GNU Tag) --------
				
			# On our system gnu-parallel is loaded via a module load command specified in Config.conf under the variable $LOAD_PARALLEL
			# As an alternative you could simply configure GNU-Parallel manually so that calling "parallel" runs GNU-Parallel
			# by adjusting the following lines so that GNU-Parallel runs on your system
			
			# Load/Inititalize GNU-Parallel
				$LOAD_PARALLEL
				
			# -------- Configure GNU-Parallel --------


			# Exports the MergedRefName variable so the child process can see it
				export WorkingDir
				export MergedRefName
				export -f ConcatF
			
			# GNU-Parallel Command: Takes all the chromosomal chunks and concatenates them in parallel
				parallel --eta ConcatF {} ::: {23..23}
	
	else

		echo
		echo Running Serial Concatenation
		echo ---------------------------------------------------------
		echo 

			cd ${WorkingDir}
			cd MergeRefSets
			cd MergedRefPanels

		# Run the Concatenation in Serial
			for chr in {1..26}; do

				echo
				echo 
				echo Concatenating Merged Ref Panel Files for Chromosome ${chr}
				echo ---------------------------------------------------------

			#Searches for chromosome gen file/s; if exists then concatenates them; else skips the chromosome concatenation
				if ls ./*Chr${chr}*.hap.gz 1> /dev/null 2>&1; then 

					# Find all the chromosomal haplotype segments for a particular chromosome, sort them in order, then concatenate them to a single Chr .hap.gz
						find -maxdepth 1 -type f -name "*Chr${chr}_*.hap.gz" |sort -V | xargs cat > ./FinalizedPanel/${MergedRefName}_Chr${chr}.hap.gz 
					
					# Find all the chromosomal legend segments for a particular chromosome, sort them in order, unzips them, removes the header and concatenates the legend files to a single Chr .legend.gz file, then re-zips the individual legend files
						find -maxdepth 1 -type f -name "*Chr${chr}_*.legend.gz" | sort -V | xargs gzip -d ; find -maxdepth 1 -type f -name "*Chr$1_*.legend" | sort -V | head -1 | xargs head -1 -q > ./FinalizedPanel/${MergedRefName}_Chr${chr}.legendheader; find -maxdepth 1 -type f -name "*Chr${chr}_*.legend" | sort -V | xargs tail -n +2 -q > ./FinalizedPanel/${MergedRefName}_Chr${chr}.legendbulk ; cat ./FinalizedPanel/${MergedRefName}_Chr${chr}.legendheader ./FinalizedPanel/${MergedRefName}_Chr${chr}.legendbulk > ./FinalizedPanel/${MergedRefName}_Chr${chr}.legend ; gzip ./FinalizedPanel/${MergedRefName}_Chr${chr}.legend ; find -maxdepth 1 -type f -name "*Chr${chr}_*.legend" | sort -V | xargs gzip ; rm ./FinalizedPanel/${MergedRefName}_Chr${chr}.legendheader ; rm ./FinalizedPanel/${MergedRefName}_Chr${chr}.legendbulk


				else echo "Files for Chromosome ${chr} does not exist -- Skipping"
				
				fi

			done
	fi
	

else 

	echo
	echo
	echo ------ Skipping Concatenation of Chromosomal .legend.gz and .hap.gz Files ------
	echo
	echo

fi


printf "\nPhew! Done! \n\n"



