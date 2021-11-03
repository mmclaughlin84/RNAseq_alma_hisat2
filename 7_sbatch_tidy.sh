#!/bin/bash
#SBATCH --job-name=tidy							# Job name
#SBATCH --partition=compute						# short queue for testing/compiling/debugging/benchmarking, not chargable, max 16cpus and 4h
#SBATCH --mail-type=END,FAIL					# Mail events (NONE, BEGIN, END, FAIL, ALL)
#SBATCH --mail-user=mmclaughlin@icr.ac.uk		# Where to send mail
#SBATCH --nodes=1                   		 	# Run all processes on a single node	
#SBATCH --ntasks=1                   			# Run a single task		
#SBATCH --cpus-per-task=4            			# Number of threads per task (OMP threads)
#SBATCH --mem-per-cpu=1000                    	# Job memory request
#SBATCH --time=01:00:00							# Time limit hrs:min:sec (give 15+5 min per paired-sample)
#SBATCH --output=log7_tidy.txt					# Output txt log



###########################
echo '[STEP 7: prepDE.py3]'
###########################
date
python alignment_files/prepDE.py3 -i ballgown/ -g counts_gene.csv -t counts_transcript.csv



############################
echo '[STEP 8: Tidy Up]'
############################
# moves ballgown directory and bam files to alignment_files directory
# creates analysis folder for R analysis
date
mv ballgown alignment_files/
mkdir -p alignment_files/bam_files/; mv *.bam alignment_files/bam_files/
mkdir -p alma_logs/
mkdir -p analysis



################################
echo '[...FINAL SYNC TO RDS...]'
################################

# saves the current folder location (ie the project folder) of the script to the variable $wd
# submits sbatch to sync ALMA fastqc run to RDS to be viewed
# renames to _aligned to differentiate from the unaligned files, don't want a folder structure mess due to syncing if there is an error
# leaving off the trailing / of both file addresses in rsync is important!
wd=${PWD##*/} 

sbatch --time=02:00:00 --job-name=syncRDS --partition=data-transfer --mail-type=END,FAIL --mail-user=mmclaughlin@icr.ac.uk --ntasks=1 --output=log7b_synctoRDS.txt \
	--wrap="echo $wd; mv --verbose ../$wd ../$wd\_complete; srun rsync -av /home/mmclaughlin/SCRATCH_mmclaughlin/$wd\_complete  /data/rds/DRI/URTHY/TARGTHER/mmclaughlin; mv --verbose ../$wd\_complete ../$wd"

### SCRIPT-END