#!/bin/bash 


# Overview:
# =-==================

# This script will:
# 1. Concatenate GEN file
# 2. Analyze the variants on the concatenated GEN file (meanwhile...)
# 3. Concatenate the chromosomal gen files to a single dataset gen file
# 4. Convertt the chromosomal GEN file to a Pgen file for Plink Analysis



# Splash Screen
# --------------
	source .TitleSplash.txt
	printf "$Logo"

# Source from .config files (Program options via Settings.conf & Program execs via Programs.conf)
# ----------------------------
	source Settings.conf
	
	# Load Odysseys Dependencies -- pick from several methods
	if [ "${OdysseySetup,,}" == "one" ]; then
		printf "\n\nLoading Odyssey's Singularity Container Image \n\n"
		source ./Configuration/Setup/Programs-Singularity.conf
	
	elif [ "${OdysseySetup,,}" == "two" ]; then
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
echo
echo Changing to Working Directory
echo ----------------------------------------------
echo ${WorkingDir}

	cd ${WorkingDir}
	


# =-=-=-=-==========================================================
#  ================================================================
#   ====================== Error Check ===========================
#  ================================================================
# ==================================================================

if [ "${UseImpute,,}" == "t" ]; then
	# Perform Error Analysis on Phasing Step -- grep looks for .out files containing 'Killed', 'Aborted', 'segmentation', or 'error'
	# -----------------------------
	
	if [ "${ImputationErrorAnalysis,,}" == "t" ]; then
	
		echo
		echo --------------------------------------------------------
		echo Performing Error Analysis on Imputation Jobs:
		echo --------------------------------------------------------
		echo 
		echo Note: Some errors are caused by no SNPs being in the imputed area -- this is not really an issue -- skip the segment
		echo Note: Other errors are listed as segmentation faults -- memory access issues -- try re-running or use Impute2 and re-run
		echo 
		echo
		echo Imputation jobs that should be reviewed are listed:
		echo It may take a while to scan all the .out files
		echo ==============================================
		echo
			find ./3_Impute/${BaseName}/Scripts2Impute -maxdepth 1 -type f -print | xargs grep -rli 'Killed\|Aborted\|segmentation\|error' | sort -V
		echo
		echo ==============================================
		echo
	
	# Examine the failed files?
		echo
		echo "The files listed above appeared to have failed." 
		echo "Would you like more details on why they failed (this will print the line that contains the error for each failed file)?"
		echo "(y/n)?"
		echo --------------------------------------------------
		read UserInput1
		echo
		echo
		
		if [ "${UserInput1,,}" == "y" ]; then
			
			echo
			echo "Outputting more details on failed file/s..."
			echo ===========================================
			echo
			find ./3_Impute/${BaseName}/Scripts2Impute -maxdepth 1 -type f -print | xargs grep -ri 'Killed\|Aborted\|segmentation\|error' | sort -V
			echo
			echo ===========================================
		
		elif [ "${UserInput1,,}" == "n" ]; then
			
			echo "Alright, will not output more details on failed file/s"
			echo =========================================================
			echo
	
		else
				echo "Input not recognized -- specify either 'y' or 'n' -- exiting Error Analysis"
				echo ================================================================================
				echo
		fi
		
	# Re-submit the failed scripts
		echo
		echo "Would you like to resubmit the failed scripts?" 
		echo "Script/s will be submitted to an HPS if specified in Conf.conf otherwise will submit via a simple 'sh' command"
		echo "(y/n)?"
		echo --------------------------------------------------
		read UserInput2
		echo
		echo
		
		if [ "${UserInput2,,}" == "y" ]; then
		
			# Specify text document of failed scripts to re-run; manual script re-submission
			echo
			echo "Normally ALL the failed scripts will be re-submitted" 
			echo "However, you can provide a text doc that contains a list of the scripts you would like re-submitted"
			echo "Would you prefer to manually provide this list?"
			echo "Note: The file should contain the full path to the automatically created scripts you want re-submitted"
			echo "Note: Each script should be listed on a new line of the text document"
			echo "(y/n)?"
			echo --------------------------------------------------
			read UserInput3
			echo
			echo
				if [ "${UserInput3,,}" == "y" ]; then
					echo "You Said Yes to Manual Script Submission So Please Provide the Full Path to the Re-Submission Text Doc"
					read UserInput4
					echo "Using Text Doc: ${UserInput4} for manual script submission"
				
				elif [ "${UserInput3}" == "n" ]; then
						echo
				else 
					echo "User Input not recognized -- please specify 'y' or 'n' -- ignoring input"
					
				fi
			
			if [ "${HPS_Submit,,}" == "t" ]; then
	
			
				echo
				echo Re-Submitting Failed Scripts to HPS...
				echo ===========================================
				echo
				
					if [ "${UserInput3,,}" == "y" ]; then
						echo "Manually reading in scripts to re-submit from $UserInput4"
						
						# Manually read in scripts that need to be re-run			
							cat $UserInput4 | sort -V | xargs grep -r 'qsub' | sed 's/.*# //' > ReSubmitImputeJobs.txt
							
						# Remove the errored .out file (otherwise the new .out will be appended to the old and the error will never be reported as fixed)
							find ./3_Impute/${BaseName}/Scripts2Impute -maxdepth 1 -type f -print | xargs grep -rli 'Killed\|Aborted\|segmentation\|error' | sort -V | xargs rm -f
			
						# Read the file that contains the scripts that need to be re-submitted and submit then via Bash to the HPS queue
							cat ReSubmitImputeJobs.txt | bash
				
						# Remove ReSubmitJobs.txt
							rm -f ReSubmitImputeJobs.txt
			
						echo
						echo ===========================================
						echo
					
					elif [ "${UserInput3,,}" == "n" ]; then
						
						echo "Looking up all failed scripts from .out files for re-submission"
						# The following line does a lot: 
						# 1) looks in the script directory that also contains output logs 
						# 2) find .out files that contain the words 'Killed', 'Aborted', 'segmentation', or 'error'
						# 3,4) Sorts the .out files and subs .out for .sh to get the script
						# 5) Within .sh should be a manual execution command that starts with '# qsub', grep finds the line and trims the off the '# ' to get the qsub command and saves it to ReSubmitPhaseJobs.txt
							find ./3_Impute/${BaseName}/Scripts2Impute -maxdepth 1 -type f -print | xargs grep -rli 'Killed\|Aborted\|segmentation\|error' | sort -V | sed 's/.out/.sh/g' | xargs grep -r 'qsub' | sed 's/.*# //' > ReSubmitImputeJobs.txt
							
						# Remove the errored .out file (otherwise the new .out will be appended to the old and the error will never be reported as fixed)
							find ./3_Impute/${BaseName}/Scripts2Impute -maxdepth 1 -type f -print | xargs grep -rli 'Killed\|Aborted\|segmentation\|error' | sort -V | xargs rm -f
			
						# Read the file that contains the scripts that need to be re-submitted and submit then via Bash to the HPS queue
							cat ReSubmitImputeJobs.txt | bash
				
						# Remove ReSubmitJobs.txt
							rm -f ReSubmitImputeJobs.txt
			
						echo
						echo ===========================================
						echo
					else
						echo
						echo "User Input not recognized -- please specify 'y' or 'n'"
						echo "Exiting Script Re-Submission"
						echo
					fi
			
			else
			
			
				echo
				echo Re-Submitting Failed Scripts to Desktop...
				echo ===========================================
				echo
				
				if [ "${UserInput3,,}" == "y" ]; then
					echo "Manually reading in scripts to re-submit from $UserInput4"
						
					# Manually read in scripts that need to be re-run			
						cat $UserInput4 | sort -V | xargs grep -r 'qsub' | sed 's/.*# //' > ReSubmitImputeJobs.txt
							
					# Remove the errored .out file (otherwise the new .out will be appended to the old and the error will never be reported as fixed)
						find ./3_Impute/${BaseName}/Scripts2Impute -maxdepth 1 -type f -print | xargs grep -rli 'Killed\|Aborted\|segmentation\|error' | sort -V | xargs rm -f
						
					# Read the file that contains the scripts that need to be re-submitted and submit then via Bash to the HPS queue
						cat ReSubmitImputeJobs.txt | sh
				
					# Remove ReSubmitJobs.txt
						rm -f ReSubmitImputeJobs.txt
			
						echo
						echo ===========================================
						echo
						
				elif [ "${UserInput3,,}" == "n" ]; then
					# The following line does a lot: 
					# 1) looks in the script directory that also contains output 
					# 2) find .out files that contain the words 'Killed', 'Aborted', 'segmentation', or 'error'
					# 3,4) Sorts the .out files and subs .out for .sh to get the script
					# 5) Within .sh should be a manual execution command that starts with 'time ', grep finds the line and saves it to ReSubmitPhaseJobs.txt
						find ./3_Impute/${BaseName}/Scripts2Impute -maxdepth 1 -type f -print | xargs grep -rli 'Killed\|Aborted\|segmentation\|error' | sort -V | sed 's/.out/.sh/g' | xargs grep -r 'time ' > ReSubmitImputeJobs.txt
			
					# Remove the errored .out file (otherwise the new .out will be appended to the old and the error will never be reported as fixed)
						find ./3_Impute/${BaseName}/Scripts2Impute -maxdepth 1 -type f -print | xargs grep -rli 'Killed\|Aborted\|segmentation\|error' | sort -V | xargs rm -f
			
					# Read the file that contains the scripts that need to be re-submitted and submit then via sh to the Linux workstation
						cat ReSubmitImputeJobs.txt | sh
				
					# Remove ReSubmitJobs.txt
						rm -f ReSubmitImputeJobs.txt
			
					echo
					echo ===========================================
					echo
				
				
				else
					echo
					echo "User Input not recognized -- please specify 'y' or 'n'"
					echo "Exiting Script Re-Submission"
					echo	
				fi
			fi
				
				
		
		elif [ "${UserInput2,,}" == "n" ]; then
			
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
	elif [ "${ImputationErrorAnalysis,,}" == "f" ]; then
	
		echo 
	
	else 
		echo 
		echo User Input Not Recognized -- please specify T or F in Conf.conf
		echo
	fi
