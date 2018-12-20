#!/bin/bash 

# Overview:
# ==================

# This script will:
# 1. Concatenate GEN file
# 2. Analyze the variants on the concatenated GEN file (meanwhile...)
# 3. Concatenate the chromosomal gen files to a single dataset gen file
# 4. Convertt the chromosomal GEN file to a Pgen file for Plink Analysis



echo
echo ==================================
echo ----------------------------------
echo Odyssey v1.0 -- Updated 7-10-2018 
echo ----------------------------------
echo ==================================
echo 

# Call Variables from Config
# ----------------------------
source Config.conf
source Programs.conf


# Set Working Directory
# -------------------------------------------------
echo
echo Changing to Working Directory
echo ----------------------------------------------
echo ${WorkingDir}
echo

	cd ${WorkingDir}
	
# Perform Error Analysis on Imputation Step (grep looks for log files containing 'error' or 'segmentation')
# -----------------------------

if [ "${ImputationErrorAnalysis}" == "T" ]; then

	echo
	echo Performing Error Analysis on Imputation Step:
	echo ----------------------------------------------
	echo 
	echo Note: Some errors are caused by no SNPs being in the imputed area -- this is not really an issue -- skip the segment
	echo Note: Other errors are listed as segmentation faults -- memory access issues -- try re-running or use Impute2 and re-run
	echo 
	echo Imputation Segments that should be reviewed are listed below:
	echo ==============================================
	echo
	grep "segmentation\|error" ./Impute/${BaseName}/Scripts2Impute/*
	echo
	echo ==============================================
	echo
fi


# Impute concatenation of chromosomal .gen file chunks
# -----------------------------

if [ "${ConcatImpute}" == "T" ]; then

# Make Lustre Stripped Directory in which to place merged concatenated files
#----------------------------------------------------------------------------
	
echo
echo Creating Concat Cohort Folder within Impute Directory
echo ----------------------------------------------
echo
	mkdir -p ./Impute/${BaseName}/ConcatImputation
	
	# Use Lustre Stripping?
	if [ "${LustreStrip}" == "T" ]; then
		lfs setstripe -c 5 ./Impute/${BaseName}/ConcatImputation
	fi
	
	
	if [ "${ConcatParallel}" == "T" ]; then
		# This is a GNU Parallel command that first searches for *Chr[#]_* to see if the file exists
			# GNU Parallel (https://www.gnu.org/software/parallel/) must be installed on the system to use this option
			# If GNU-Parallel is installed it will find all the .gen chunks for the chromosome and concatenate them together
			# If the chromosomal file doesn't exist then it will report that it doesn't exist
			# All concatenations are performed in parallel based on the number of CPU cores detected (since concatenation is a light resource command)
		
		# Load GNU-Parallel and execute the parallel command to concatenate in parallel
			
			echo Running Parallel Concatenation with GNU-Parallel
			echo Each CPU will concatenated 3 chromosomes at a time
			echo To change this setting modify the -j option in 3b_ConcatenateSegments.sh
			echo
			echo You may have to configure GNU-Parallel manually to run on your system
			echo 	See Config.conf for instructions on how to do this
			echo ---------------------------------------------------------
			echo
			
			
			function Concat() {
				if ls ./Impute/"$BaseName"/RawImputation/*Chr$1_*.gen 1> /dev/null 2>&1; then 
					
					#Say what chr was concatenated
						printf "\n\nConcatenated Chromosome $1\n\n"
					
					# Find all the chromosomal segments for a particular chromosome, sort them in order, replaces the first column with a chromsome number, then concatenate them to a single Chr .gen
						find ./Impute/"$BaseName"/RawImputation/ -type f -name "*Chr$1_*.gen" |sort -V | xargs -r awk '{ $1='$1'; print }' | cat > ./Impute/"$BaseName"/ConcatImputation/"$BaseName"_Chr$1.gen 
					
			
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


			# Exports the BaseName variable so the child process can see it
				export BaseName
				export -f Concat
			
			# GNU-Parallel Command: Takes all the chromosomal chunks and concatenates them in parallel
				parallel -j8 --eta Concat {} ::: {1..23}
	
	else

		echo
		echo Running Serial Concatenation
		echo 
		
		# Run the Concatenation in Serial
			for chr in {1..26}; do

				echo
				echo 
				echo Concatenating Chromosome ${chr}
				echo ----------------------------------------------

			#Searches for chromosome gen file/s; if exists then concatenates them; else skips the chromosome concatenation
				if ls ./Impute/${BaseName}/RawImputation/*Chr${chr}_*gen 1> /dev/null 2>&1; then 
					find ./Impute/${BaseName}/RawImputation/ -type f -name "*Chr${chr}_*.gen" |sort -V | xargs -r awk '{ $1='${chr}'; print }' | cat > ./Impute/${BaseName}/ConcatImputation/"$BaseName"_Chr${chr}.gen
					
				else echo "Files for Chromosome ${chr} does not exist -- Skipping"
				
				fi

			done
	fi
	

else 

	echo
	echo
	echo ------ Skipping Concatenation of Chromosomal .GEN Files ------
	echo
	echo

fi


# Create a SNP Report for the concatenated chromosomal GEN file (Includes INFO score)
#-----------------------------------------------------------------------------------

# Serial Version of Running QCTools to get a SNP Report
if [ "${AnalyzeINFO}" == "T" ]; then

	echo
	echo Analyzing Chromosomal Imputation Results -- Getting INFO Metrics
	echo ----------------------------------------------
	echo
	
	# Parallel Version of Running QCTools to get a SNP Report
	if [ "${AnalyzeINFOParallel}" == "T" ]; then
		
		# Load GNU-Parallel and execute the parallel command to analyze variants in parallel
			
		echo	
		echo Running Parallel Variant Analysis with GNU-Parallel
		echo Up to 5 chromosomes will be analyzed at a time
		echo To change this setting modify the -j option in 3b_ConcatenateSegments.sh
		echo   You may have to configure GNU-Parallel manually to run on your system
		echo   See Config.conf for instructions on how to do this
		echo ---------------------------------------------------------
		echo

		# Function that executes SNPTEST to Analyze Variants in Concatenated .GEN File
			function GetInfo() {
	
				# Conditional statement to see if there is a Concatenated Chromosomal GEN file from which to make a SNP Report
					if ls ./Impute/"$BaseName"/ConcatImputation/*Chr$1.gen 1> /dev/null 2>&1; then 
	
						#Perform SNPTEST SNP Analysis
							printf "\n\nPerforming SNP Analysis on Chromosome $1\n------------------------------\n";
							$SNPTEST_Exec -summary_stats_only -assume_chromosome $1 -data ./Impute/${BaseName}/ConcatImputation/${BaseName}_Chr$1.gen ./Impute/${BaseName}/${BaseName}.sample -chunk 10000 -o ./Impute/${BaseName}/ConcatImputation/${BaseName}_Chr$1.snpstat &> ./Impute/${BaseName}/ConcatImputation/${BaseName}_Chr$1.snpstatOut
	
	
						# Filter SNP Report based on INFO score, Report a List of SNP's that meet the INFO Requirements, and Display Some Filtering Statistics
		
							echo
							echo Filtering SNP-Report to return SNPs that meet the specified INFO Score cutoff of greater than: ${FilterINFO}
							echo ----------------------------------------------
								#awk '/^[^#]/ { print $2,$9}' ./Impute/$BaseName/ConcatImputation/${BaseName}_Chr$1.snpstat | awk '{ if($2 >= $'$FilterINFO') {print $1}}' > ./Impute/$BaseName/ConcatImputation/INFOFiltered_Chr$1.list
								#awk '{ if($9 >= $'$FilterINFO') { print $2}}' ./Impute/$BaseName/ConcatImputation/${BaseName}_Chr$1.snpstat > ./Impute/$BaseName/ConcatImputation/INFOFiltered_Chr$1.list
								#awk 'FNR > 11 { if($9 >= '$FilterINFO') { print $2,$9 }}' ./Impute/$BaseName/ConcatImputation/${BaseName}_Chr$1.snpstat > ./Impute/$BaseName/ConcatImputation/INFOFiltered_Chr$1.list
								awk '{ if (!/#|info/ && $9 >= '$FilterINFO') { print $2 }}' ./Impute/$BaseName/ConcatImputation/${BaseName}_Chr$1.snpstat > ./Impute/$BaseName/ConcatImputation/INFOFiltered_Chr$1.list

							
							
							#awk '$my_awk' > ./Impute/$BaseName/ConcatImputation/INFOFiltered_Chr$1.list
								
							echo
							echo Looking up the total number of imputed variants and how many are left after filtering...
							echo ----------------------------------------------
			
							TOTAL_SNPS="$(wc -l < ./Impute/${BaseName}/ConcatImputation/${BaseName}_Chr$1.snpstat)"
							FILTERED_SNPS="$(wc -l < ./Impute/${BaseName}/ConcatImputation/INFOFiltered_Chr$1.list)"
			
							echo
							echo Total Number of Imputed Variants in Chromosome $1: $TOTAL_SNPS
							echo Filtered Number of Imputed Variants in Chromosome $1: $FILTERED_SNPS
							echo	
			
			
					# Otherwise if there are no files to create a SNP Report for then say so	
					else
		
						printf " \n\nNo Chromosomal GEN File Present for Chromosome $1 with which to create a SNP Report -- Skipping \n"
		
		
					fi
			}
		# ----- Configure GNU-Parallel (GNU-Parallel Tag) --------
				
		# On our system gnu-parallel is loaded via a module load command specified in Config.conf under the variable $LOAD_PARALLEL
		# As an alternative you could simply configure GNU-Parallel manually so that calling "parallel" runs GNU-Parallel
		# by adjusting the following lines so that GNU-Parallel runs on your system
		
		# Load/Inititalize GNU-Parallel
			$LOAD_PARALLEL 
			
		# -------- Configure GNU-Parallel --------	
		
		
		# Exports the BaseName and FilterINFO variables as well as the exec path for SNPTEST so the child process (GNU-Parallel) can see it
			export BaseName
			export FilterINFO
			export SNPTEST_Exec
			export -f GetInfo
			
		# GNU-Parallel Command: Takes all the chromosomal .gen files and analyzes them in parallel	
			parallel -j5 --eta GetInfo {} "&>" ./Impute/${BaseName}/ConcatImputation/${BaseName}_Chr{}.snpstatOut ::: {1..23}

	# If don't ask for parallel variant analysis then analyze in serial to get a SNP Report
	else 
		echo
		echo Running Serial Analysis of Variants
		echo ----------------------------------------------
		echo
		
		for chr in {1..26}; do			
		
			# Conditional statement to see if there is a Concatenated Chromosomal GEN file from which to make a SNP Report
			if ls ./Impute/${BaseName}/ConcatImputation/*Chr${chr}.gen 1> /dev/null 2>&1; then

			#Perform SNPTEST SNP Analysis
				echo
				echo Reporting SNP Statistics for Concatenated Chromosome ${chr} GEN File - Includes INFO Scores
				echo ----------------------------------------------
				echo
					$SNPTEST_Exec -summary_stats_only -assume_chromosome ${chr} -data ./Impute/${BaseName}/ConcatImputation/${BaseName}_Chr${chr}.gen ./Impute/${BaseName}/${BaseName}.sample -chunk 10000 -o ./Impute/${BaseName}/ConcatImputation/${BaseName}_Chr${chr}.snpstat &> ./Impute/${BaseName}/ConcatImputation/${BaseName}_Chr${chr}.snpstatOut
	
			
			# Filter SNP Report based on INFO score, Report a List of SNP's that meet the INFO Requirements, and Display Some Filtering Statistics
			
				echo
				echo Filtering SNP-Report to return SNPs that meet the specified INFO Score cutoff of greater than: ${FilterINFO}
				echo ----------------------------------------------
					#awk '{ if($9 >= $'$FilterINFO') { print $2}}' ./Impute/${BaseName}/ConcatImputation/${BaseName}_Chr${chr}.snpstat > ./Impute/${BaseName}/ConcatImputation/INFOFiltered_Chr${chr}.list
					#awk ' { print $2,$9}' ./Impute/$BaseName/ConcatImputation/${BaseName}_Chr${chr}.snpstat | awk '{ if($2 >= $'$FilterINFO') {print $1}}' > ./Impute/$BaseName/ConcatImputation/INFOFiltered_Chr${chr}.list
					#awk 'FNR > 11 { if($9 >=$FilterINFO) { print $2,$9}}' ./Impute/$BaseName/ConcatImputation/${BaseName}_Chr${chr}.snpstat > ./Impute/$BaseName/ConcatImputation/INFOFiltered_Chr${chr}.list
					awk '{ if (!/#|info/ && $9 >= $FilterINFO) { print $2 }}' ./Impute/$BaseName/ConcatImputation/${BaseName}_Chr${chr}.snpstat > ./Impute/$BaseName/ConcatImputation/INFOFiltered_Chr${chr}.list

				
				
				echo
				echo Looking up the total number of imputed variants and how many are left after filtering...
				echo ----------------------------------------------
			
				TOTAL_SNPS="$(wc -l < ./Impute/${BaseName}/ConcatImputation/${BaseName}_Chr${chr}.snpstat)"
				FILTERED_SNPS="$(wc -l < ./Impute/${BaseName}/ConcatImputation/INFOFiltered_Chr${chr}.list)"
			
				
				printf "\n\nTotal Number of Imputed Variants in Chromosome ${chr}: $TOTAL_SNPS\n\n" >> ./Impute/${BaseName}/ConcatImputation/${BaseName}_Chr${chr}.snpstatOut
				printf "\n\nFiltered Number of Imputed Variants in Chromosome ${chr}: $FILTERED_SNPS\n\n" >> ./Impute/${BaseName}/ConcatImputation/${BaseName}_Chr${chr}.snpstatOut
							

			
			# Otherwise if there are no files to create a SNP Report for then say so	
			else
		
				echo "No Chromosomal GEN File Present for Chromosome ${chr} with which to create a SNP Report -- Skipping"
	
			fi
		done

	fi
	
else
	echo
	echo ------ Skipping the Analysis of Variant Files ------
	echo
	echo
	
fi



# Use Plink to Convert Concatenated GEN file to VCF

	
	
if [ "${Convert2VCF}" == "T" ]; then


	
	
	if [ "${ConvertParallel}" == "T" ]; then
		# This is a GNU Parallel command that first searches for *Chr[#]_* to see if the file exists
			# GNU Parallel (https://www.gnu.org/software/parallel/) must be installed on the system to use this option
			# If GNU-Parallel is installed it will find all the .gen chunks for the chromosome and convert them to a VCF
			# If the chromosomal file doesn't exist then it will report that it doesn't exist
			# All concatenations are performed in parallel based on the number of CPU cores detected (since concatenation is a light resource command)
		
		# Load GNU-Parallel and execute the parallel command to convert in parallel
			
			echo Running Parallel Conversion with GNU-Parallel
			echo Up to 10 chromosomes will be converted at a time
			echo To change this setting modify the -j option in 3b_ConcatenateSegments.sh
			echo
			echo You may have to configure GNU-Parallel manually to run on your system
			echo 	See Config.conf for instructions on how to do this
			echo ---------------------------------------------------------
			echo
			
			# -------- Configure GNU-Parallel --------
				
			# On our system gnu-parallel is loaded via a module load command specified in Config.conf under the variable $LOAD_PARALLEL
			# As an alternative you could simply configure GNU-Parallel manually so that calling "parallel" runs GNU-Parallel
			# by adjusting the following lines so that GNU-Parallel runs on your system
			
			# Load/Inititalize GNU-Parallel and then run the GNU-Parallel command
				$LOAD_PARALLEL 
				
			# -------- Configure GNU-Parallel --------


			function ConvertSegments() {
	
				# Conditional statement to see if there is a Concatenated Chromosomal GEN file from which to make a SNP Report
					if ls $1 1> /dev/null 2>&1; then 
	

			# Then use for to convert

					# Get chromosome number from the name of the file
						FetchChr=$(echo $1 | egrep -o --ignore-case "chr[[:digit:]]{1,2}[^[:digit:]]{1}" | egrep -o --ignore-case "[[:digit:]]{1,2}")		
					
					#If there is a concatenated GEN file to convert then convert it
						echo Converting the following GEN file using Plink:
						echo ----------------------------------------------
						echo $1 being Converted 
						echo ----------------------------------------------
						echo
						echo

					# Runs Plink to convert the concatenated GEN to a VCF 4.3
						time ${Plink2_Exec} \
						--gen $1 \
						--sample ./Impute/${BaseName}/${BaseName}.sample \
						--export vcf vcf-dosage=GP \
						--extract ./Impute/${BaseName}/ConcatImputation/INFOFiltered_Chr$FetchChr.list\
						--memory 2000 require \
						--out $1
	
		
					echo
					echo
					echo
	

					# Otherwise if there are no files to create a SNP Report for then say so	
					else
		
						printf " \n\nNo Chromosomal GEN Files Present for $1 with which to convert -- Skipping \n"
		
		
					fi

	
			}

		
		# Exports the BaseName and function so the child process (GNU-Parallel) can see it
			export BaseName
			export Plink2_Exec
			export -f ConvertSegments


			# GNU-Parallel Command: Takes all the chromosomal segments and converts them in parallel
				parallel -j5 --eta ConvertSegments {} ::: ./Impute/${BaseName}/ConcatImputation/*.gen

	else

		echo
		echo Running Serial Conversion
		echo 
		
		# Run the Conversion in Serial
			# Find all gens in the directory, and return array of gens with absolute path.
				allGens=$"`find ./Impute/${BaseName}/RawImputation -name '*gen' -type f -maxdepth 1 |sort -V `"
				
				echo $allGens
				echo
				echo
				
			# Then use for to convert
				for gen in ${allGens[@]}
					do
					
					# Get chromosome number from the name of the file
						FetchChr=$(echo $gen | egrep -o --ignore-case "chr[[:digit:]]{1,2}[^[:digit:]]{1}" | egrep -o --ignore-case "[[:digit:]]{1,2}")
									
					#If there is a concatenated GEN file to convert then convert it
						echo Converting the following GEN file using Plink:
						echo ----------------------------------------------
						echo "$gen" being Converted -- Found on Chr $FetchChr
						echo ----------------------------------------------
						echo
						echo

					# Runs Plink to convert the concatenated GEN to a VCF 4.3
						time ${Plink2_Exec} \
						--gen ${gen} \
						--sample ./Impute/${BaseName}/${BaseName}.sample \
						--oxford-single-chr $FetchChr \
						--extract ./Impute/${BaseName}/ConcatImputation/INFOFiltered_Chr$FetchChr.list \
						--export vcf vcf-dosage=GP \
						--memory 2000 require \
						--out $gen
	
		
					echo
					echo
					echo
					
				
				done




	fi
	
else 

	echo
	echo
	echo ------ Skipping Conversion of Chromosomal .GEN Files ------
	echo
	echo

fi

	

# Use BCFTools to Merge the VCF Files Created by Plink
	
if [ "${MergeVCF}" == "T" ]; then


	# Conditional statement to find if there are files to concatenate for the currently iterated chromosome
		if ls ./Impute/${BaseName}/ConcatImputation/*.vcf 1> /dev/null 2>&1; then

	# If there are .vcf files to concatenate then list them (in order) on the screen
		echo
		echo Concatenating the following VCF files using BCFTools:
		echo ----------------------------------------------
		ls -1av ./Impute/${BaseName}/ConcatImputation/*.vcf
		echo ----------------------------------------------
		echo ...to ./Impute/${BaseName}/ConcatImputation/1DONE_${BaseName}_Merged.vcf -- denoted to put it first alphabetically
		echo
	
	# Set List entries as a variable
		VCF2Merge="$(find ./Impute/${BaseName}/ConcatImputation/ -maxdepth 1 -type f -name "*.vcf" |sort -V)"

	# Use BCFTools to Merge the VCF Files Listed in the variable
		time ${bcftools} concat --threads ${ConcatThreads} ${VCF2Merge} --output-type z --output ./Impute/${BaseName}/ConcatImputation/1DONE_${BaseName}_Merged.vcf.gz

	# Change Permission so the cat script can access it
		chmod -f 700 ./Impute/${BaseName}/ConcatImputation/1DONE_${BaseName}_Merged.vcf.gz || true
		

# Otherwise if there are no files to concatenate for the currently iterated chromosome then say so	
		else
			echo
			echo "No VCF Files for BCFTools to Concatenate"
			echo
	
		fi
else
	echo
	echo ------ Skipping the Merging of Chromosomal VCFs to a Single VCF ------
	echo		
fi


# Remove Temporary Files to Save Space
	
if [ "${KeepTemp}" == "F" ]; then	

	echo
	echo Removing Temporary Files to Save Space
	echo ---------------------------------------
	echo

	rm -f *.gen
	rm -f *.gen.vcf
	rm -f *.log

else

	echo
	echo Keeping Temporary Files
	echo ---------------------------------------
	echo 



fi
	
printf "\nPhew! Done! \n\n"






