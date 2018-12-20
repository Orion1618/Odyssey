# Odyssey 

Version: 1.0 beta


Odyssey is a suite of scripts that aids in the preparation, phasing, and imputation of genomic data. The suite also contains scripts to assist in the running of genome wide association studies (GWAS) via the program SNPTEST as well as some rudamentary data analysis of the SNPTEST output.

# General Overview
Odyssey relies primarily on the idea that the creation of imputed genomic data must go through 4 basic steps: pre-imputation QC, phasing, imputation, and post imputation cleanup and QC. Once Odyssey is setup and its dependencies are installed, users can automate these 4 steps on a High Performance System (HPS) running some form of Linux or a desktop (if you are not concerned about time requirements as phasing/imputation is normally resource intensive). Odyssey contains 6 main folders. DataPrepModule is where the user places his or her target data that needs to be remapped and/or fixed to a reference genome (to assure proper genomic positions and allele 'flippige'). Target is where the cleaned data from DataPrepModule is put following the data being cleaned. Reference is where the user places the reference data that will be used by Shapeit2 and Impute2/4. Phasing is where Shapeit scripts, logs, and phased data will be housed while Impute is where the imputed data as well as the final concatenated and INFO score filtered dosage VCF will be housed. GWASModule is a module that takes the dosage VCF file and performs a specific analysis, a Genome Wide Association Study (GWAS) on the dosage VCF. If the user wants to perform another type of analysis he or she may simply stop at the Imputation step.

Users should also make note of Config.conf which is used to configure the variables that allow Odyssey to run. Programs.conf is another configuration file that specifies the file paths to Odyssey dependencies. Specifying the program exec files in this way avoids the hassle of trying to configure #PATH.

Once the Config file is completed the user can execute the various scripts in the main Odyssey folder which cleans, phases, imputes, and performs a GWAS on the data respectively from a command prompt. Odyssey is optimized for human data. Using other organism data is possible with Odyssey, but unsupported with the current version (since testing various species' data would take a really long time).

# Odyssey Tutorial
As an added reference, an Odyssey Tutorial has been provided which contains a 100 sample HGDP dataset (provided in the Tutorial Folder) as well as a document, Odyssey Tutorial, which walks you through the data prep, phasing, imputation, and post imputation QC that is needed to create a dosage VCF. I would highly recommend new users to utilize the extremely detailed explanation that can be found in the tutorial in order to become more familiar with Odyssey. Running through the tutorial covers all the essential, offers some tips, and provides a look at more advanced settings that will hopefully make data prep, QC, phasing, imputation, and post Imputation QC very simple and easy. It will only take around 3-6 hour to complete the tutorial given adequate computational resources. One can even truncate the analysis to a few chromosomes to decrease the amount of time to completion even further.


---------
Quick Setup
==============

Download Odyssey:
------------------------
On the Odyssey Github page, click Clone or download

Note: It's important that you do not rename any of the file directories in the Odyssey Folder. The scripts within the main Odyssey folder organize all the created files based on the the names of the pre-existing folders, so renaming the folders will not be good

Place Odyssey: 
-----------------------
Place Odyssey on the system on which you want to phase/impute/analyze your data. The Odyssey folder will hereafter be referred to as the home directory since all the main scripts will be executed from here.

Setup Dependencies: 
------------------------
Odyssey is dependent on several programs that aid in genetic manipulations (and quality control), genetic phasing, imputation, and the analysis of the imputed data. Therefore, before running Odyssey you will need to make sure these programs are installed and compiled correctly on your system. So please refer to these programs installation instructions.

	Dependencies:
		
		1) Plink 1.9 (http://www.cog-genomics.org/plink2)
		2) Plink 2.0 July 19 build or later (https://www.cog-genomics.org/plink/2.0/)
		3) Shapeit2 (http://mathgen.stats.ox.ac.uk/genetics_software/shapeit/shapeit.html)
		4) Impute2 (http://mathgen.stats.ox.ac.uk/impute/impute_v2.html)
		5) Impute4 (https://jmarchini.org/impute-4/) by permission
		6) SNPTEST (https://mathgen.stats.ox.ac.uk/genetics_software/snptest/snptest.html)
		7) BCFTools (https://samtools.github.io/bcftools/bcftools.html) + fixref plugin
		8) GNU-Parallel (https://www.gnu.org/software/parallel/) -- OPTIONAL (Speeds up the latter scripts significantly though)
		9) R (updated to at least r/3.4.4) with the following packages
			a) data.table
			b) qqman
			c) dplyr
			d) stringr
			e) manhattanly
