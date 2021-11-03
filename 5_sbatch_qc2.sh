#!/bin/bash
#SBATCH --job-name=QC2							# Job name
#SBATCH --partition=compute						# short queue for testing/compiling/debugging/benchmarking, not chargable, max 16cpus and 4h
#SBATCH --mail-type=END,FAIL					# Mail events (NONE, BEGIN, END, FAIL, ALL)
#SBATCH --mail-user=mmclaughlin@icr.ac.uk		# Where to send mail
#SBATCH --nodes=1                   		 	# Run all processes on a single node	
#SBATCH --ntasks=1                   			# Run a single task		
#SBATCH --cpus-per-task=24            			# Number of threads per task (OMP threads)
#SBATCH --mem-per-cpu=1000                    	# Job memory request
#SBATCH --time=04:00:00							# Time limit hrs:min:sec <=24 ~10min; <=48 ~20min; etc
#SBATCH --output=log5_fastqc2.txt				# Output txt log

export OMP_NUM_THREADS=$SLURM_CPUS_PER_TASK # sets cpus per task from slurm job script above as i'm not using srun
echo '[SLURM CPUS PER TASK:]' $SLURM_CPUS_PER_TASK # prints to log file to allow later confirmation

module load FastQC SAMtools anaconda/3 # load required modules
source activate MMrnaseqenv # load conda environment containing multiqc, trimmomatic, hisat2 and stringtie



#######################################
echo '[STEP 4: POST-TRIM FASTQC CHECK]'
#######################################

date # prints date for slurm log
path='alignment_files/fastqc_trimmed' # set folder to save everything to
echo $path

mkdir -p $path # make directory to store fastqc analysis of TRIMMED fastq files
find ./alignment_files/samples/ -name "[A-Z][0-9]_trim.fq.gz" -type f | sort > $path/fastq_trimmed_file_list.txt # exports TRIMMED R1/R2 paths as a log
fastq_trimmed_file_list=($(cut -f 1 $path/fastq_trimmed_file_list.txt)) # imports the above file rather than duplicate code and risk an error
echo ${fastq_trimmed_file_list[@]} # @ echos all elements in variables array to record on slurm output log

# Actual fastqc line
fastqc --threads $SLURM_CPUS_PER_TASK ${fastq_trimmed_file_list[@]} # multithreaded, but two output html and zip files saved in sample folder and need moved

# Move fastqc output files
find ./alignment_files/samples/ -name "*_trim_fastqc.[htmlzip]*" -type f | sort > $path/fastqc_trimmed_output_file_list.txt # saves html and zip paths as a log
fastqc_trimmed_output_file_list=$(cut -f 1 $path/fastqc_trimmed_output_file_list.txt) # imports the above file rather than duplicate code and risk an error
echo ${fastqc_trimmed_output_file_list[@]} # @ echos all elements in variables array to record on slurm output log

for fastqc_trimmed_output_file in ${fastqc_trimmed_output_file_list[@]}; do
	sample_name=$(echo $fastqc_trimmed_output_file | sed -E "s/.\/alignment_files\/samples\/([A-Za-z0-9_-]*)\/.*/\1/g")
	echo $sample_name
	mkdir -p $path/$sample_name/
	mv --verbose $fastqc_trimmed_output_file $path/$sample_name/
done



##################################
echo '[STEP 5: POST-TRIM MULTIQC]'
##################################
date
multiqc -d $path --outdir $path



################################
echo '[...SYNC TO RDS...]'
################################
# saves the current folder location (ie the project folder) of the script to the variable $wd
# submits sbatch to sync ALMA TRIMMED fastqc run to RDS to be viewed
# renames to _aligned to differentiate from the unaligned files, don't want a folder structure mess due to syncing if there is an error
# leaving off the trailing / of both file addresses in rsync is important!
wd=${PWD##*/}

sbatch --time=02:00:00 --job-name=syncRDS --partition=data-transfer --mail-type=END,FAIL --mail-user=mmclaughlin@icr.ac.uk --ntasks=1 --output=log5b_synctoRDS.txt \
	--wrap="echo $wd; mv --verbose ../$wd ../$wd\_complete; srun rsync -av /home/mmclaughlin/SCRATCH_mmclaughlin/$wd\_complete  /data/rds/DRI/URTHY/TARGTHER/mmclaughlin; mv --verbose ../$wd\_complete ../$wd"

### SCRIPT-END



