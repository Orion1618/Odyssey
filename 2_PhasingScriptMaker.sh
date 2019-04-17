#!/bin/bash

## Overview:
## ==================

## This script will:
	# 1) Create the Bash scripts used to execute Phasing jobs (autosomal and the X chromosome) on a system
	# 2) Submit the Bash scripts to the HPC queue at the user's request
	

# Splash Screen
# --------------
	source .TitleSplash.txt
	printf "$Logo"

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


# Set Working Directory
# ------------------------
	printf "\nChanging to Working Directory\n"
	echo ----------------------------------------------
	echo ${WorkingDir}
		cd ${WorkingDir}
	
	# Creating Imputation Project Folders within Phase Directory
	# -----------------------------------------------------------
	printf "\nCreating Imputation Project Folder within Phase Directory\n\n"
	
		mkdir -p ./2_Phase/${BaseName}
			
			# Perform Lustre Stripping?
			if [ "${LustreStrip,,}" == "t" ]; then
				lfs setstripe -c 2 ./2_Phase/${BaseName}
			fi
		
		mkdir -p ./2_Phase/${BaseName}/Scripts2Shapeit
	

## --------------------------------------------------------------------------------------
## ===========================================
##         Download Default Ref Data
## ===========================================
## --------------------------------------------------------------------------------------