Setup Reference Data: 
--------------------------
You will have to populate the Reference Data Folder with reference data that will be used for phasing and imputation. Refer to the Odyssey Tutorial to download the newest version of the 1000 Genome Reference data, from the Impute2 site, but if you want to use your own reference data you may populate the folder with your custom reference data. Odyssey is configured by default to work with the following reference data:

a) The reference data is downloaded from the IMPUTE2 site under their reference data for "1,000 Genomes haplotypes -- Phase 3 integrated variant set release in NCBI build 37 (hg19) coordinates" (Updated 3 Aug 2015)
	
	i) Downloaded from https://mathgen.stats.ox.ac.uk/impute/1000GP_Phase3.html
		
However, if you choose to use a custom reference dataset, then several adjustments may need to be made to the naming of the reference files (.legend, .map, and .hap) and also to the Config.conf file. These adjustments are explained more in detail in the Config.conf file. And obviously, users are should pay particular attention to make sure that custom reference data is sync'ed to the target data (i.e. don't try and use a Target dataset mapped to GRCH 37 to a ref dataset mapped to GRCH 38).

Setup Target Data: 
-----------------------
Deposit the data you would like phased/imputed (hereafter referred to as "Target" data) in ./Odyssey/Target/PLACE_NEW_PROJECT_TARGET_DATA_HERE/
	
a) While Odyssey performs basic quality control prior to phasing (filtering individuals and variants based on missingness, minor allele frequency filter, and Hardy-Weinbergy Equilibrium tests), it is up to the user to make sure the target data is in sync with the reference data
	
	i) If you are not blessed to have perfect data right out of the sequencing machine you may be interested in utilizing Odyssey Submodules. The HGDP_Starter_SubModule is mostly for use with the HGDP tutorial data, but you may be interested in utilizing the Remapping_Made_Easy_SubModule. It essentially, is responsible for utilizing NCBI's Remap Service to automate the remapping process of your data to a build of your choice (that is supported by NCBI of course). More information on running this sub-module can be found with the Odyssey Tutorial.
	ii) If you feel as though the data is mapped to the right build, but not properly sync'ed to your reference data then you may place the Plink .bed, .bim, and .fam files into the DataPrepModule, execute 0_DataPrepCleanup.sh from ./Odyssey, and then take the resulting sync'ed data and place it in ./Odyssey/Target/PLACE_NEW_PROJECT_TARGET_DATA_HERE/. Doing this pre-step is actually highly recommended. While this pre-step assumes aligning to a GRCH37 build of Homo_Sapien, this can be changed. A more detailed explanation of data cleanup can be found from within the Odyssey Tutorial.

Fill out Config.conf and Programs.conf: 
-------------------------------------------
Config.conf file is responsible for setting the variables that will be used to execute the scripts in the home directory. Essentially, all the main scripts on the home directory "phone home" back to the Config file to lookup their variables. Because of this, unless additional customization is needed, you should never have to modify any of the main scripts in the home directory (however, each script within Odyssey Modules and Submodules are heavily commented to allow for easy navigation when attempting more advanced customization not supported by the config file). Most of these variables are relating to toggling steps of Odyssey (to allow for more user control and to help with troubleshooting), specifying home directories, etc. Step by step instructions on how to setup the Config.conf variables can be found in the Config file itself and a more detailed explanation can be found in the Odyssey Tutorial. Programs.conf is another configuration file, but it is responsible for directing Odyssey scripts to its program dependencies' exec files.

A Note on Odyssey File Organization:
--------------------------------------
Odyssey has an organization scheme to keep all imputation results separate from each other so when the user does not have to "reset" the Odyssey folder after each imputation run. Odyssey does this by organizing files into 'Imputatation Projects'. Each project will create a folder that is identified by a BaseName, a name that is specified at the beginning of the analysis to identify the imputation run. This will allow for the creation of identifiable folders within the Target, Phase, and Impute folders. For example, if I have a dataset of Homo sapien target DNA that I want imputed, I will setup an Imputation Project named "Human_Impute1" (name must not contain whitespaces). Odyssey will then create a target folder (withing the Target directory) specific to my imputation run and move my data into it. Odyssey will then deposit phased and imputated scripts, outputs, and results within the Phase and Impute folders respectively. If I then want to impute a different set of data, I simply create a new Imputation project which will separately house the target, phase, and impute data from my second imputation run.


 
---------
Running Odyssey
==============

