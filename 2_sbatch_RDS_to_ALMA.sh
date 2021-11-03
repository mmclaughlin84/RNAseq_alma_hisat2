#!/bin/bash
#SBATCH --job-name=syncalma						# Job name will appear on emails and squeue
#SBATCH --partition=data-transfer				# queue for transfering data, not chargable
#SBATCH --mail-type=END,FAIL					# Mail events (NONE, BEGIN, END, FAIL, ALL)
#SBATCH --mail-user=mmclaughlin@icr.ac.uk		# Where to send mail
#SBATCH --ntasks=1
#SBATCH --time=03:00:00							# Job time, very unlikely to take more than 30 min
#SBATCH --output=log2_SyncToALMA.txt			# Output log name

# this copies the folder indicated on the RDS to the ALMA scratch location
# saves the current folder location (ie the project folder) of the script to the variable $wd
wd=${PWD##*/} 
echo $wd

# leaving off the trailing / of both is important!
srun rsync -av /data/rds/DRI/URTHY/TARGTHER/mmclaughlin/$wd /home/mmclaughlin/SCRATCH_mmclaughlin



### OLD CODE
# this copies the folder indicated on the RDS to the ALMA scratch location
#srun rsync -av /data/rds/DRI/URTHY/TARGTHER/mmclaughlin/alma_trial /home/mmclaughlin/SCRATCH_mmclaughlin # leaving off the trailing / of both is important!