fi

# =-=-=-=-=-==============================================================================================
#  ======================================================================================================
#   =============================== IMPUTE 4 Post Imputation File Cleaning =============================
#  ======================================================================================================
# ========================================================================================================

if  [ "${UseImpute,,}" == "t" ]; then
	echo
	echo
	echo ----------------------------------------------------------------
	printf "Performing Post Imputation File Clean Up on IMPUTE4 Files\n"
	echo ================================================================

	# =-=-=-=-================================================================================================
	#  ======================================================================================================
	#   ========================= Perform Concatenation of chromosomal .gen file chunks ====================
	#  ======================================================================================================
	# ========================================================================================================

	if [ "${ConcatImpute,,}" == "t" ]; then
	
		# Make Directory in which to place merged concatenated files
		#----------------------------------------------------------------------------
		echo
		echo Creating Concat Cohort Folder within Impute Directory
		echo ----------------------------------------------
		echo
			mkdir -p ./3_Impute/${BaseName}/ConcatImputation
		
		# Use Lustre Stripping?
		if [ "${LustreStrip,,}" == "t" ]; then
			lfs setstripe -c 5 ./3_Impute/${BaseName}/ConcatImputation
		fi
		
		
		# Concatenation Command Using GNU-Parallel
		if [ "${ConcatParallel,,}" == "t" ]; then
			# This is a GNU Parallel command that first searches for *Chr[#]_* to see if the file exists
				# GNU Parallel (https://www.gnu.org/software/parallel/) must be installed on the system to use this option
				# If GNU-Parallel is installed it will find all the .gen chunks for the chromosome and concatenate them together
				# If the chromosomal file doesn't exist then it will report that it doesn't exist
				# All concatenations are performed in parallel based on the number of CPU cores detected (since concatenation is a light resource command)
			
			# Load GNU-Parallel and execute the parallel command to concatenate in parallel
				echo ---------------------------------------------------------
				echo Running Parallel Concatenation with GNU-Parallel
				echo Each CPU will concatenated 1 chromosome at a time
				echo
				echo You may have to configure GNU-Parallel manually to run on your system
				echo 	See Config.conf for instructions on how to do this
				echo ---------------------------------------------------------
				echo
				
			function Concat() {
				if ls ./3_Impute/"$BaseName"/RawImputation/*Chr$1_*.gen 1> /dev/null 2>&1; then 
					
					#Say what chr was concatenated
						printf "\n\nConcatenated Chromosome $1\n\n"
					
					# Find all the chromosomal segments for a particular chromosome, sort them in order, replaces the first column with a chromsome number, then concatenate them to a single Chr .gen
						find ./3_Impute/"$BaseName"/RawImputation/ -type f -name "*Chr$1_*.gen" |sort -V | xargs -r awk '{ $1='$1'; print }' | cat > ./3_Impute/"$BaseName"/ConcatImputation/"$BaseName"_Chr$1.gen
					
					# Zips the concatenated .gen file
					${gzip_Exec} ./3_Impute/"$BaseName"/ConcatImputation/"$BaseName"_Chr$1.gen
					
			
				else echo "Files for Chromosome $1 does not exist -- Skipping"
						
				fi
			}
				
				
			# -------- Configure GNU-Parallel (GNU Tag) --------
				
			# On our system gnu-parallel is loaded via a module load command specified in the ./Odyssey/Configuration/Setup/*.conf file under the variable $LOAD_PARALLEL
			# As an alternative you could simply configure GNU-Parallel manually so that calling "parallel" runs GNU-Parallel
			# by adjusting the following lines so that GNU-Parallel runs on your system
			
			# Load/Inititalize GNU-Parallel
				$LOAD_PARALLEL
				
			# -------- Configure GNU-Parallel --------
	
	
			# Exports the BaseName variable so the child process can see it
				export BaseName
				export -f Concat
				export gzip_Exec

	
			# GNU-Parallel Command: Takes all the chromosomal chunks and concatenates them in parallel
				if [ "${GNU_ETA,,}" == "t" ]; then
					seq $ConcatStart $ConcatEnd | parallel --eta Concat {}
				
				elif [ "${GNU_ETA,,}" == "f" ]; then
					seq $ConcatStart $ConcatEnd | parallel Concat {}
				
				else
					echo 'Input not recognized for GNU_ETA -- specify either T or F'
				fi
	

		else
	
			echo
			echo ================================
			echo   Running Serial Concatenation
			echo ================================
			echo
			
			# Run the Concatenation in Serial
			for chr in `eval echo {${ConcatStart}..${ConcatEnd}}`; do
	        
				echo 
				echo ----- Concatenating Chromosome ${chr} -----
				echo 
	        
				#Searches for chromosome gen file/s; if exists then concatenates them; else skips the chromosome concatenation
				if ls ./3_Impute/${BaseName}/RawImputation/*Chr${chr}_*gen 1> /dev/null 2>&1; then 
					find ./3_Impute/${BaseName}/RawImputation/ -type f -name "*Chr${chr}_*.gen" |sort -V | xargs -r awk '{ $1='${chr}'; print }' | cat > ./3_Impute/${BaseName}/ConcatImputation/${BaseName}_Chr${chr}.gen
				
				# Zips the concatenated .gen file
					${gzip_Exec} ./3_Impute/${BaseName}/ConcatImputation/${BaseName}_Chr${chr}.gen
				
					
				else 
					echo "Files for Chromosome ${chr} does not exist -- Skipping"
				fi
			done
		fi
	else 
	

		printf "\n\n\n------ Skipping Concatenation of Impute4 Chromosomal .GEN Files ------\n"
			
	fi
	
	
	# =-=-=-=-=================================================================================================
	#  ======================================================================================================
	#   ===== Cleanup the Concatenated Impute4 Output Gen files (analyze INFO, Filter, Convert to VCF) =====
	#  ======================================================================================================
	# =========================================================================================================
	
	
	if [ "${Cleanup,,}" == "t" ]; then
		
		
		printf "\n\n\nPreparing to Cleanup Concatenated Impute4 Chromosomal Gen Files\n"
		echo ---------------------------------------------------------------
		
		
		# Create Temporary Sample File that Creates Unique ID_1 By Combining ID_1 and ID-2 since SNPTEST only looks at ID_1
		
		printf "Creating Temporary Sample File that Creates a Unique ID_1 from ID_1 and ID_2 \nSNPTEST only looks at ID_1, thus this must be unique\n"
		echo
		echo
		
		awk -F " " 'NR==1; NR==2; NR > 2{print $1"_"$2,$2,$3,$4, $5}' OFS=' ' ./3_Impute/${BaseName}/${BaseName}.sample > ./3_Impute/${BaseName}/.TempSample4SNPTEST.sample
	
		
		# =-=-=-=====================================================================================
		#   Cleanup Gen File in in parallel using GNU-Parallel
		#  =========================================================================================
		# ===========================================================================================
		
		if [ "${CleanupParallel,,}" == "t" ]; then
			
			# Load GNU-Parallel and execute the parallel command to analyze variants in parallel
			
			echo
			echo =========================================================
		 printf " Running Parallel Chrom.gen.gz Cleanup with GNU-Parallel\n"
		 printf "     Each CPU will analyze 1 chromosome at a time\n\n"
		 printf "    You may have to configure GNU-Parallel manually\n"
		 printf "  See Settings.conf for instructions on how to do this\n"
			echo =========================================================
			echo
	
			# GNU-Parallel Function that Performs multiple steps to cleanup the Impute4 concatenated .gen.gz files
				function CleanupFunc() {
				
					
				#   Create a SNP Report for the concatenated chromosomal GEN file (Includes INFO score)
				# =-=-====================================================================================
				# =========================================================================================
					
					printf "\n\nUsing SNPTEST to Analyze Chr $1 INFO Scores\n"
					echo ----------------------------------------------
				
					# Conditional statement to see if there is a Concatenated Chromosomal GEN file from which to make a SNP Report
					if ls ./3_Impute/"$BaseName"/ConcatImputation/*Chr$1.gen.gz 1> /dev/null 2>&1; then 
		
						# Conditional Statement to look to see if a snpstat file for the particular chromosome is already present
						if ls ./3_Impute/"$BaseName"/ConcatImputation/*Chr$1.snpstat 1> /dev/null 2>&1; then
						
							echo "A snpstat file for Chromosome $1 already exists -- What Should I do?"
							
							# If a snpstat file for the particular chromosome is already present and overwrite set to false, then skip the Info analysis
							if  [ "${OverwriteIfExist,,}" == "f" ]; then
							
								echo Do not overwrite ./3_Impute/"$BaseName"/ConcatImputation/"$BaseName"_Chr$1.snpstat -- Skipping INFO Score Analysis for Chr $1
								echo
								
															
							# If a snpstat file for the particular chromosome is already present and overwrite set to true, then overwrite it
							elif  [ "${OverwriteIfExist,,}" == "t" ]; then
								echo Will overwrite ./3_Impute/"$BaseName"/ConcatImputation/"$BaseName"_Chr$1.snpstat
								echo
								
								
								#Perform SNPTEST SNP Analysis
									printf "\n\nPerforming SNP Analysis on Chromosome $1 \n-----------------------------------------\n";
						
									printf "Options in Effect: \n$SNPTEST_Exec \n-summary_stats_only -assume_chromosome $1 \n-data ./3_Impute/${BaseName}/ConcatImputation/${BaseName}_Chr$1.gen.gz ./3_Impute/${BaseName}/${BaseName}.sample \n-chunk 10000 \n-o ./3_Impute/${BaseName}/ConcatImputation/${BaseName}_Chr$1.snpstat >> ./3_Impute/${BaseName}/ConcatImputation/${BaseName}_Chr$1.snpstatOut\n\n"
						
									$SNPTEST_Exec -summary_stats_only -assume_chromosome $1 -data ./3_Impute/${BaseName}/ConcatImputation/${BaseName}_Chr$1.gen.gz ./3_Impute/${BaseName}/.TempSample4SNPTEST.sample -chunk 10000 -o ./3_Impute/${BaseName}/ConcatImputation/${BaseName}_Chr$1.snpstat >> ./3_Impute/${BaseName}/ConcatImputation/${BaseName}_Chr$1.snpstatOut
							else
								echo ERROR -- Specify Either T or F for OverwriteIfExist Variable
								echo
							fi
						else
							# If a snpstat file for the particular chromosome is not present then do the Info analysis and make one
							
							#Perform SNPTEST SNP Analysis
								printf "\n\nPerforming SNP Analysis on Chromosome $1 \n-----------------------------------------\n";
						
								printf "Options in Effect: \n$SNPTEST_Exec \n-summary_stats_only -assume_chromosome $1 \n-data ./3_Impute/${BaseName}/ConcatImputation/${BaseName}_Chr$1.gen.gz ./3_Impute/${BaseName}/${BaseName}.sample \n-chunk 10000 \n-o ./3_Impute/${BaseName}/ConcatImputation/${BaseName}_Chr$1.snpstat >> ./3_Impute/${BaseName}/ConcatImputation/${BaseName}_Chr$1.snpstatOut\n\n"
						
								$SNPTEST_Exec -summary_stats_only -assume_chromosome $1 -data ./3_Impute/${BaseName}/ConcatImputation/${BaseName}_Chr$1.gen.gz ./3_Impute/${BaseName}/.TempSample4SNPTEST.sample -chunk 10000 -o ./3_Impute/${BaseName}/ConcatImputation/${BaseName}_Chr$1.snpstat >> ./3_Impute/${BaseName}/ConcatImputation/${BaseName}_Chr$1.snpstatOut
						fi
					else
						# Otherwise if there are no files to create a SNP Report then say so	
						printf " \n\nNo Chromosomal .gen.gz File Present for Chromosome $1 with which to create a SNP Report -- Skipping \n"
					fi
					
				#                 Generate List to Filter Variants based on INFO scores
				# =-=-=====================================================================================
				# ==========================================================================================
					printf " \n\n\nMake List to Filter Variants Based on INFO Scores for Chr $1\n"
					echo ------------------------------------------------------------
					
					# Conditional statement to see if there is a .snpstat file from which to filter variants
					if ls ./3_Impute/"$BaseName"/ConcatImputation/*Chr$1.snpstat 1> /dev/null 2>&1; then  

						# Conditional Statement to look to see if an INFOFiltered_Chr$1.list is already present
						if ls ./3_Impute/"$BaseName"/ConcatImputation/INFOFiltered_Chr$1.list 1> /dev/null 2>&1; then
						
							printf "An INFOFiltered file for Chromosome $1 already exists -- What Should I do?\n"
							
							# If a list file for the particular chromosome is already present and overwrite is set to false, then skip the list creation
							if  [ "${OverwriteIfExist,,}" == "f" ]; then
							
								echo Do not overwrite ./3_Impute/"$BaseName"/ConcatImputation/INFOFiltered_Chr$1.list
								echo Skipping INFO List Creation for Chr $1, but still report INFO SNP Stats
								echo
								
							# But Still Report SNP Filtering Stats to .snpstatOut
								
								TOTAL_SNPS="$(wc -l < ./3_Impute/${BaseName}/ConcatImputation/${BaseName}_Chr$1.snpstat)"
								FILTERED_SNPS="$(wc -l < ./3_Impute/${BaseName}/ConcatImputation/INFOFiltered_Chr$1.list)"
					
								#Output to Screen
									printf "\n\n\nINFO Score SNP Statistics for Chr$1:\n-------------------------- \nTotal Number of Imputed Variants in Chromosome $1: $TOTAL_SNPS \nRemaining Total Variants in Chromosome $1 after INFO Filtering: $FILTERED_SNPS\n\n"
								
								# Output to Snpstat.out
									#printf "\n\nINFO Score SNP Statistics for Chr$1:\n-------------------------- \nTotal Number of Imputed Variants in Chromosome $1: $TOTAL_SNPS \nRemaining Total Variants in Chromosome $1 after INFO Filtering: $FILTERED_SNPS\n\n" >> ./3_Impute/${BaseName}/ConcatImputation/${BaseName}_Chr$1.snpstatOut
							
							# If a list file for the particular chromosome is already present and overwrite set to true, then overwrite it
							elif  [ "${OverwriteIfExist,,}" == "t" ]; then
								echo Will overwrite ./3_Impute/"$BaseName"/ConcatImputation/INFOFiltered_Chr$1.list
								
								
								# Output TEMP INFO filtered list that ignores '#' headers, scans .snpstat for INFO scores (9th column of .snpstat), and filters/outputs SNP names (used later to filter)
								
									# Legacy Code
									#awk '/^[^#]/ { print $2,$9}' ./Impute/$BaseName/ConcatImputation/${BaseName}_Chr$1.snpstat | awk '{ if($2 >= $'$INFOThresh') {print $1}}' > ./Impute/$BaseName/ConcatImputation/INFOFiltered_Chr$1.list
									#awk '{ if($9 >= $'$INFOThresh') { print $2}}' ./Impute/$BaseName/ConcatImputation/${BaseName}_Chr$1.snpstat > ./Impute/$BaseName/ConcatImputation/INFOFiltered_Chr$1.list
									#awk 'FNR > 11 { if($9 >= '$INFOThresh') { print $2,$9 }}' ./Impute/$BaseName/ConcatImputation/${BaseName}_Chr$1.snpstat > ./Impute/$BaseName/ConcatImputation/INFOFiltered_Chr$1.list
		
									printf "\n\n\nScanning .snpstat SNP-Report for SNPs that meet the specified INFO Score cutoff of greater than: $INFOThresh\n"
									echo Outputting INFOFiltered list  which contains SNP names and their corresponding INFO scores 
									echo ----------------------------------------------
						
									awk '{ if (!/#|info/ && $9 >= '$INFOThresh') { print $2 }}' ./3_Impute/$BaseName/ConcatImputation/${BaseName}_Chr$1.snpstat > ./3_Impute/$BaseName/ConcatImputation/INFOFiltered_Chr$1.list.temp
									
								# Output INFO filtered list that ignores '#' headers, scans .snpstat for INFO scores (9th column of .snpstat), and filters/outputs SNP name and corresponding INFO score
									awk '{ if (!/#|info/ && $9 >= '$INFOThresh') { print $2, $9}}' ./3_Impute/$BaseName/ConcatImputation/${BaseName}_Chr$1.snpstat > ./3_Impute/$BaseName/ConcatImputation/INFOFiltered_Chr$1.list
									
								# Lookup SNP Filtering Stats
					
									TOTAL_SNPS="$(wc -l < ./3_Impute/${BaseName}/ConcatImputation/${BaseName}_Chr$1.snpstat)"
									FILTERED_SNPS="$(wc -l < ./3_Impute/${BaseName}/ConcatImputation/INFOFiltered_Chr$1.list)"
					

									#Output to Screen
										printf "\n\n\nINFO Score SNP Statistics for Chr$1:\n-------------------------- \nTotal Number of Imputed Variants in Chromosome $1: $TOTAL_SNPS \nRemaining Total Variants in Chromosome $1 after INFO Filtering: $FILTERED_SNPS\n\n"
									
									# Output to Snpstat.out
										#printf "\n\nINFO Score SNP Statistics for Chr$1:\n-------------------------- \nTotal Number of Imputed Variants in Chromosome $1: $TOTAL_SNPS \nRemaining Total Variants in Chromosome $1 after INFO Filtering: $FILTERED_SNPS\n\n" >> ./3_Impute/${BaseName}/ConcatImputation/${BaseName}_Chr$1.snpstatOut
									
									
							else
								echo ERROR -- Specify Either T or F for OverwriteIfExist Variable
							fi
						else
							# Output TEMP INFO filtered list that ignores '#' headers, scans .snpstat for INFO scores (9th column of .snpstat), and filters/outputs SNP names (used later to filter)
							
								# Legacy Code
								#awk '/^[^#]/ { print $2,$9}' ./Impute/$BaseName/ConcatImputation/${BaseName}_Chr$1.snpstat | awk '{ if($2 >= $'$INFOThresh') {print $1}}' > ./Impute/$BaseName/ConcatImputation/INFOFiltered_Chr$1.list
								#awk '{ if($9 >= $'$INFOThresh') { print $2}}' ./Impute/$BaseName/ConcatImputation/${BaseName}_Chr$1.snpstat > ./Impute/$BaseName/ConcatImputation/INFOFiltered_Chr$1.list
								#awk 'FNR > 11 { if($9 >= '$INFOThresh') { print $2,$9 }}' ./Impute/$BaseName/ConcatImputation/${BaseName}_Chr$1.snpstat > ./Impute/$BaseName/ConcatImputation/INFOFiltered_Chr$1.list
								#awk '/^[^#]/ { first = \$1; \$1 = \"X\"; print \$0}' ./2_Phase/${BaseName}/Ody3_${BaseName}_Chr23_Phased.vcf.temp > ./2_Phase/${BaseName}/Ody3_${BaseName}_Chr23_Phased.vcf
		
								printf "\n\n\nScanning .snpstat SNP-Report for SNPs that meet the specified INFO Score cutoff of greater than: ${INFOThresh}\n"
								echo Outputting INFOFiltered list  that contains INFO Filtered SNP names and their corresponding INFO scores
								echo ----------------------------------------------
						
								awk '{ if (!/#|info/ && $9 >= '$INFOThresh') { print $2 }}' ./3_Impute/$BaseName/ConcatImputation/${BaseName}_Chr$1.snpstat > ./3_Impute/$BaseName/ConcatImputation/INFOFiltered_Chr$1.list.temp
								
							# Output INFO filtered list that ignores '#' headers, scans .snpstat for INFO scores (9th column of .snpstat), and filters/outputs SNP name and corresponding INFO score
								awk '{ if (!/#|info/ && $9 >= '$INFOThresh') { print $2, $9}}' ./3_Impute/$BaseName/ConcatImputation/${BaseName}_Chr$1.snpstat > ./3_Impute/$BaseName/ConcatImputation/INFOFiltered_Chr$1.list
								
							# Append SNP Filtering Stats to .snpstatOut
								printf "\n\nINFO Score SNP Statistics:\n"
								echo --------------------------
					
								TOTAL_SNPS="$(wc -l < ./3_Impute/${BaseName}/ConcatImputation/${BaseName}_Chr$1.snpstat)"
								FILTERED_SNPS="$(wc -l < ./3_Impute/${BaseName}/ConcatImputation/INFOFiltered_Chr$1.list)"
					
								echo Total Number of Imputed Variants in Chromosome $1: $TOTAL_SNPS
								echo Remaining Total Variants in Chromosome $1 after INFO Filtering: $FILTERED_SNPS
								echo
						fi
					else
						# Otherwise if there are no files with which to make a SNP list then say so	
						printf " \n\nNo Chromosomal .snpstat File Present for Chromosome $1 with which to filter SNPs -- Skipping \n"
					fi
					
					
				#          Use Plink to Filter/Convert .gen.gz with INFO score List to .VCF.gz
				# =-=-======================================================================================
				# ===========================================================================================	
					printf "\n\nUsing Plink to Filter/Convert the Chr$1.gen.gz to an INFO filtered .vcf\n" 
					echo -------------------------------------------------------------------
				
					# Conditional statement to see if there is a .gen.gz to convert to .vcf
					if ls ./3_Impute/"$BaseName"/ConcatImputation/*Chr$1.gen.gz 1> /dev/null 2>&1; then  

						# Conditional Statement to look to see if a Plink Created .vcf is already present
						if ls ./3_Impute/"$BaseName"/ConcatImputation/"$BaseName"_Chr$1.vcf.gz 1> /dev/null 2>&1; then
						
							printf "\nA .VCF.gz file for Chromosome $1 already exists -- What Should I do?\n"
							
							# If a list file for the particular chromosome is already present and overwrite is set to false, then skip the list creation
							if  [ "${OverwriteIfExist,,}" == "f" ]; then
							
								echo Do not overwrite ./3_Impute/"$BaseName"/ConcatImputation/"$BaseName"_Chr$1.vcf.gz -- Skipping Plink VCF Conversion for Chr $1
								echo
							
							# If a list file for the particular chromosome is already present and overwrite set to true, then overwrite it
							elif  [ "${OverwriteIfExist,,}" == "t" ]; then
								echo Will overwrite ./3_Impute/"$BaseName"/ConcatImputation/"$BaseName"_Chr$1.vcf.gz
								echo
								

								# Get chromosome number from the name of the file
									#FetchChr=$(echo $1 | egrep -o --ignore-case "chr[[:digit:]]{1,2}[^[:digit:]]{1}" | egrep -o --ignore-case "[[:digit:]]{1,2}")		
								
								# Runs Plink to convert the concatenated GEN to a VCF 4.3
									${Plink2_Exec} --memory 2000 require \
									--gen ./3_Impute/${BaseName}/ConcatImputation/${BaseName}_Chr$1.gen.gz \
									--sample ./3_Impute/${BaseName}/${BaseName}.sample \
									--export vcf vcf-dosage=GP \
									--extract ./3_Impute/${BaseName}/ConcatImputation/INFOFiltered_Chr$1.list.temp\
									--out ./3_Impute/${BaseName}/ConcatImputation/${BaseName}_Chr$1
									
								# Zip the Resulting File
									printf "\n\n\nZipping the Plink .VCF.gz file for Chromosome $1 to save space\n"
									echo --------------------------------------------------------------
									${gzip_Exec} ./3_Impute/${BaseName}/ConcatImputation/${BaseName}_Chr$1.vcf
									
							else
								echo ERROR -- Specify Either T or F for OverwriteIfExist Variable
							fi
						else
							# If does not exist then perform the conversion

							# Get chromosome number from the name of the file
								#FetchChr=$(echo $1 | egrep -o --ignore-case "chr[[:digit:]]{1,2}[^[:digit:]]{1}" | egrep -o --ignore-case "[[:digit:]]{1,2}")		
			
							# Runs Plink to convert the concatenated GEN to a VCF 4.3
								${Plink2_Exec} --memory 2000 require \
								--gen ./3_Impute/${BaseName}/ConcatImputation/${BaseName}_Chr$1.gen.gz \
								--sample ./3_Impute/${BaseName}/${BaseName}.sample \
								--export vcf vcf-dosage=GP \
								--extract ./3_Impute/${BaseName}/ConcatImputation/INFOFiltered_Chr$1.list.temp\
								--out ./3_Impute/${BaseName}/ConcatImputation/${BaseName}_Chr$1
								
							# Zip the Resulting File
								printf "\n\n\nZipping the Plink .VCF.gz file for Chromosome $1 to save space\n"
								echo --------------------------------------------------------------

								${gzip_Exec} ./3_Impute/${BaseName}/ConcatImputation/${BaseName}_Chr$1.vcf
							

						fi
					else
						# Otherwise if there are no files with which to filter/convert to make a dosage VCF then say so	
						printf " \n\nNo Chromosomal .gen.gz File Present for Chromosome $1 with which to filter and convert to a VCF.gz -- Skipping \n"
					fi
				}
				
			# ----- Configure GNU-Parallel (GNU-Parallel Tag) --------
					
			# On our system gnu-parallel is loaded via a module load command specified in Config.conf under the variable $LOAD_PARALLEL
			# As an alternative you could simply configure GNU-Parallel manually so that calling "parallel" runs GNU-Parallel
			# by adjusting the following lines so that GNU-Parallel runs on your system
			
			# Load/Inititalize GNU-Parallel
				$LOAD_PARALLEL 
			# -------- Configure GNU-Parallel --------	
			
			
			# Exports the BaseName and other variables as well as the exec path for SNPTEST so the child process (GNU-Parallel) can see it
				export BaseName
				export SNPTEST_Exec
				export -f CleanupFunc
				export CleanupStart
				export CleanupEnd
				export OverwriteIfExist
				export INFOThresh
				export Plink2_Exec
				export gzip_Exec
				
			# GNU-Parallel Command: Takes all the chromosomal .gen files and analyzes them in parallel
				# GNU-Parallel Request ETA: ETA output should only be run on interactive jobs
				if [ "${GNU_ETA,,}" == "t" ]; then
									
					seq $CleanupStart $CleanupEnd | parallel --eta CleanupFunc {} ">" ./3_Impute/${BaseName}/ConcatImputation/${BaseName}_Chr{}.snpstatOut
				
				elif [ "${GNU_ETA,,}" == "f" ]; then
					seq $CleanupStart $CleanupEnd | parallel CleanupFunc {} ">" ./3_Impute/${BaseName}/ConcatImputation/${BaseName}_Chr{}.snpstatOut
				
				else
					echo 'Input not recognized for GNU_ETA -- specify either T or F'
				
				fi
		


	
	
		# =-=-=-=====================================================================================
		#   Cleanup Gen File in Serial
		# ==========================================================================================
		# ===========================================================================================
		
		elif [ "${CleanupParallel,,}" == "f" ]; then
			echo
			echo ==============================================
			printf "    Cleanup Chrom.gen.gz In Serial Mode\n"
			echo ==============================================
			echo
			
			for chr in `eval echo {${CleanupStart}..${CleanupEnd}}`; do	
			
				#   Create a SNP Report for the concatenated chromosomal GEN file (Includes INFO score)
				# =-=-======================================================================================
				# ===========================================================================================
					
					printf "\n\nUsing SNPTEST to Analyze Chr $1 INFO Scores\n"
					echo ----------------------------------------------
				
				# Conditional statement to see if there is a Concatenated Chromosomal GEN file from which to make a SNP Report
				if ls ./3_Impute/${BaseName}/ConcatImputation/*Chr${chr}.gen.gz 1> /dev/null 2>&1; then 
					
					# Conditional Statement to look to see if a snpstat file for the particular chromosome is already present
					if ls ./3_Impute/${BaseName}/ConcatImputation/*Chr${chr}.snpstat 1> /dev/null 2>&1; then
						
						printf "A snpstat file for Chromosome ${chr}.snpstat already exists -- What Should I do?\n"
		
						# If a snpstat file for the particular chromosome is already present and overwrite is set to false, then skip the Info analysis
						if  [ "${OverwriteIfExist,,}" == "f" ]; then
							printf "Do not overwrite ./3_Impute/$BaseName/ConcatImputation/$BaseName_Chr${chr}.snpstat \nSkipping INFO Score Analysis for Chr ${chr}\n\n"
							
						# If a snpstat file for the particular chromosome is already present and overwrite is set to true, then overwrite it
						elif  [ "${OverwriteIfExist,,}" == "t" ]; then
							printf "Will overwrite ./3_Impute/$BaseName/ConcatImputation/$BaseName_Chr${chr}.snpstat\n\n"
							
							
							#Perform SNPTEST SNP Analysis
								printf "\n\nPerforming SNP Analysis on Chromosome ${chr} \n-----------------------------------------\n";
						
								printf "Options in Effect: \n$SNPTEST_Exec \n-summary_stats_only -assume_chromosome ${chr} \n-data ./3_Impute/${BaseName}/ConcatImputation/${BaseName}_Chr${chr}.gen.gz ./3_Impute/${BaseName}/${BaseName}.sample \n-chunk 10000 \n-o ./3_Impute/${BaseName}/ConcatImputation/${BaseName}_Chr${chr}.snpstat >> ./3_Impute/${BaseName}/ConcatImputation/${BaseName}_Chr${chr}.snpstatOut\n\n"
						
									$SNPTEST_Exec -summary_stats_only -assume_chromosome ${chr} -data ./3_Impute/${BaseName}/ConcatImputation/${BaseName}_Chr${chr}.gen.gz ./3_Impute/${BaseName}/.TempSample4SNPTEST.sample -chunk 10000 -o ./3_Impute/${BaseName}/ConcatImputation/${BaseName}_Chr${chr}.snpstat >> ./3_Impute/${BaseName}/ConcatImputation/${BaseName}_Chr${chr}.snpstatOut
						else
							echo ERROR -- Specify Either T or F for OverwriteIfExist Variable
							echo
						fi
					else
						# If a snpstat file for the particular chromosome is not present then do the Info analysis and make one
							
						#Perform SNPTEST SNP Analysis
							printf "\n\nPerforming SNP Analysis on Chromosome ${chr} \n-----------------------------------------\n";
						
							printf "Options in Effect: \n$SNPTEST_Exec \n-summary_stats_only -assume_chromosome ${chr} \n-data ./3_Impute/${BaseName}/ConcatImputation/${BaseName}_Chr${chr}.gen.gz ./3_Impute/${BaseName}/${BaseName}.sample \n-chunk 10000 \n-o ./3_Impute/${BaseName}/ConcatImputation/${BaseName}_Chr${chr}.snpstat >> ./3_Impute/${BaseName}/ConcatImputation/${BaseName}_Chr${chr}.snpstatOut\n\n"
						
							$SNPTEST_Exec -summary_stats_only -assume_chromosome ${chr} -data ./3_Impute/${BaseName}/ConcatImputation/${BaseName}_Chr${chr}.gen.gz ./3_Impute/${BaseName}/.TempSample4SNPTEST.sample -chunk 10000 -o ./3_Impute/${BaseName}/ConcatImputation/${BaseName}_Chr${chr}.snpstat >> ./3_Impute/${BaseName}/ConcatImputation/${BaseName}_Chr${chr}.snpstatOut
					fi
		
				else
					# Otherwise if there are no files to create a SNP Report then say so	
						printf " \n\nNo Chromosomal .gen.gz File Present for Chromosome $1 with which to create a SNP Report -- Skipping \n"
				fi				
								

						
				#                   Generate List to Filter Variants based on INFO scores
				# =-=-======================================================================================= 
				# ========================================================================================
				printf " \n\nMake List to Filter Variants Based on INFO Scores for Chr ${chr}\n"
				echo ------------------------------------------------------------

				# Conditional statement to see if there is a .snpstat file from which to filter variants
				if ls ./3_Impute/$BaseName/ConcatImputation/*Chr${chr}.snpstat 1> /dev/null 2>&1; then  

					# Conditional Statement to look to see if an INFOFiltered_Chr$1.list is already present
					if ls ./3_Impute/$BaseName/ConcatImputation/INFOFiltered_Chr${chr}.list 1> /dev/null 2>&1; then
						printf "An INFOFiltered file for Chromosome ${chr} already exists -- What Should I do?\n"
							
						# If a list file for the particular chromosome is already present and overwrite is set to false, then skip the list creation
						if  [ "${OverwriteIfExist,,}" == "f" ]; then
					
 							printf "Do not overwrite ./3_Impute/$BaseName/ConcatImputation/INFOFiltered_Chr${chr}.list \nSkipping INFO List Creation for Chr ${chr}, but still report INFO SNP Stats\n\n"
							
							
							# But Still Report SNP Filtering Stats to .snpstatOut
								
								printf "\n\nINFO Score SNP Statistics:\n"
								echo --------------------------
								TOTAL_SNPS="$(wc -l < ./3_Impute/${BaseName}/ConcatImputation/${BaseName}_Chr${chr}.snpstat)"
								FILTERED_SNPS="$(wc -l < ./3_Impute/${BaseName}/ConcatImputation/INFOFiltered_Chr${chr}.list)"
						
								echo Total Number of Imputed Variants in Chromosome ${chr}: $TOTAL_SNPS
								echo Remaining Total Variants in Chromosome ${chr} after INFO Filtering: $FILTERED_SNPS
								echo
							
						# If a list file for the particular chromosome is already present and overwrite set to true, then overwrite it
						elif  [ "${OverwriteIfExist,,}" == "t" ]; then
							echo Will overwrite ./3_Impute/$BaseName/ConcatImputation/INFOFiltered_Chr${chr}.list

							printf "\n\n\nScanning .snpstat SNP-Report for SNPs that meet the specified INFO Score cutoff of greater than: $INFOThresh\n"
							echo Outputting INFOFiltered list  which contains SNP names and their corresponding INFO scores 
							echo ----------------------------------------------	
								
								# Output TEMP INFO filtered list that ignores '#' headers, scans .snpstat for INFO scores (9th column of .snpstat), and filters/outputs SNP names (used later to filter)
									awk '{ if (!/#|info/ && $9 >= '$INFOThresh') { print $2 }}' ./3_Impute/$BaseName/ConcatImputation/${BaseName}_Chr${chr}.snpstat > ./3_Impute/$BaseName/ConcatImputation/INFOFiltered_Chr${chr}.list.temp
								
								# Output INFO filtered list that ignores '#' headers, scans .snpstat for INFO scores (9th column of .snpstat), and filters/outputs SNP name and corresponding INFO score
									awk '{ if (!/#|info/ && $9 >= '$INFOThresh') { print $2, $9}}' ./3_Impute/$BaseName/ConcatImputation/${BaseName}_Chr${chr}.snpstat > ./3_Impute/$BaseName/ConcatImputation/INFOFiltered_Chr${chr}.list
								
								# Lookup SNP Filtering Stats
									
									TOTAL_SNPS="$(wc -l < ./3_Impute/${BaseName}/ConcatImputation/${BaseName}_Chr${chr}.snpstat)"
									FILTERED_SNPS="$(wc -l < ./3_Impute/${BaseName}/ConcatImputation/INFOFiltered_Chr${chr}.list)"
					
									#Output to Screen
										printf "\n\n\nINFO Score SNP Statistics for Chr${chr}:\n-------------------------- \nTotal Number of Imputed Variants in Chromosome ${chr}: $TOTAL_SNPS \nRemaining Total Variants in Chromosome ${chr} after INFO Filtering: $FILTERED_SNPS\n\n"
								
									# Output to Snpstat.out
										printf "\n\nINFO Score SNP Statistics for Chr${chr}:\n-------------------------- \nTotal Number of Imputed Variants in Chromosome ${chr}: $TOTAL_SNPS \nRemaining Total Variants in Chromosome ${chr} after INFO Filtering: $FILTERED_SNPS\n\n" >> ./3_Impute/${BaseName}/ConcatImputation/${BaseName}_Chr${chr}.snpstatOut	
						else
							echo ERROR -- Specify Either T or F for OverwriteIfExist Variable	
						fi	
					else
					# If an INFOFiltered_Chr$1.list is not already present then make one
					
						# Output TEMP INFO filtered list that ignores '#' headers, scans .snpstat for INFO scores (9th column of .snpstat), and filters/outputs SNP names (used later to filter)
							awk '{ if (!/#|info/ && $9 >= '$INFOThresh') { print $2 }}' ./3_Impute/$BaseName/ConcatImputation/${BaseName}_Chr${chr}.snpstat > ./3_Impute/$BaseName/ConcatImputation/INFOFiltered_Chr${chr}.list.temp
								
						# Output INFO filtered list that ignores '#' headers, scans .snpstat for INFO scores (9th column of .snpstat), and filters/outputs SNP name and corresponding INFO score
							awk '{ if (!/#|info/ && $9 >= '$INFOThresh') { print $2, $9}}' ./3_Impute/$BaseName/ConcatImputation/${BaseName}_Chr${chr}.snpstat > ./3_Impute/$BaseName/ConcatImputation/INFOFiltered_Chr${chr}.list
								
						# Lookup SNP Filtering Stats
									
							TOTAL_SNPS="$(wc -l < ./3_Impute/${BaseName}/ConcatImputation/${BaseName}_Chr${chr}.snpstat)"
							FILTERED_SNPS="$(wc -l < ./3_Impute/${BaseName}/ConcatImputation/INFOFiltered_Chr${chr}.list)"
					
								#Output to Screen
									printf "\n\n\nINFO Score SNP Statistics for Chr${chr}:\n-------------------------- \nTotal Number of Imputed Variants in Chromosome ${chr}: $TOTAL_SNPS \nRemaining Total Variants in Chromosome ${chr} after INFO Filtering: $FILTERED_SNPS\n\n"
								
								# Output to Snpstat.out
									printf "\n\nINFO Score SNP Statistics for Chr${chr}:\n-------------------------- \nTotal Number of Imputed Variants in Chromosome ${chr}: $TOTAL_SNPS \nRemaining Total Variants in Chromosome ${chr} after INFO Filtering: $FILTERED_SNPS\n\n" >> ./3_Impute/${BaseName}/ConcatImputation/${BaseName}_Chr${chr}.snpstatOut		
					fi
				else
					# Otherwise if there are no files with which to make a SNP list then say so	
						printf " \n\nNo Chromosomal .snpstat File Present for Chromosome ${chr} with which to filter SNPs -- Skipping \n"
								
				fi				
								
				
				#          Use Plink to Filter/Convert .gen.gz with INFO score List to .VCF.gz
				# =-=-=====================================================================================
				# =========================================================================================	
				printf "\n\nUsing Plink to Filter/Convert the Chr${chr}.gen.gz to an INFO filtered .vcf\n" 
				echo --------------------------------------------------------------------------
							
				# Conditional statement to see if there is a .gen.gz to convert to .vcf
				if ls ./3_Impute/$BaseName/ConcatImputation/*Chr${chr}.gen.gz 1> /dev/null 2>&1; then 			
							
					# Conditional Statement to look to see if a Plink Created .vcf is already present
					if ls ./3_Impute/$BaseName/ConcatImputation/${BaseName}_Chr${chr}.vcf.gz 1> /dev/null 2>&1; then			
							
						printf "A .VCF.gz file for Chromosome ${chr} already exists -- What Should I do?\n"

						# If a vcf.gz file for the particular chromosome is already present and overwrite is set to false, then skip the list creation
						if  [ "${OverwriteIfExist,,}" == "f" ]; then

							echo Do not overwrite ./3_Impute/$BaseName/ConcatImputation/${BaseName}_Chr${chr}.vcf.gz -- Skipping Plink VCF Conversion for Chr ${chr}
							echo
							echo
						
						# If a vcf.gz file for the particular chromosome is already present and overwrite set to true, then overwrite it
						elif  [ "${OverwriteIfExist,,}" == "t" ]; then
							echo Will overwrite ./3_Impute/"$BaseName"/ConcatImputation/"$BaseName"_Chr${chr}.vcf.gz
							echo
							echo
							
								# Get chromosome number from the name of the file
									#FetchChr=$(echo $1 | egrep -o --ignore-case "chr[[:digit:]]{1,2}[^[:digit:]]{1}" | egrep -o --ignore-case "[[:digit:]]{1,2}")
							
							# Runs Plink to convert the concatenated GEN to a VCF 4.3
								${Plink2_Exec} --memory 2000 require \
								--gen ./3_Impute/${BaseName}/ConcatImputation/${BaseName}_Chr${chr}.gen.gz \
								--sample ./3_Impute/${BaseName}/${BaseName}.sample \
								--export vcf vcf-dosage=GP \
								--extract ./3_Impute/${BaseName}/ConcatImputation/INFOFiltered_Chr${chr}.list.temp\
								--out ./3_Impute/${BaseName}/ConcatImputation/${BaseName}_Chr${chr}		
 
							# Zip the Resulting File
								printf "\n\n\nZipping the Plink .VCF.gz file for Chromosome ${chr} \n"
								echo --------------------------------------------------------------
								${gzip_Exec} ./3_Impute/${BaseName}/ConcatImputation/${BaseName}_Chr${chr}.vcf

						else
							echo ERROR -- Specify Either T or F for OverwriteIfExist Variable
						fi
					else	
						# If does not yet exist then perform the conversion to make one
						# Runs Plink to convert the concatenated GEN to a VCF 4.3
							${Plink2_Exec} --memory 2000 require\
							--gen ./3_Impute/${BaseName}/ConcatImputation/${BaseName}_Chr${chr}.gen.gz \
							--sample ./3_Impute/${BaseName}/${BaseName}.sample \
							--export vcf vcf-dosage=GP \
							--extract ./3_Impute/${BaseName}/ConcatImputation/INFOFiltered_Chr${chr}.list.temp\
							--out ./3_Impute/${BaseName}/ConcatImputation/${BaseName}_Chr${chr}		
 
						# Zip the Resulting File
							printf "\n\n\nZipping the Plink .VCF.gz file for Chromosome ${chr} \n"
							echo --------------------------------------------------------------
							${gzip_Exec} ./3_Impute/${BaseName}/ConcatImputation/${BaseName}_Chr${chr}.vcf
					fi
	
				else
					# Otherwise if there are no files with which to filter/convert to make a dosage VCF then say so	
					printf " \n\nNo Chromosomal .gen.gz File Present for Chromosome ${chr} with which to filter and convert to a VCF.gz -- Skipping \n"
				fi
			done
			

		else
			echo ERROR -- Specify Either T or F for Cleanup Variable
		fi
		
		
		
		# TarGZ .snpstat/Out and INFOFiltered files
		# -------------------------------------------
			printf "\n\nTar and Zipping IMPUTE INFO score information\n"
			echo -----------------------------------------------------
		
		
		# TGZ the .snpstat files
		# =======================
			printf "\n\nTar-Zipping .snpstat files to ./3_Impute/$BaseName/ConcatImputation/${BaseName}_INFOMetrics.tgz \n"
			
			# Are .snpstat files present to tgz?
			if ls ./3_Impute/$BaseName/ConcatImputation/*.snpstat 1> /dev/null 2>&1; then
			
				# If .snpstat files are present does a corresponding tgz file already exist?
				if ls ./3_Impute/$BaseName/ConcatImputation/${BaseName}_INFOMetricsSummary.tgz 1> /dev/null 2>&1; then
				
				printf "\nFile Already Exists! What should I do? Checking Overwrite Settings...\n"
				
					# If they exist overwrite if on
					if  [ "${OverwriteIfExist,,}" == "t" ]; then
						printf "......Overwrite is ON so will overwrite\n"
						${tar_Exec} -czvf ./3_Impute/$BaseName/ConcatImputation/${BaseName}_INFOMetricsSummary.tgz ./3_Impute/$BaseName/ConcatImputation/*.snpstat
					
					# Do not overwrite if off
					elif [ "${OverwriteIfExist,,}" == "f" ]; then
						printf "......Overwrite is OFF so will skip\n"
					else
						printf "ERROR -- Specify Either T or F for OverwriteIfExist Variable"
					fi
				# If doesn't exist then make it
				else
					${tar_Exec} -czvf ./3_Impute/$BaseName/ConcatImputation/${BaseName}_INFOMetricsSummary.tgz ./3_Impute/$BaseName/ConcatImputation/*.snpstat
				fi
			else
				printf "\n-- No .snpstat files to Tar-zip --\n\n"
			fi
		
		# TGZ the .snpstatOut files
		# =======================		
			printf "\n\nTar-Zipping .snpstatOut files to ./3_Impute/$BaseName/ConcatImputation/${BaseName}_INFOMetricsMeta.tgz \n"
			
			# Are .snpstatOut files present to tgz?
			if ls ./3_Impute/$BaseName/ConcatImputation/*.snpstatOut 1> /dev/null 2>&1; then
			
				# If .snpstatOut files are present does a corresponding tgz file already exist?
				if ls ./3_Impute/$BaseName/ConcatImputation/${BaseName}_INFOMetricsMeta.tgz 1> /dev/null 2>&1; then
				
					printf "\nFile Already Exists! What should I do? Checking Overwrite Settings\n"
					
					# If they exist overwrite if on
					if  [ "${OverwriteIfExist,,}" == "t" ]; then
						printf "......Overwrite is ON so will overwrite\n"
						${tar_Exec} -czvf ./3_Impute/$BaseName/ConcatImputation/${BaseName}_INFOMetricsMeta.tgz ./3_Impute/$BaseName/ConcatImputation/*.snpstatOut					
					# Do not overwrite if off
					elif [ "${OverwriteIfExist,,}" == "f" ]; then
						printf "......Overwrite is OFF so will skip\n"
					
					else
						printf "ERROR -- Specify Either T or F for OverwriteIfExist Variable"
					fi
				# If doesn't exist then make it
				else
					${tar_Exec} -czvf ./3_Impute/$BaseName/ConcatImputation/${BaseName}_INFOMetricsMeta.tgz ./3_Impute/$BaseName/ConcatImputation/*.snpstatOut
				fi
			else
				printf "\n-- No .snpstatOut files to Tar-zip --\n\n"
			fi
			
		# TGZ the .INFOFiltered files
		# =======================		
			printf "\n\nTar-Zipping INFOFiltered files to ./3_Impute/$BaseName/ConcatImputation/${BaseName}_INFOMetricsRaw.tgz \n"
			
			# Are INFOFiltered files present to tgz?
			if ls ./3_Impute/$BaseName/ConcatImputation/INFOFiltered*.list 1> /dev/null 2>&1; then
			
				# If INFOFiltered files are present does a corresponding tgz file already exist?
				if ls ./3_Impute/$BaseName/ConcatImputation/${BaseName}_INFOMetricsFilteredRawValues.tgz 1> /dev/null 2>&1; then
				
				printf "\nFile Already Exists! What should I do? Checking Overwrite Settings\n"

					# If they exist overwrite if on
					if  [ "${OverwriteIfExist,,}" == "t" ]; then
					
						printf "......Overwrite is ON so will overwrite\n"
						${tar_Exec} -czvf ./3_Impute/$BaseName/ConcatImputation/${BaseName}_INFOMetricsFilteredRawValues.tgz ./3_Impute/$BaseName/ConcatImputation/INFOFiltered*.list
					
					# Do not overwrite if off
					elif [ "${OverwriteIfExist,,}" == "f" ]; then
						printf "......Overwrite is OFF so will skip\n\n"
					else
						printf "ERROR -- Specify Either T or F for OverwriteIfExist Variable"
					fi
				# If doesn't exist then make it
				else
					${tar_Exec} -czvf ./3_Impute/$BaseName/ConcatImputation/${BaseName}_INFOMetricsFilteredRawValues.tgz ./3_Impute/$BaseName/ConcatImputation/INFOFiltered*.list
				fi
			else
				printf "\n-- No INFOFiltered files to Tar-zip --\n\n"
			fi
	
	elif [ "${Cleanup,,}" == "f" ]; then
		echo
		echo
		echo ------ Skipping .GEN File Cleanup of IMPUTE4 Chromosomal .GEN Files ------
		echo
		
	else
		echo ERROR -- Specify Either T or F for Cleanup Variable
	fi
		
	
	# =-=-=-=-==============================================================================================
	# ======================================================================================================
	#                  Use BCFTools to Merge the VCF Files Created by Plink
	# ======================================================================================================
	# ======================================================================================================
	
		
	if [ "${MergeVCF,,}" == "t" ]; then
	
	
		# Conditional statement to find if there are files to concatenate for the currently iterated chromosome
			if ls ./3_Impute/${BaseName}/ConcatImputation/*.vcf.gz 1> /dev/null 2>&1; then
	
			# If there are .vcf.gz files to concatenate then list them (in order) on the screen
				echo
				printf "\n\n\nConcatenating the following VCF.gz files using BCFTools:\n"
				echo ---------------------------------------------------
				ls -1av ./3_Impute/${BaseName}/ConcatImputation/${BaseName}*.vcf.gz
				echo ---------------------------------------------------
				echo ...to ./3_Impute/${BaseName}/ConcatImputation/Imputed_${BaseName}_Merged.vcf.gz
				echo
		
			# Set List entries as a variable
				VCF2Merge="$(find ./3_Impute/${BaseName}/ConcatImputation/ -maxdepth 1 -type f -name "*.vcf.gz" |sort -V)"
		
			# Conditional Statement to look to see if a BCFTools merged VCF File is already present
				if ls ./3_Impute/${BaseName}/ConcatImputation/1Imputed__${BaseName}_Merged.vcf.gz 1> /dev/null 2>&1; then
				
				printf "\nFile Already Exists! What should I do? Checking Overwrite Settings...\n"
				# If the file exists and overwrite is set to false, then skip the list creation
					if  [ "${OverwriteIfExist,,}" == "f" ]; then
					
						printf "......Overwrite is OFF so will skip\n"
						
				# If the file exists and overwrite is set to true, then overwrite it
					elif  [ "${OverwriteIfExist,,}" == "t" ]; then
						printf "......Overwrite is ON so will overwrite\n"
							

						# Use BCFTools to Merge the VCF Files Listed in the variable
							${bcftools} concat --threads ${ConcatThreads} ${VCF2Merge} --output-type z --output ./3_Impute/${BaseName}/ConcatImputation/1Imputed__${BaseName}_Merged.vcf.gz
		
						# Change Permission so the cat script can access it
							chmod -f 700 ./3_Impute/${BaseName}/ConcatImputation/1Imputed__${BaseName}_Merged.vcf.gz || true
					
					else
						echo ERROR -- Specify Either T or F for OverwriteIfExist Variable
					fi
				else	
					# If does not yet exist then perform the merge to make one
						# Use BCFTools to Merge the VCF Files Listed in the variable
							${bcftools} concat --threads ${ConcatThreads} ${VCF2Merge} --output-type z --output ./3_Impute/${BaseName}/ConcatImputation/1Imputed__${BaseName}_Merged.vcf.gz
		
						# Change Permission so the cat script can access it
							chmod -f 700 ./3_Impute/${BaseName}/ConcatImputation/1Imputed__${BaseName}_Merged.vcf.gz || true
				fi

		# Otherwise if there are no files to concatenate for the currently iterated chromosome then say so	
			else
				printf "\n-- No VCF.gz Files for BCFTools to Concatenate --\n\n"
			fi
		
	
	elif [ "${MergeVCF,,}" == "f" ]; then
		printf "\n------ Skipping the Merging of Impute4 Chromosomal VCFs to a Single VCF ------\n\n"
	
	else
		printf "\nERROR -- Specify Either T or F for MergeVCF Variable\n\n"
					
	fi
	
# -------------------------------------	
# Remove Temporary Files to Save Space
# -------------------------------------
		
	if [ "${RmTemp,,}" == "t" ]; then	
	
	echo --------------------------------
	printf "Tidying Up\n"
	echo ================================	
	
			# Delete Raw Imputation Files
				printf "\n\nDelete Raw Imputation Folder and Redundant Temp Files\n"
				echo ------------------------------------------------------------------------------
				if [ -d ./3_Impute/$BaseName/RawImputation/ ]; then  rm -r ./3_Impute/$BaseName/RawImputation/; fi
				rm -r ./3_Impute/$BaseName/ConcatImputation/*.temp
				rm -r ./3_Impute/$BaseName/ConcatImputation/$BaseName*Chr*.vcf.gz

			# Then Remove leftover .snpstat/Out and INFOFiltered files if corresponding tgz file exists
				printf "\n\nRemoving leftover .snpstat files if corresponding .tgz is already made\n"
				echo ------------------------------------------------------------------------------
				if [ -f ./3_Impute/$BaseName/ConcatImputation/${BaseName}_INFOMetricsSummary.tgz ]; then  rm -r ./3_Impute/$BaseName/ConcatImputation/*.snpstat; fi
				if [ -f ./3_Impute/$BaseName/ConcatImputation/${BaseName}_INFOMetricsMeta.tgz ]; then  rm -r ./3_Impute/$BaseName/ConcatImputation/*.snpstatOut; fi
				if [ -f ./3_Impute/$BaseName/ConcatImputation/${BaseName}_INFOMetricsFilteredRawValues.tgz ]; then  rm -r ./3_Impute/$BaseName/ConcatImputation/INFOFiltered*; fi
				
				
	else
		
		printf "\n\nKeeping Temporary Files\n"
		echo ---------------------------------------
		echo
		echo
	fi

# ----------------------------------------------
# Super Clean to Remove all but the bare bones
# ----------------------------------------------
		
	if [ "${SuperClean,,}" == "t" ]; then	
	
		printf "\n\nRemoving All But Essential Files\n"
		echo ---------------------------------------
		echo
		echo
			# Delete Raw Imputation Files
			#rm -r ./3_Impute/$BaseName/ConcatImputation/*.snpstat.gz
			rm -r ./3_Impute/$BaseName/ConcatImputation/$BaseName*Chr*.gen.gz

	fi
	
# =-=-=-=-=-==============================================================================================
#  ======================================================================================================
#   =============================== Minimac4 Post Imputation File Cleaning =============================
#  ======================================================================================================
# ========================================================================================================	
	

elif [ "${UseMinimac,,}" == "t" ]; then

	echo
	echo
	echo ----------------------------------------------------------------
	printf "Performing Post Imputation File Clean Up on Minimac4 Files\n"
	echo ================================================================
	
	# Make Directory in which to place merged concatenated files
	#----------------------------------------------------------------------------
		echo
		echo Creating Concat Cohort Folder within Impute Directory
		echo ----------------------------------------------
		echo
			mkdir -p ./3_Impute/${BaseName}/ConcatImputation
	
	# Use Lustre Stripping?
		if [ "${LustreStrip,,}" == "t" ]; then
			lfs setstripe -c 5 ./3_Impute/${BaseName}/ConcatImputation
		fi

	
	# =-=-=-=====================================================================================
	#   Cleanup .dose.vcf.gz File in in parallel using GNU-Parallel
	#  =========================================================================================
	# ===========================================================================================
	
	if [ "${Cleanup,,}" == "t" ]; then
	
		if [ "${CleanupParallel,,}" == "t" ]; then
			
			echo
			echo =========================================================
		printf " Running Parallel .dose.vcf.gz Cleanup with GNU-Parallel\n"
		printf "     Each CPU will analyze 1 chromosome at a time\n\n"
		printf "    You may have to configure GNU-Parallel manually\n"
		printf "  See Settings.conf for instructions on how to do this\n"
			echo =========================================================
			echo
	
			# GNU-Parallel Function that Performs multiple steps to cleanup the Minimac4 concatenated .dose.vcf.gz
			function CleanupFunc() {	
			
				#       Use Plink to Filter .dose.vcf.gz with built in R2 score to .vcf.gz
				# =-=-=====================================================================================
				# =========================================================================================
				
					printf "\n\nUsing Plink to Filter the Chr$1.dose.vcf.gz to an R2 filtered .vcf.gz\n" 
					echo ----------------------------------------------------------------------
				
				# Conditional statement to see if there is a .dose.vcf.gz to convert to .vcf.gz
				if ls ./3_Impute/"$BaseName"/RawImputation/*Chr$1.dose.vcf.gz 1> /dev/null 2>&1; then  
	
					# Conditional Statement to look to see if a Plink Created .vcf is already present
					if ls ./3_Impute/"$BaseName"/ConcatImputation/"$BaseName"_Chr$1.vcf.gz 1> /dev/null 2>&1; then
						
						printf "\nA .VCF.gz file for Chromosome $1 already exists -- What Should I do?\n"
							
						# If a file for the particular chromosome is already present and overwrite is set to false, then skip the file creation
						if  [ "${OverwriteIfExist,,}" == "f" ]; then
							
							echo Do not overwrite ./3_Impute/"$BaseName"/RawImputation/"$BaseName"_Chr$1.vcf.gz -- Skipping Plink VCF Filtration for Chr $1
							echo
							
						# If a file for the particular chromosome is already present and overwrite set to true, then overwrite it
						elif  [ "${OverwriteIfExist,,}" == "t" ]; then
							echo Will overwrite ./3_Impute/"$BaseName"/RawImputation/"$BaseName"_Chr$1.vcf.gz
							echo
	
							# Get chromosome number from the name of the file
								#FetchChr=$(echo $1 | egrep -o --ignore-case "chr[[:digit:]]{1,2}[^[:digit:]]{1}" | egrep -o --ignore-case "[[:digit:]]{1,2}")		
							
							# Runs Plink to convert the concatenated dosage VCF to an R2 Filtered VCF 4.3
								${Plink2_Exec} --memory 2000 require --vcf ./3_Impute/${BaseName}/RawImputation/Ody4_${BaseName}_Chr$1.dose.vcf.gz dosage=HDS --exclude-if-info "R2<=0.3" --export vcf vcf-dosage=GP --out ./3_Impute/${BaseName}/ConcatImputation/${BaseName}_Chr$1
								
								# Runs Plink to convert the concatenated dosage VCF to an R2 Filtered VCF 4.3
								
								#${Plink2_Exec} --memory 2000 require \
								--vcf ./3_Impute/${BaseName}/RawImputation/Ody4_${BaseName}_Chr$1.dose.vcf.gz  dosage=HDS \
								--exclude-if-info "R2<=0.3"	\
								--make-pgen \
								--out ./3_Impute/${BaseName}/ConcatImputation/${BaseName}_Chr$1 \
							
							# Zip the Resulting File
								printf "\n\n\nZipping the Plink Filtered .VCF.gz file for Chromosome $1 \n"
								echo --------------------------------------------------------------
								${gzip_Exec} -f ./3_Impute/${BaseName}/ConcatImputation/${BaseName}_Chr$1.vcf
		
						else
								echo ERROR -- Specify Either T or F for OverwriteIfExist Variable
						fi
					else
						# If does not exist then perform the conversion
	
						# Get chromosome number from the name of the file
							#FetchChr=$(echo $1 | egrep -o --ignore-case "chr[[:digit:]]{1,2}[^[:digit:]]{1}" | egrep -o --ignore-case "[[:digit:]]{1,2}")		
			
						# Runs Plink to filter the concatenated dosage VCF to an R2 Filtered VCF 4.3
							${Plink2_Exec} --memory 2000 require --vcf ./3_Impute/${BaseName}/RawImputation/Ody4_${BaseName}_Chr$1.dose.vcf.gz dosage=HDS --exclude-if-info "R2<=${INFOThresh}" --export vcf vcf-dosage=GP --out ./3_Impute/${BaseName}/ConcatImputation/${BaseName}_Chr$1
							
								
						# Zip the Resulting File
							printf "\n\n\nZipping the Plink Filtered .VCF.gz file for Chromosome $1 \n"
							echo --------------------------------------------------------------
							${gzip_Exec} -f ./3_Impute/${BaseName}/ConcatImputation/${BaseName}_Chr$1.vcf
					fi
				else
					# Otherwise if there are no files with which to filter to make a .vcf.gz then say so	
						printf " \n\nNo Chromosomal .dosage.vcf.gz File Present for Chromosome ${chr} with which to filter to a VCF.gz -- Skipping \n"
				fi
			}
					
			# ----- Configure GNU-Parallel (GNU-Parallel Tag) --------
					
			# On our system gnu-parallel is loaded via a module load command specified in Config.conf under the variable $LOAD_PARALLEL
			# As an alternative you could simply configure GNU-Parallel manually so that calling "parallel" runs GNU-Parallel
			# by adjusting the following lines so that GNU-Parallel runs on your system
			
			# Load/Inititalize GNU-Parallel
				$LOAD_PARALLEL 
			# -------- Configure GNU-Parallel --------	
				
				
			# Exports the BaseName and other variables as well as the exec path for SNPTEST so the child process (GNU-Parallel) can see it
				export BaseName
				export -f CleanupFunc
				export CleanupStart
				export CleanupEnd
				export OverwriteIfExist
				export INFOThresh
				export Plink2_Exec
				export gzip_Exec
				
			# GNU-Parallel Command: Takes all the chromosomal .gen files and analyzes them in parallel
				# GNU-Parallel Request ETA: ETA output should only be run on interactive jobs
				if [ "${GNU_ETA,,}" == "t" ]; then
									
					seq $CleanupStart $CleanupEnd | parallel --eta CleanupFunc {} ">" ./3_Impute/${BaseName}/ConcatImputation/${BaseName}_Chr{}.Out
				
				elif [ "${GNU_ETA,,}" == "f" ]; then
					seq $CleanupStart $CleanupEnd | parallel CleanupFunc {} ">" ./3_Impute/${BaseName}/ConcatImputation/${BaseName}_Chr{}.Out
				
				else
					echo 'Input not recognized for GNU_ETA -- specify either T or F'
				
				fi
			
			
		elif [ "${CleanupParallel,,}" == "f" ]; then	
		
			# =-=-=-=====================================================================================
			#   Cleanup .dosage.vcf.gz File in Serial
			# ==========================================================================================
			# ===========================================================================================
			
			for chr in `eval echo {${CleanupStart}..${CleanupEnd}}`; do	
	
				#       Use Plink to Filter .dosage.vcf.gz with in-built R2 to .dosage.vcf.gz
				# =========================================================================================
				# =========================================================================================	
					printf "\n\nUsing Plink to Filter the Chr${chr}.dosage.vcf.gz to an R2 filtered .vcf.gz\n" 
					echo -------------------------------------------------------------------------------
								
					# Conditional statement to see if there is a .dosage.vcf.gz to convert to .vcf.gz
					if ls ./3_Impute/$BaseName/RawImputation/*Chr${chr}.dose.vcf.gz 1> /dev/null 2>&1; then 			
								
						# Conditional Statement to look to see if a Plink Created .vcf.gz is already present
						if ls ./3_Impute/$BaseName/ConcatImputation/${BaseName}_Chr${chr}.vcf.gz 1> /dev/null 2>&1; then			
								
							printf "A .VCF.gz file for Chromosome ${chr} already exists -- What Should I do?\n"
	
							# If a vcf.gz file for the particular chromosome is already present and overwrite is set to false, then skip the file creation
							if  [ "${OverwriteIfExist,,}" == "f" ]; then
	
								echo Do not overwrite ./3_Impute/$BaseName/ConcatImputation/${BaseName}_Chr${chr}.vcf.gz -- Skipping Plink VCF Filtration for Chr ${chr}
								echo
								echo
							
							# If a vcf.gz file for the particular chromosome is already present and overwrite set to true, then overwrite it
							elif  [ "${OverwriteIfExist,,}" == "t" ]; then
								echo Will overwrite ./3_Impute/"$BaseName"/ConcatImputation/"$BaseName"_Chr${chr}.vcf.gz
								echo
								echo
								
									# Get chromosome number from the name of the file
										#FetchChr=$(echo $1 | egrep -o --ignore-case "chr[[:digit:]]{1,2}[^[:digit:]]{1}" | egrep -o --ignore-case "[[:digit:]]{1,2}")
								
								# Runs Plink to filter the concatenated dosage VCF to an R2 Filtered VCF 4.3
								echo ${Plink2_Exec}
									${Plink2_Exec} --memory 2000 require --vcf ./3_Impute/${BaseName}/RawImputation/Ody4_${BaseName}_Chr${chr}.dose.vcf.gz dosage=HDS --exclude-if-info "R2<=${INFOThresh}" --export vcf vcf-dosage=GP --out ./3_Impute/${BaseName}/ConcatImputation/${BaseName}_Chr${chr}
									
								# Zip the Resulting File
									printf "\n\n\nZipping the Plink Filtered .VCF.gz file for Chromosome $1 \n"
									echo --------------------------------------------------------------
									${gzip_Exec} -f ./3_Impute/${BaseName}/ConcatImputation/${BaseName}_Chr${chr}.vcf
			
							else
								echo ERROR -- Specify Either T or F for OverwriteIfExist Variable
							fi
						else	
							# If file does not yet exist then perform the filtration to make one
							# Runs Plink to filter the concatenated dosage VCF to an R2 Filtered VCF 4.3
								${Plink2_Exec} --memory 2000 require --vcf ./3_Impute/${BaseName}/RawImputation/Ody4_${BaseName}_Chr${chr}.dose.vcf.gz dosage=HDS --exclude-if-info "R2<=${INFOThresh}" --export vcf vcf-dosage=GP --out ./3_Impute/${BaseName}/ConcatImputation/${BaseName}_Chr${chr}
								
							# Zip the Resulting File
								printf "\n\n\nZipping the Plink Filtered .VCF.gz file for Chromosome $1 \n"
								echo --------------------------------------------------------------
								${gzip_Exec} -f ./3_Impute/${BaseName}/ConcatImputation/${BaseName}_Chr${chr}.vcf
						fi
		
					else
						# Otherwise if there are no files with which to filter to make a .vcf.gz then say so	
						printf " \n\nNo Chromosomal .dosage.vcf.gz File Present for Chromosome ${chr} with which to filter to a VCF.gz -- Skipping \n"
					fi
			done
		else
			printf "\n\nERROR -- Specify Either T or F for CleanupParallel Variable\n\n"
		fi
	
	elif [ "${Cleanup,,}" == "f" ]; then
 		printf "\n\n\n------ Skipping Minimac4 .dose.vcf.gz Cleanup ------\n\n"
	
	else
		printf "\n\nERROR -- Specify Either T or F for Cleanup Variable\n\n"
	fi
	
		
	# ======================================================================================================
	# ======================================================================================================
	#                  Use BCFTools to Merge the VCF Files Created by Plink
	# ======================================================================================================
	# ======================================================================================================	
	
	if [ "${MergeVCF,,}" == "t" ]; then
	# Conditional statement to find if there are files to concatenate for chromosomes
			if ls ./3_Impute/${BaseName}/ConcatImputation/*.vcf.gz 1> /dev/null 2>&1; then
	
		# If there are .vcf.gz files to concatenate then list them (in order) on the screen
			echo
			printf "\nConcatenating the following VCF.gz files using BCFTools:\n"
			echo ---------------------------------------------------
			ls -1av ./3_Impute/${BaseName}/ConcatImputation/*.vcf.gz
			echo ---------------------------------------------------
			echo ...to ./3_Impute/${BaseName}/ConcatImputation/Imputed_${BaseName}_Merged.vcf.gz
					
		# Set List entries as a variable
			VCF2Merge="$(find ./3_Impute/${BaseName}/ConcatImputation/ -maxdepth 1 -type f -name "*.vcf.gz" |sort -V)"
	
		# Use BCFTools to Merge the VCF Files Listed in the variable
			${bcftools} concat --threads ${ConcatThreads} ${VCF2Merge} --output-type z --output ./3_Impute/${BaseName}/ConcatImputation/1Imputed__${BaseName}_Merged.vcf.gz
	
		# Change Permission so the cat script can access it
			chmod -f 700 ./3_Impute/${BaseName}/ConcatImputation/1Imputed__${BaseName}_Merged.vcf.gz || true
			
	
	# Otherwise if there are no files to concatenate for the currently iterated chromosome then say so	
			else
				
				printf "\nNo VCF.gz Files for BCFTools to Concatenate\n\n"
					
			fi
	
	elif [ "${MergeVCF,,}" == "f" ]; then
		printf "\n------ Skipping the Merging of Impute4 Chromosomal VCFs to a Single VCF ------\n\n"
	
	else
		printf "\nERROR -- Specify Either T or F for MergeVCF Variable\n\n"
					
	fi			
	
	
	# Remove Temporary Files to Save Space
	if [ "${RmTemp,,}" == "t" ]; then

	echo --------------------------------
	printf "Tidying Up\n"
	echo ================================	

		# Delete Raw Imputation Files
		if [ -d ./3_Impute/$BaseName/RawImputation/ ]; then rm -r ./3_Impute/$BaseName/RawImputation/; fi

	else
		
		printf "\n\nKeeping Temporary Files\n"
		echo ---------------------------------------
		echo
		echo
	fi
	
	# Super Clean to Remove all but the bare bones
		
	if [ "${SuperClean,,}" == "t" ]; then	
	
		printf "\n\nRemoving All But Essential Files\n"
		echo ---------------------------------------
		echo
		echo
			# Delete Raw Imputation Files
			#rm -r ./3_Impute/$BaseName/ConcatImputation/*.snpstat.gz
			rm -r ./3_Impute/$BaseName/ConcatImputation/$BaseName*Chr*.vcf.gz
	fi
		


else
	printf "\n\nNeither UseMinimac or UseImpute Set to T So Nothing to Cleanup -- Exiting\n\n"

fi

	
# Termination Message
	echo
	echo ============
	printf " Phew Done!\n"
	echo ============
	echo
	echo