Step 1: Pre-Imputation QC and Setup
-----------------------

1) Once the target data has been cleaned and is deposited in the 'PLACE_NEW_PROJECT_TARGET_DATA_HERE' folder within the Target folder directory, the first script, "1_ImputeProjectSetup-QC-Split.sh" can be run from the home directory. Simply use a command prompt to navigate to the home directory (e.g. $ cd /path/to/Odyssey/) and execute the script (e.g. $ 1_ImputeProjectSetup-QC-Split.sh) which will setup an Imputation Project Folder, move your Target Data into this Project Folder within the Target Directory, and will provide a small amount of pre-imputation QC which includes:

	a) Filtering for individual missingness (removes individuals missing more than 5% of genomic content)
	b) Filtering for genetic variant missingness (removes variants missing in more than 5% of individuals)
	c) Filtering for minor allele frequencies (removes variants that contain a minor allele frequency of 2.5% or less)
	d) Filtering for Hardy-Weinberg Equilibrium (removes variants that have a HWE p-value of 1e-6 or below). This test is very lenient to allow for diverse target data.
	
2) SHAPEIT2 requires data to be split by chromosome so the last step is splitting the dataset into their respective chromsomes
	By default the script looks for chromosomes 1-26 (the default for human samples) into their respective chromosomes. Any advanced customizations to this default may be made in "1_ImputeProjectSetup-QC-Split.sh" directly.

Step 2: Phasing
-----------------------

1) Odyssey organizes phased data into an Imputation Project Folder created within the Phase folder. The name of this folder is specified by the Imputation Project Name variable and will contain subdirectories that house the phasing scripts, outputs, and results.
2) No additional files outside of those created in Step 1 need to be created to run the Phasing step. Each step builds on the next and contains all the files necessary to run the next step. 

	a) If you intend to use the 1000 Genome Data reference data specified in the Odyssey Tutorial, then you do not need to modify the Reference Variable Section within Config.conf. If you intend to use your own reference data or non-human target data then you will need to make some adjustments to the Config.conf file and/or your reference filenames.
	
3) Phasing is carried out using SHAPEIT2 recommended settings (shown below) and a reference data map provided by IMPUTE2. If using a HPC and you wish to alter the PBS settings you may do so by following the direction found directly in "2_PhasingScriptMaker.sh" itself by navigating to the "Alter Script for HPC if necessary" commented line. If you are not running on a system that has a TORQUE resource monitor then you can ignore the PBS commands as they should just be treated as commented out lines by your system
		
		i) The SHAPEIT command has the general form: shapeit --thread [#] --input-bed [PlinkTargetBedFile] --input-map [ReferenceMapFile] --output-max [OutputPhasedName] --output-log [OutputPhasedLogName]

4) More advanced customization of phasing can be achieved by altering the heavily commented "2_PhasingScriptMaker.sh" directly.

5) Phased output, logs, and scripts are deposited within the Imputation Project directory placed within the Phase directory

Step 3a: Imputation
-----------------------

1) Odyssey organizes imputed data into an Imputation Project Folder created within the Impute folder. The name of this folder is specified by the Imputation Project Name variable and will contain subdirectories that house the imputation scripts, outputs, and results.
2) Imputation is carried out using IMPUTE2 recommended settings using reference data (genetic, hap, and map files) provided from IMPUTE2 and designed to be compatible with their program. The General IMPUTE2/4 command is listed below. Note that the reason why Impute2 and Impute4 are used is because Impute4 has superior speed in comparison to Impute2, but is not yet able to impute the NON-PAR regions of the X chromosome). Therefore, as of now, Impute4 is used to impute chromosomes 1-22 and Impute2 to impute the Non-Par region of the X chromosome. If using a HPC and you wish to alter the PBS settings you may do so by following the direction found directly in "3_ImputeScriptMaker.sh" itself by navigating to the "Alter Script for HPC if necessary" commented line. If you are not running on a system that has a TORQUE resource monitor then you can ignore the PBS commands as they should just be treated as commented out lines by your system
		
		i) impute -known_haps [PhasedHapsFileFromSHAPEIT]  -sample_g [PhasedOutputFromSHAPEIT] -m [ReferenceGeneticMapFile] -h [ReferenceHapsFile] -l [ReferenceLegendFile] -int [StartChromosomeChunkSegment EndChromosomeChunkSegment] -Ne [20000] -o [OutputName]