if [ "${DownloadDefaultRefPanel,,}" == "t" ]; then

	printf "\nDownloading Default Ref Panel \nDetermining Phasing and Imputation Program Requested From Settings.conf\n "
	echo "---------------------------------------------"
	echo

	# Make sure troublesome combos are not coded -- i.e. requesting several phasing or several imputations
	if ([ "${UseShapeit,,}" == "t" ] && [ "${UseEagle,,}" == "t" ]) || ([ "${UseShapeit,,}" == "f" ] && [ "${UseEagle,,}" == "f" ]) || ([ "${UseImpute,,}" == "t" ] && [ "${UseMinimac,,}" == "t" ]) || ([ "${UseImpute,,}" == "f" ] && [ "${UseMinimac,,}" == "f" ]) ; then
	
		printf "\nCombo Not Possible. Specify a single Phasing and Imputation Program to Use -- Exiting\n\n "
		exit
	
	# Valid Phase/Impute Combinations
	elif ([ "${UseShapeit,,}" == "t" ] && [ "${UseImpute,,}" == "t" ]) || ([ "${UseShapeit,,}" == "t" ] && [ "${UseMinimac,,}" == "t" ]) || ([ "${UseEagle,,}" == "t" ] && [ "${UseMinimac,,}" == "t" ]) || ([ "${UseEagle,,}" == "t" ] && [ "${UseImpute,,}" == "t" ]) ; then
	
		printf "Good Phase/Impute Combination Proceeding...\n\n"
	
		# ================================Use Shapeit================================
		if [ "${UseShapeit,,}" == "t" ]; then
			
			# ====================================== Use Shapeit-Impute ======================================
			if [ "${UseImpute,,}" == "t" ]; then
				printf "Using a Shapeit-Impute Combo Downloading Necessary Default Ref Files"
				# Retrieves the (default) Reference Genome from the IMPUTE Website
				# ----------------------------------------------------------------------------------
				# Collects the 1000Genome Reference Build from the Impute Site 
					#(https://mathgen.stats.ox.ac.uk/impute/1000GP_Phase3.html)
					# Reference Build Specs: 1,000 Genomes haplotypes -- Phase 3 integrated variant set release in NCBI build 37 (hg19) coordinates 
					# Ref Build Updated Aug 3 2015
	
					printf "\n\nRetrieving 1K Genome Phase 3 Ref Panel and hg19 Genetic Map from Impute2 Website \n-------------------------------------------------------------------------------\n\n\n"
						wget --directory-prefix=${WorkingDir}Reference/ https://mathgen.stats.ox.ac.uk/impute/1000GP_Phase3.tgz
						wget --directory-prefix=${WorkingDir}Reference/ https://mathgen.stats.ox.ac.uk/impute/1000GP_Phase3_chrX.tgz
				
				#Unzip the packaged ref panel
					printf "\n\nUnpackaging Ref Panel \n--------------------------\n\n"
						tar -xzf ${WorkingDir}Reference/1000GP_Phase3.tgz -C ${WorkingDir}Reference/
						tar -xzf ${WorkingDir}Reference/1000GP_Phase3_chrX.tgz -C ${WorkingDir}Reference/
				
				# Since untar makes an additional directory, move all the files from the 1000GP_Phase3 folder and move it into the Ref Directory
					printf "\n\nCleaning Up \n-------------------\n\n"
						mv ${WorkingDir}Reference/1000GP_Phase3/* ${WorkingDir}Reference/
										
				# Delete the now empty directory and the tgz zipped Ref panel
					rmdir ${WorkingDir}Reference/1000GP_Phase3/
					rm ${WorkingDir}Reference/*.tgz
		
		
		
			# ====================================== Use Shapeit-Minimac ====================================
			elif [ "${UseMinimac,,}" == "t" ]; then
				printf "Using a Shapeit-Minimac Combo Downloading Necessary Default Ref Files"
				
				# Retrieves the (default) Reference Genome from the IMPUTE Website
				# ----------------------------------------------------------------------------------
				# Collects the 1000Genome Reference Build from the Impute Site 
					#(https://mathgen.stats.ox.ac.uk/impute/1000GP_Phase3.html)
					# Reference Build Specs: 1,000 Genomes haplotypes -- Phase 3 integrated variant set release in NCBI build 37 (hg19) coordinates 
					# Ref Build Updated Aug 3 2015
	
					printf "\n\nRetrieving 1K Genome Phase 3 Ref Panel and hg19 Genetic Map from Impute2 Website \n-------------------------------------------------------------------------------\n\n\n"
						wget --directory-prefix=${WorkingDir}Reference/ https://mathgen.stats.ox.ac.uk/impute/1000GP_Phase3.tgz
						wget --directory-prefix=${WorkingDir}Reference/ https://mathgen.stats.ox.ac.uk/impute/1000GP_Phase3_chrX.tgz
				
				#Unzip the packaged ref panel
					printf "\n\nUnpackaging Ref Panel \n--------------------------\n\n"
						tar -xzf ${WorkingDir}Reference/1000GP_Phase3.tgz -C ${WorkingDir}Reference/
						tar -xzf ${WorkingDir}Reference/1000GP_Phase3_chrX.tgz -C ${WorkingDir}Reference/
				
				# Since untar makes an additional directory, move all the files from the 1000GP_Phase3 folder and move it into the Ref Directory
					printf "\n\nCleaning Up \n-------------------\n\n"
						mv ${WorkingDir}Reference/1000GP_Phase3/* ${WorkingDir}Reference/
										
				# Delete the now empty directory and the tgz zipped Ref panel
					rmdir ${WorkingDir}Reference/1000GP_Phase3/
					rm ${WorkingDir}Reference/*.tgz
				
				# Remove the .hap.gz and .legend.gz files since we are using the Minimac mvcf Ref Panel
					rm ${WorkingDir}Reference/*hap.gz
					rm ${WorkingDir}Reference/*legend.gz
					
				# Download the Minimac4 mvcf
					wget --directory-prefix=${WorkingDir}Reference/ ftp://share.sph.umich.edu/minimac3/G1K_P3_M3VCF_FILES_WITH_ESTIMATES.tar.gz
					
				#Unpack
					tar -xzf ${WorkingDir}Reference/G1K_P3_M3VCF_FILES_WITH_ESTIMATES.tar.gz -C ${WorkingDir}Reference/
			
				# Remove original .tar.gz Minimac Ref Panel
					rm ${WorkingDir}Reference/*tar.gz
			
			else
				printf "Invalid Phasing/Imputation Program Combo -- Exiting \n\n"
				exit
			fi
			
		# ================================Use Eagle================================
		elif [ "${UseEagle,,}" == "t" ]; then
			
			# ====================================== Use Eagle-Impute ======================================
			if [ "${UseImpute,,}" == "t" ]; then
				printf "Using a Eagle-Impute Combo Downloading Necessary Default Ref Files"
				# Retrieves the (default) Reference Genome from the IMPUTE Website
				# ----------------------------------------------------------------------------------
				# Collects the 1000Genome Reference Build from the Impute Site 
					#(https://mathgen.stats.ox.ac.uk/impute/1000GP_Phase3.html)
					# Reference Build Specs: 1,000 Genomes haplotypes -- Phase 3 integrated variant set release in NCBI build 37 (hg19) coordinates 
					# Ref Build Updated Aug 3 2015
	
					printf "\n\nRetrieving 1K Genome Phase 3 Ref Panel and hg19 Genetic Map from Impute2 Website \n-------------------------------------------------------------------------------\n\n\n"
						wget --directory-prefix=${WorkingDir}Reference/ https://mathgen.stats.ox.ac.uk/impute/1000GP_Phase3.tgz
						wget --directory-prefix=${WorkingDir}Reference/ https://mathgen.stats.ox.ac.uk/impute/1000GP_Phase3_chrX.tgz
						wget --directory-prefix=${WorkingDir}Reference/ https://data.broadinstitute.org/alkesgroup/Eagle/downloads/tables/genetic_map_hg19_withX.txt.gz	
						
				#Unzip the packaged ref panel
					printf "\n\nUnpackaging Ref Panel \n--------------------------\n\n"
						tar -xzf ${WorkingDir}Reference/1000GP_Phase3.tgz -C ${WorkingDir}Reference/
						tar -xzf ${WorkingDir}Reference/1000GP_Phase3_chrX.tgz -C ${WorkingDir}Reference/
						${gzip_Exec} -dc < ${WorkingDir}Reference/genetic_map_hg19_withX.txt.gz > ${WorkingDir}Reference/genetic_map_hg19_withX.txt
				
				# Since untar makes an additional directory, move all the files from the 1000GP_Phase3 folder and move it into the Ref Directory
					printf "\n\nCleaning Up \n-------------------\n\n"
						mv ${WorkingDir}Reference/1000GP_Phase3/* ${WorkingDir}Reference/
										
				# Delete the now empty directory and the tgz zipped Ref panel
					rmdir ${WorkingDir}Reference/1000GP_Phase3/
					rm ${WorkingDir}Reference/*.tgz
					rm ${WorkingDir}Reference/*txt.gz
					
	
	
			# ====================================== Use Eagle-Minimac ======================================
			elif [ "${UseMinimac,,}" == "t" ]; then
				printf "Using a Eagle-Minimac Combo Downloading Necessary Default Ref Files"
				
				# Download the Minimac4 mvcf
					wget --directory-prefix=${WorkingDir}Reference/ ftp://share.sph.umich.edu/minimac3/G1K_P3_M3VCF_FILES_WITH_ESTIMATES.tar.gz
					wget --directory-prefix=${WorkingDir}Reference/ https://data.broadinstitute.org/alkesgroup/Eagle/downloads/tables/genetic_map_hg19_withX.txt.gz	
						
					
				#Unpack
					tar -xzf ${WorkingDir}Reference/G1K_P3_M3VCF_FILES_WITH_ESTIMATES.tar.gz -C ${WorkingDir}Reference/
					${gzip_Exec} -dc < ${WorkingDir}Reference/genetic_map_hg19_withX.txt.gz > ${WorkingDir}Reference/genetic_map_hg19_withX.txt
			
				# Remove original .tar.gz Minimac Ref Panel
					rm ${WorkingDir}Reference/*tar.gz
					rm ${WorkingDir}Reference/*txt.gz
	
			else
				printf "Invalid Phasing/Imputation Program Combo -- Exiting \n\n"
				exit
			fi
		fi
	
	else
		printf "Invalid Phasing/Imputation Program Combo -- Exiting \n\n"
		exit
	fi
	
elif [ "${DownloadDefaultRefPanel,,}" == "f" ]; then	

	printf "\nWill Not Download Default Phasing and Imputation Ref Panels\nIn This Case Make Sure the Proper Genetic Map File/s and Ref Panel are Located in the ./Reference Directory \n\nRefer to the Reference Dataset Section in Settings.conf for Supported Reference Naming Schemes\n"
	echo "---------------------------------------------"
	echo

else
	printf "Command Not Recognized Please Specify either T or F -- Exiting n\n"
	exit
fi



## --------------------------------------------------------------------------------------
## ===========================================
##          Phasing Using Shapeit2
## ===========================================
## --------------------------------------------------------------------------------------

if [ "${UseShapeit,,}" == "t" ]; then

	printf "\n\nUsing Shapeit for Phasing\n=======================\n\n"

	
	## -------------------------------------------
	## Phasing Script Creation for Autosomes (Chr1-22)
	## -------------------------------------------
	if [ "${PhaseAutosomes,,}" == "t" ]; then
	
		#Set Chromosome Start and End Parameters
		for chr in `eval echo {$PhaseChrStart..$PhaseChrEnd}`; do
	
	
		#Search the reference directory for the chromosome specific reference map, legend, and hap files and create their respective variables on the fly
	
			printf "\n\nProcessing Chromosome ${chr} Script \n"
			echo -----------------------------------
			
		
			echo "Pre-Check: Looking in ./Reference For Reference Files "
			echo "Found the Following Shapeit References for Chromosome ${chr}: "
		
			GeneticMap="$(ls ./Reference/ | egrep --ignore-case ".*map.*chr${chr}[^[:digit:]]{1}.*|.*chr${chr}[^[:digit:]]{1}.*map.*")"
				printf "   Genetic Map File: $GeneticMap \n"
			HapFile="$(ls ./Reference/ | egrep --ignore-case ".*chr${chr}[^[:digit:]]{1}.*hap\.gz")"
				printf "   Haplotpe File: $HapFile \n"
			LegendFile="$(ls ./Reference/ | egrep --ignore-case ".*chr${chr}[^[:digit:]]{1}.*legend\.gz")"
				printf "   Legend File: $LegendFile \n \n"	


echo "#!/bin/bash


cd ${WorkingDir}

# Phase Command to Phase Chromosomes
	# Manual Command to Run:
	# qsub -l nodes=1:ppn=${PhaseThreads},vmem=${Phase_Memory}gb,walltime=${Phase_Walltime} -M ${Email} -m ae -j oe -o ${WorkingDir}2_Phase/${BaseName}/Scripts2Shapeit/${BaseName}_Chr${chr}_P.out -N PChr${chr}_${BaseName} ./2_Phase/${BaseName}/Scripts2Shapeit/${BaseName}_Chr${chr}_P.sh
			

${Shapeit2_Exec} \
--thread ${PhaseThreads} \
--input-bed ./1_Target/${BaseName}/Ody2_${BaseName}_PhaseReady.chr${chr} \
--input-map ./Reference/${GeneticMap} \
-O ./2_Phase/${BaseName}/Ody3_${BaseName}_Chr${chr}_Phased.haps.gz ./2_Phase/${BaseName}/Ody3_${BaseName}_Chr${chr}_Phased.sample \
--output-log ./2_Phase/${BaseName}/Ody3_${BaseName}_Chr${chr}_Phased.log" > ./2_Phase/${BaseName}/Scripts2Shapeit/${BaseName}_Chr${chr}_P.sh


			# Toggle that will turn script submission on/off
			# -----------------------------------------------
			
			if [ "${ExecutePhasingScripts,,}" == "t" ]; then
			
				if [ "${HPS_Submit,,}" == "t" ]; then
			
					echo
					echo Submitting Phasing script to HPC Queue
					echo
						qsub -l nodes=1:ppn=${PhaseThreads},vmem=${Phase_Memory}gb,walltime=${Phase_Walltime} -M ${Email} -m ae -j oe -o ${WorkingDir}2_Phase/${BaseName}/Scripts2Shapeit/${BaseName}_Chr${chr}_P.out -N PChr${chr}_${BaseName} ./2_Phase/${BaseName}/Scripts2Shapeit/${BaseName}_Chr${chr}_P.sh
						sleep 0.2
				else
					echo
					echo Submitting Phasing script to Desktop Queue
					echo
						bash ./2_Phase/${BaseName}/Scripts2Shapeit/${BaseName}_Chr${chr}_P.sh > ${WorkingDir}2_Phase/${BaseName}/Scripts2Shapeit/${BaseName}_Chr${chr}_P.out 2>&1 &
			
				fi
			fi
	
		done
	fi



	## ---------------------------------------
	## Extra Step to Phase the X Chromosome
	## ---------------------------------------
	
	if [ "${PhaseX,,}" == "t" ]; then
	
		## -------------------------------------------
		## Phasing Script Creation for HPC (Chr23/X)
		## -------------------------------------------
		
			printf "\n\nProcessing X Chromosome Script \n"
			echo -----------------------------------
			
		
		# Search the reference directory for the X chromosome specific reference map, legend, and hap files and create their respective variables on the fly
			
			echo "Pre-Check: Looking in ./Reference For Reference Files "
			echo "Found the Following Shapeit References for Chromosome X: "
		
			XGeneticMap="$(ls ./Reference/ | egrep --ignore-case ".*map.*${XChromIdentifier}.*|.*${XChromIdentifier}.*map.*")"
				printf "   Genetic Map: $XGeneticMap \n"
			XHapFile="$(ls ./Reference/ | egrep --ignore-case ".*${XChromIdentifier}.*hap\.gz")"
				printf "   Haplotpe File: $XHapFile \n"
			XLegendFile="$(ls ./Reference/ | egrep --ignore-case ".*${XChromIdentifier}.*legend\.gz")"
				printf "   Legend File: $XLegendFile \n \n"
	
echo "#!/bin/bash

cd ${WorkingDir}

# Phase Command to Phase X Chromosome
	# Manual Command to Run:
	# qsub -l nodes=1:ppn=${PhaseThreads},vmem=${Phase_Memory}gb,walltime=${Phase_Walltime} -M ${Email} -m ae -j oe -o ${WorkingDir}2_Phase/${BaseName}/Scripts2Shapeit/${BaseName}_Chr23_P.out -N PChr23_${BaseName} ./2_Phase/${BaseName}/Scripts2Shapeit/${BaseName}_Chr23_P.sh



${Shapeit2_Exec} \
--thread ${PhaseThreads} \
--chrX \
--input-bed ./1_Target/${BaseName}/Ody2_${BaseName}_PhaseReady.chr23 \
--input-map ./Reference/${XGeneticMap} \
--output-max ./2_Phase/${BaseName}/Ody3_${BaseName}_Chr23_Phased.haps.gz \
--output-log ./2_Phase/${BaseName}/Ody3_${BaseName}_Chr23_Phased.log" > ./2_Phase/${BaseName}/Scripts2Shapeit/${BaseName}_Chr23_P.sh
	
	
		# Toggle that will turn script submission on/off
		# -----------------------------------------------
		
			if [ "${ExecutePhasingScripts,,}" == "t" ]; then
		
				if [ "${HPS_Submit,,}" == "t" ]; then
		
					echo
					echo Submitting Phasing script to HPC Queue
					echo
						qsub -l nodes=1:ppn=${PhaseThreads},vmem=${Phase_Memory}gb,walltime=${Phase_Walltime} -M ${Email} -m ae -j oe -o ${WorkingDir}2_Phase/${BaseName}/Scripts2Shapeit/${BaseName}_Chr23_P.out -N PChr23_${BaseName} ./2_Phase/${BaseName}/Scripts2Shapeit/${BaseName}_Chr23_P.sh
						sleep 0.2
				else
					echo
					echo Submitting Phasing script to Desktop Queue
					echo
						sh ./2_Phase/${BaseName}/Scripts2Shapeit/${BaseName}_Chr23_P.sh > ${WorkingDir}2_Phase/${BaseName}/Scripts2Shapeit/${BaseName}_Chr23_P.out 2>&1 &
				fi		
			fi
	fi
fi

## --------------------------------------------------------------------------------------
## ===========================================
##          Phasing Using Eagle2
## ===========================================
## --------------------------------------------------------------------------------------

if [ "${UseEagle,,}" == "t" ]; then

	printf "\n\nUsing Eagle for Phasing\n=======================\n\n"


	## -------------------------------------------
	## Phasing Script Creation for Autosomes (Chr1-22)
	## -------------------------------------------
	if [ "${PhaseAutosomes,,}" == "t" ]; then
	
		#Set Chromosome Start and End Parameters
		for chr in `eval echo {$PhaseChrStart..$PhaseChrEnd}`; do
	
	
		#Search the reference directory for the chromosome specific reference map, legend, and hap files and create their respective variables on the fly
	
			printf "\n\nProcessing Chromosome ${chr} Script \n"
			echo -----------------------------------
					
			echo "Pre-Check: Looking in ./Reference For Reference Files "
			echo "Found the Following Eagle References for Chromosome ${chr}: "
		
			GeneticMap="$(ls ./Reference/ | egrep --ignore-case ".*genetic_map.*")"
				printf "   Genetic Map File: $GeneticMap \n"

echo "#!/bin/bash


cd ${WorkingDir}

# Phase Command to Phase Chromosomes
	# Manual Command to Run:
	# qsub -l nodes=1:ppn=${PhaseThreads},vmem=${Phase_Memory}gb,walltime=${Phase_Walltime} -M ${Email} -m ae -j oe -o ${WorkingDir}2_Phase/${BaseName}/Scripts2Shapeit/${BaseName}_Chr${chr}_P.out -N PChr${chr}_${BaseName} ./2_Phase/${BaseName}/Scripts2Shapeit/${BaseName}_Chr${chr}_P.sh
			

## Execute Phasing without a ref dataset

printf '\n\n'	
echo ========================================
printf 'Phase Chr${chr} Using Eagle\n'
echo ========================================
printf '\n\n'
	
${Eagle2_Exec} --bfile ./1_Target/${BaseName}/Ody2_${BaseName}_PhaseReady.chr${chr} \
--geneticMapFile=./Reference/${GeneticMap} \
--outPrefix=./2_Phase/${BaseName}/Ody3_${BaseName}_Chr${chr}_Phased \
--chrom ${chr} \
--numThreads ${PhaseThreads}

#Unzip Phased Output

printf '\n\n'	
echo ========================================
printf 'Gzip Chr${chr}\n'
echo ========================================
printf '\n\n'

${gzip_Exec} -dc < ./2_Phase/${BaseName}/Ody3_${BaseName}_Chr${chr}_Phased.haps.gz > ./2_Phase/${BaseName}/Ody3_${BaseName}_Chr${chr}_Phased.haps" > ./2_Phase/${BaseName}/Scripts2Shapeit/${BaseName}_Chr${chr}_P.sh


			# Toggle that will turn script submission on/off
			# -----------------------------------------------
			
			if [ "${ExecutePhasingScripts,,}" == "t" ]; then
			
				if [ "${HPS_Submit,,}" == "t" ]; then
			
					
					echo Submitting Phasing script to HPC Queue
					echo
						qsub -l nodes=1:ppn=${PhaseThreads},vmem=${Phase_Memory}gb,walltime=${Phase_Walltime} -M ${Email} -m ae -j oe -o ${WorkingDir}2_Phase/${BaseName}/Scripts2Shapeit/${BaseName}_Chr${chr}_P.out -N PChr${chr}_${BaseName} ./2_Phase/${BaseName}/Scripts2Shapeit/${BaseName}_Chr${chr}_P.sh
						sleep 0.2
				else
					
					echo Submitting Phasing script to Desktop Queue
					echo
						bash ./2_Phase/${BaseName}/Scripts2Shapeit/${BaseName}_Chr${chr}_P.sh > ${WorkingDir}2_Phase/${BaseName}/Scripts2Shapeit/${BaseName}_Chr${chr}_P.out 2>&1 &
			
				fi
			fi
	
		done
	fi


	## ---------------------------------------
	## Extra Step to Phase the X Chromosome
	## ---------------------------------------
	
	if [ "${PhaseX,,}" == "t" ]; then
	
		## -------------------------------------------
		## Phasing Script Creation for HPC (Chr23/X)
		## -------------------------------------------
		
			printf "\n\nProcessing X Chromosome Script \n"
			echo -----------------------------------
			
		
		#Search the reference directory for the chromosome specific reference map, legend, and hap files and create their respective variables on the fly
		
			echo "Pre-Check: Looking in ./Reference For Reference Files "
			echo "Found the Following Eagle References for Chromosome X: "
		
			GeneticMap="$(ls ./Reference/ | egrep --ignore-case ".*genetic_map.*")"
				printf "   Genetic Map File: $GeneticMap \n"
	
echo "#!/bin/bash

cd ${WorkingDir}

# Phase Command to Phase X Chromosome
	# Manual Command to Run:
	# qsub -l nodes=1:ppn=${PhaseThreads},vmem=${Phase_Memory}gb,walltime=${Phase_Walltime} -M ${Email} -m ae -j oe -o ${WorkingDir}2_Phase/${BaseName}/Scripts2Shapeit/${BaseName}_Chr23_P.out -N PChr23_${BaseName} ./2_Phase/${BaseName}/Scripts2Shapeit/${BaseName}_Chr23_P.sh
			

## Execute Phasing without a ref dataset
	
${Eagle2_Exec} --bfile ./1_Target/${BaseName}/Ody2_${BaseName}_PhaseReady.chr23 \
--geneticMapFile=./Reference/${GeneticMap} \
--outPrefix=./2_Phase/${BaseName}/Ody3_${BaseName}_Chr23_Phased \
--chrom 23 \
--numThreads ${PhaseThreads}

#Unzip Phased Output

${gzip_Exec} -dc < ./2_Phase/${BaseName}/Ody3_${BaseName}_Chr23_Phased.haps.gz > ./2_Phase/${BaseName}/Ody3_${BaseName}_Chr23_Phased.haps" > ./2_Phase/${BaseName}/Scripts2Shapeit/${BaseName}_Chr23_P.sh


		# Toggle that will turn script submission on/off
		# -----------------------------------------------
		
			if [ "${ExecutePhasingScripts,,}" == "t" ]; then
		
				if [ "${HPS_Submit,,}" == "t" ]; then
		
					
					echo Submitting Phasing script to HPC Queue
					echo
						qsub -l nodes=1:ppn=${PhaseThreads},vmem=${Phase_Memory}gb,walltime=${Phase_Walltime} -M ${Email} -m ae -j oe -o ${WorkingDir}2_Phase/${BaseName}/Scripts2Shapeit/${BaseName}_Chr23_P.out -N PChr23_${BaseName} ./2_Phase/${BaseName}/Scripts2Shapeit/${BaseName}_Chr23_P.sh
						sleep 0.2
				else
					
					echo Submitting Phasing script to Desktop Queue
					echo
						bash ./2_Phase/${BaseName}/Scripts2Shapeit/${BaseName}_Chr23_P.sh > ${WorkingDir}2_Phase/${BaseName}/Scripts2Shapeit/${BaseName}_Chr23_P.out 2>&1 &
				fi		
			fi
	fi
fi

# Termination Message
	echo
	echo ============
	echo " Phew Done!"
	echo ============
	echo
	echo