3) More advanced customization of imputation can be achieved by altering the heavily commented "3_ImputeScriptMaker.sh" directly.

4) Imputed output, logs, and scripts are deposited within the Imputation Project directory placed within the Raw_Imputation folder within the Impute directory


Step 3b: Post Imputation Cleaning and Concatenation
-----------------------

1) Since imputted files are divided by chromosome and by segment, these files must be concatenated. Odyssey does this through 3b_ConcatConvert.sh which does a simple concat command with all the imputed chromsomal segments housed within the Raw Imputation folder and re-assigns them their chromosome number (which isn't explicitly assigned during imputation)
2) SNPTEST creates a SNP Report which allows you to populate the Imputation QC INFO metric. This will later be used to filter the VCF file (as specified by the FilterINFO variables specified within Config.conf).
3) Concatenated chromsomal .GEN files are converted to a dosage VCF file (.VCF) using Plink 2.0
4) Finally, the dosage VCF files are concatenated via BCFTools since Plink 2.0 currently doesn't support the merging of these files.
5) There is also an option to allow the retention of temporary files for troubleshooting purposes, but for the sake of saving space these files are deleted by default.
5) The final output within the ConcatImputation Folder contains the following:
		
	i.	.snpstat (QCTool2 snp report that contains several metrics on the imputed chromosome including the INFO score)
	ii.	.snpstatOut (is a log file for QCTool2 which contains the run results from QCTool AND a count of the total number of variants imputed for the particular chromosome and how many are left after INFO filtering)
	iii.	.list (a file that contains the variants within the chromosome specified that meet the INFO score requirements specified in FilterINFO 
	iv.	Most importantly is the 1DONE_[BaseName].vcf.gz file which is the final product of the Odyssey pipeline. This dosage VCF file can be inputted into analysis programs such as Plink 2.0, SNPTEST, GenAble, etc. for all sorts of analyzes


Step 4: Setup GWAS Project and Run GWAS Analysis
-----------------------
The last step in Odyssey will be to setup a GWAS Analysis Project where a dosage VCF can either be manually imported into Plink or an Imputation Project Name can be specified, which will allow Odyssey to automatically lookup the dosage VCF file and corresponding sex sample file (the .fam file for the dataset which contains sex information) and perform an analysis. How Plink imports the data can be setup via the Config.conf file.
The Plink analysis and corresponding R script is designed to perform and visualize a genotype:phenotype analysis (i.e. a Genome-Wide-Association Study). Specifically, the genotypic data and inputted phenotypic data is fit on a general linear model or a logistic model, and the R script analyzes the output results.

Note: The R visualization step requires the following R packages (please refer to their corresonding installation instructions to properly configure them within your R environment before executing '5_AutomatePlink.sh': data.table, qqman, stringr, dplyr, and manhattanly

1) Users will need to setup a GWAS Project for the GWAS analysis by completing the GWAS Project Variables Section of the Config.conf file. More specific details on how to fill out the variables are included within the Config file itself and the tutorial, but briefly:
	
		a) Specify the GWAS Project Name
		b) List the Imputation Project the user wishes to analyze or manually list the path of the dosage VCF the user wishes to analyze
		c) Specify the name of the covariate/phenotype file that correspond to the imputation files (placed in ./GWAS/Phenotype). 
		Note: It is important that the user read the instructions in the Plink manual regarding the formatting of the phenotype and covariate files.
		d) List any additional Plink options to be run during the analysis withing the "Plink_Options" variable

2) Run the '5_AutomatePlink.sh' script from the Odyssey directory
3) A new GWAS Project directory should then become visible in the GWAS directory which contains:
	
		a) An analysis log file + the R and Bash scripts used to run the analysis/visualization
		b) A QQPlot
		c) An interactive Manhattan Plot
		d) A summary table that contains the top 10000 variants with the lowest unadjusted p-values (as well as multiple comparison corrections, effect sizes, etc.)
		e) A gzipped file that contains the raw results from Plink




