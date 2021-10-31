# Unix Commands
## Basic

* `ls` list files in the current directory
* `ls -lh` as above, but long format and human readable file sizes
* `ls -lha` list 'all' ie hidden files as well
* `cd directory_name` # change to a directory that exists in the current working directory
* `pwd` # 'prints' the current working directory - by print, meaning to show in text on the terminal, not send to a printer
* `cd ~` # change to home directory
* `cd ~/Desktop/` # change to the Desktop, which is a folder that exists in your home directory on Macs
* `cd /` # Change to the 'root' directory, ie the very bottom of the file tree
* `cd /Volumes/` # USB pens, external hard disks, the RDS/SHARED drive all are listed here
* `cd /Users/vroulstone/` # this is the full path to a home directory, ~ is just a shortcut
* `mkdir test` # makes a new folder called 'test' in the current 'working directory' (ie where you navigated to using cd)
* `mv test.txt moved.txt` # move a file or folder, in this case renaming test.txt to moved.txt
* `mv test.txt location/moved.txt` # moves the file test.txt into the folder location and renames it to moved.txt
* `head test.txt` # see the start of a long text file
* `tail test.txt` # see the end of a long text file
* `less test.txt` # can scroll through a long text file without openning the whole thing in memory
* `man less` # opens the manual for the command less (man cd would be the manual for change directory)
* `nano test.txt` # allows editing as well as reading a txt file
* `vi test.txt` # another text editing programme, decide which you like more

### Deleting files with rm
There is a whole section for this as it's a dangerous command. There is no trash bin or ctrl-z on the command line, if you delete something it's gone. You would need to restore from a backup.

* `rm test.txt` # delete the file test.txt
* `rm -i test.txt` # delete, but ask first for confirmation
* `rm location` # this doesn't work, you cannot delete a folder with just rm
* `rm -ri location` # r stands for recursive, it deletes a folder and everything in it, annoyingly i asks for every file in a folder


## More Advanced

These would take too long to explain, but you can and read about how to use them

* `ln` # creating links
* `rsync` # syncing files between folders
* `find` # find files/folders based on pattern matching
* `sed` # extract text based on pattern matching of input list
* `wget` # download files from the internet
* `awk` # a bit like sed, but more difficult to understand
* `find | sed` # | is a piping command that passed to output of find to sed for further processing
* `find | sed > save.txt` # using > allows the output to be saved to a file rather than be 'printed' to the console

.

# RNA-seq Alignment

## ALMA login


Connect to ALMA HPC cluster with ssh

```
ssh user_name@alma.icr.ac.uk
```

There are 3 "ways" you use ALMA. 

1. The login node - after entering a password, you start on the login node (says login in terminal)
2. An interactive session - get assigned 1-4 CPUs for testing and running small scripts (says node01)
3. Submit slurm jobs using the 'sbatch' command - returns a jobid and jobs enter the job queue

*NOTE: Normally you work entirely using an interactive session. You run bash scripts and submit `sbatch` jobs. However, you cannot navigate to the RDS in an interactive session. You can only do this using a login session. Therefore you navigate to the RDS and submit an sbatch job to transfer files from the RDS to ALMA, then start interactive session*

Start an interactive session; `exit` interactive session and return to login node, or exit login mode and quit ALMA completely.

```
srun --pty -t 6:00:00 -p interactive bash						# 6h with default 1 CPU
srun --cpus-per-task=4 --pty -t 04:00:00 -p interactive bash 	# 4h with 4 CPUs (maximum)
exit  
```



## Navigating between ALMA and the RDS (when logged into ALMA)

```
cd ~ 											# Home on ALMA with ~
cd /home/vroulstone/ 							# Home on ALMA via direct location
cd /data/scratch/DRI/URTHY/TARGTHER/vroulstone/ # Team SCRATCH location (need to create <username_folder>)
cd /data/rds/DRI/URTHY/TARGTHER/vroulstone/ 	# RDS location
```

You can.create links to SCRATCH or RDS locations to make life easier. Change to home folder first, then run the following ln commands.

```
cd ~
ln -s /data/scratch/DRI/URTHY/TARGTHER/vroulstone SCRATCH_vroulstone
ln -s /data/rds/DRI/URTHY/TARGTHER/vroulstone/ RDS_vroulstone
```


Can now quickly navigate to SCRATCH and RDS folders using the shortcuts

```
cd ~/SCRATCH_vroulstone
cd ~/RDS_vroulstone
```

## Installing / Loading Software Packages


You need to setup a hidden .conda folder but in scratch linked to home directory as home directory doesn't have enough storage. cd to home, delete the existing hidden .conda directory, change to scratch folder, make new .conda directory in the SCRATCH storage location (which is larger), cd back to home. Create a link so that when installing, software follows the link and installs in the .conda folder in SCRATCH, not home.

```
cd ~
rm -r .conda
cd /data/scratch/DRI/URTHY/TARGTHER/vroulstone/
mkdir .conda
cd ~
ln -s /data/scratch/DRI/URTHY/TARGTHER/vroulstone/.conda .conda
```

Installing software (ie 'creating a conda environment') must be set up in an interactive session. `module` is used to view available modules which can be loaded. We need to load the package manager anaconda. `conda create` installs multiqc, trimmomatic, hisat2 and stringtie from the channels listed under the environment name 'MMrnaseqenv'. **Don't change the env name MMrnaseqenv, as it is used in the scripts**. To load the installed conda environment use the following in an interactive session or a script.

```
srun --pty -t 12:00:00 -p interactive bash
module avail
module load anaconda/3
conda create --name MMrnaseqenv --channel bioconda -c conda-forge multiqc trimmomatic hisat2 stringtie
source activate MMrnaseqenv
```

## Slurm Job Management and the Job Queue

The only thing the login node is used for is to navigate to an RDS folder and, using sbatch, starting a data transfer to ALMA. Testing, or installing conda environments, is carried out using an interactive session. Everything else involves submiting 'jobs' to the SLURM job manager using the `sbatch my_script.sh` command.

More on what this script looks like later. After submitting a job with `sbatch`, you get given a job ID which is a number. You can view EVERYTHING in the SLURM queue with `squeue`. Or you can view only your jobs using the `-u` or `--user` flag.

```
sbatch job_script.sh
squeue
squeue -u vroulstone
```

If your job was #123456, you can cancel it specifically, cancel all your running jobs with the `-u` flag, or cancel only pending jobs by adding `--state==PENDING`.

```
scancel 123456
scancel -u vroulstone
scancel -u vroulstone --state==PENDING
```

## SLURM Jobs - sbatch scripts


There are two types of slurm jobs, data transfers and actual computational jobs. One uses the `data-transfer` partition, the other the `compute` partition. The hash at the start of the line is necessary, comments are on the right. CPUS, memory, time, depends on the job. Jobs are killed when the time limit is reached, so give a safe amount of excess time.

A data-transfer job, syncing (ie making a copy of) files from a hypothetical RDS location to the ALMA scratch location.

```
#!/bin/bash										# Tell the operating system which interpreter to use, ie bash
#SBATCH --job-name=transfer						# Job name will appear on emails and squeue
#SBATCH --partition=data-transfer				# queue for transfering data, not chargable
#SBATCH --mail-type=END,FAIL					# Mail events (NONE, BEGIN, END, FAIL, ALL)
#SBATCH --mail-user=email_address@icr.ac.uk		# Where to send email
#SBATCH --ntasks=1								# ntasks will normally always =1
#SBATCH --time=01:00:00							# Job time, very unlikely to take more than 30 min
#SBATCH --output=log_file.txt					# Log file name

# rsync lauched by srun (a slurm function) using archived and verbose mode
# will sync files from the RDS to ALMA
srun rsync -av RDS_location/path/to/folder ALMA_SCRATCH_location/path/to/folder
```


A compute job, with the example being a list of fastq files being run using fastqc and 8 CPUs

```
#!/bin/bash										# Tell the operating system which interpreter to use, ie bash
#SBATCH --job-name=my_job						# Job name
#SBATCH --partition=compute						# compute, chargable
#SBATCH --mail-type=END,FAIL					# Mail events (NONE, BEGIN, END, FAIL, ALL)
#SBATCH --mail-user=email_address@icr.ac.uk		# Where to send mail
#SBATCH --ntasks=1                   			# Run a single task		
#SBATCH --nodes=1                   		 	# Run all processes on a single node	
#SBATCH --cpus-per-task=8            			# Number of threads per task (OpenMP threads, max=24)
#SBATCH --mem-per-cpu=1000                    	# Job memory request
#SBATCH --time=02:00:00							# Time limit hrs:min:sec
#SBATCH --output=my_job_log.txt					# Output txt log

module load FastQC
fastq_file_list=$(find ./fastq_files/ -name "R[0-9].fq.gz" -type f | sort)
fastqc --threads $SLURM_CPUS_PER_TASK ${fastq_file_list[@]}
```

.


# ALIGNMENT PIPELINE INSTRUCTIONS

## Setup Project Folder and Download Scripts

Using a local terminal (ie your computer, not AlMA), navigate to the users folder on the RDS. Create a project directory using the nomenclature **{sequencingType}\_{model}\_{initials}\_{experimentId}\_{treatments}**.

```
cd /Volumes/DATA/DRI/URTHY/TARGTHER/vroulstone/
mkdir RNAseq_4434_JKVR_JKVR002_RP1aPD1
cd RNAseq_4434_JKVR_JKVR002_RP1aPD1
```

Create the directories `alignment_files/samples` and `alignment_files/indexes`. Download the alignment scripts from github using the first two lines starting with `curl`. 

```
mkdir -p alignment_files/{samples,indexes}
curl -O "https://raw.githubusercontent.com/mmclaughlin84/RNAseq_alma_hisat2/master/{1_Rstudio_rename.R,2_sbatch_RDS_to_ALMA.sh,3_sbatch_qc1.sh,4_intbash_trim.sh,5_sbatch_qc2.sh,6_intbash_align.sh,7_sbatch_tidy.sh,8_localbash_cleanup.sh}"
curl -o alignment_files/prepDE.py3 "https://raw.githubusercontent.com/mmclaughlin84/RNAseq_alma_hisat2/master/prepDE.py3"
```

**There is a folder on the RDS was is already setup with the indexes files required**. Using `cp` or `rsync` are both painfully slow do it is easier to do without using code. Find the directory/folder called `indexes_ms_hisat2` and right click, then select `Duplicate`. Rename the resulting folder to `indexes` and drag it so it is in the project folder `alignment_files/indexes`.

If the pre-prepared indexes folder on the RDS was not there, here is how you would source the files. Download the Mus Musculus .gtf file using `curl` and `unzip`. Download an already indexed Mus Musculus genome from the HISAT2 website. You might need to drag the files into the indexes folder. All the files should be in indexes, there should be none in subdirectories.

```
curl -o ./alignment_files/indexes/Mus_musculus.GRCm38.102.gtf.gz "ftp://ftp.ensembl.org/pub/release-102/gtf/mus_musculus/Mus_musculus.GRCm38.102.gtf.gz"
gunzip ./alignment_files/indexes/Mus_musculus.GRCm38.102.gtf.gz

curl -o ./alignment_files/indexes/grcm38.tar.gz "https://cloud.biohpc.swmed.edu/index.php/s/grcm38/download/grcm38.tar.gz"
tar -xvzf ./alignment_files/indexes/grcm38.tar.gz
```

The final step is to go to the RDS project folder, and open scripts 2-7 in **Textmate**. *You need to change the email address to be your_name@icr.ac.uk* - sending emails to mmclaughlin@icr.ac.uk is the default and will not be of much use to you.


## DOWNLOAD FASTQ FILES

If samples were sequenced by the TPU, the TPU will transfer them to the folder "SHARED" in TARGTHER. Drag the files into the samples folder so they have the file structure shown further down (after sftp steps). If samples were sequence by Genewiz, they need to be downloaded using sftp using the login and password they provide. Connect using sftp and enter password (may require two attempts).

```
sftp <user_name>@gweusftp.brooks.com
```

List the files on the genewiz server, and navigate about to check directory structure. It should look like a single directory, contain subdirectories for each sample name, each containing a R1 and R2 fastq files. Use `cd ..` to move into the directory containing subdirectories for each sample.

```
ls -lh
cd genewiz_project_folder # This is usually a string of numbers
```

Set ‘local directory’, ie where on your computer to download the folder to. Use lls to confirm location is as expected.

```
lcd /Volumes/DATA/DRI/URTHY/TARGTHER/vroulstone/RNAseq_4434_JKVR_JKVR002_RP1aPD1
lls
```

Start transfer with flags `-r` recursive and `-a` attempt to resume partial transfers of existing files. The `*` copies everything in the folder, ie each directory named for each sample submitted. If files fail to transfer, repeat the below line.

```
mget -ra *
```


Exit sftp by typing `exit`. The file structure of the resulting sample folder on the RDS should look like the block of file paths below. **Each sample should be a single folder, containing two fastq.gz/fq.gz files, one with R1 the other with R2 somewhere in the name. If this is the case, the first script will run without alteration**.

```
alignment_files/samples/A001_015485/A001_015485_R1.fastq.gz
alignment_files/samples/A001_015485/A001_015485_R2.fastq.gz
alignment_files/samples/A002_015486/A002_015486_R1.fastq.gz
alignment_files/samples/A002_015486/A002_015486_R2.fastq.gz
```


## RUNNING ALIGNMENT SCRIPTS

.

### SCRIPT 1: Wrangling Samples Into Set Folder Structure

Script 1 is an Rscript that runs in Rstudio - so go open in Rstudio. Follow the instructions in the Rscript to rename the samples to full and correct sample naming. It structures the sample folder and R1/2 files in such a way that all additional alignment scripts run without alteration. The only exception is if you wish to alter the number of CPUs requested. This is explained at the two step where this is a suggestion.

When you are finished with script 1, the file structure should look as below. The sample folder has a name that contains ALL the details required for downstream analysis. The fastq files are now called `R1.fq.gz` and `R2.fq.gz`.

```
alignment_files/samples/JKVR002_4434_A01_injected_control_1/R1.fq.gz
alignment_files/samples/JKVR002_4434_A01_injected_control_1/R2.fq.gz
alignment_files/samples/JKVR002_4434_B04_injected_aPD1_4/R1.fq.gz
alignment_files/samples/JKVR002_4434_B04_injected_aPD1_4/R2.fq.gz
```

.

### SCRIPT 2: Copy RDS Project Folder to ALMA Scratch Disk

Login to ALMA. Under the login node, navigate to the project folder on the RDS. Submit script 2 as a SLURM job, to the project folder from the RDS to the users scratch location on ALMA.

```
ssh vroulstone@alma.icr.ac.uk
cd ~/RDS_vroulstone/RNAseq_4434_JKVR_JKVR002_RP1aPD1/
sbatch 2_sbatch_RDS_to_ALMA.sh
```

2 fastq files takes about 30s-45s to transfer, you will get a notification email to the address given in the `#SBATCH --mail-user=` variable at the top of the sbatch job script. It is set to be sent when a job ends, or if it fails, or if it is terminated due to the time limit being reached. You can just wait for an email, but it's a good idea to check the queue to confirm it has started running before you go home to find the next day there was an error and it quit after 1 second. You can check the job queue for the progress time by using `squeue -u vroulstone`.

.

### SCRIPT 3: Run FASTQC on All FASTQ files

Once the transfer is complete, move to the ALMA scratch location and start an interactive session. All other scripts are run in an interactive session. The first is only submitted under the login node, as once you start an interactive session, it is not possible to navigate to the RDS to run the script. If the current location is the RDS, an error will be given when starting an interactive session. The interactive session started successfully, it is just that the location you were in is no longer possible. This is why you use `cd` to change to the scratch disk first. If you forget, you just use cd to change directory after the error message.

```
cd ~/SCRATCH_vroulstone/RNAseq_4434_JKVR_JKVR002_RP1aPD1/
srun --pty -t 12:00:00 -p interative bash
```

Submit script 3 as a SLURM job using the sbatch command below. This SLURM job requests 24 CPUs which is the maximum number on a node on ALMA. If the cluster is very busy, this will get stuck in the SLURM job queue waiting for an entire free node.
You may want to cancel the job using the job ID number, edit the CPUs requested in the SLURM header, and resubmit. The header line to be edited reads `#SBATCH --cpus-per-task=24`. 

```
sbatch 3_sbatch_qc1.sh

squeue -u vroulstone 	# check the job queue
scancel <job_id> 		# cancel the job using the numerical jobID
nano 3_sbatch_qc1.sh 	# resubmit sbatch job after editing with nano
```

View the log for script 3 by typing `less log3_fastqc1.txt`and check for errors using. Normally it will say percentages and then complete for fastq files and a 100% complete multiQC file.

**The end of script 3 submits an sbatch job to sync the ALMA scratch location project folder to the RDS.** This is a new folder called `\<project_name\>\_complete` to avoid making a mess of the original folder if there is an error. Go and use the normal operating system graphical interface to open the .html file of multiqc at `alignment_files/fastqc_untrimmed/multiqc_report.html`. [Video on fastQC reports](https://www.youtube.com/watch?v=bz93ReOv87Y).

.

### SCRIPT 4: Run Trimmomatic to Trim Low Quality Bases and Reads

Trim N base calls, and low quality base calls using trimmomatic by running the bash script 4 below. Note, this is not an sbatch job script for SLURM. It is a bash script that is used to submit individual SLURM jobs for each sample. It requests 8 cores per job, so should be ok getting a slot on the cluster even if it is a little busy.

```
bash 4_intbash_trim.sh
```

Sadly submitting SLURM jobs in this way produces a log file for each job. To merge the log files into one, run the below line of code. **Be careful coping and pasting long lines of code like this, especially ones with `rm` in them.** View the log with `less`, checking for the line saying *"Input Read Pairs: 19801264 Both Surviving: 17985893 (90.83%)"* to be ~80-95%.

```
for file in log4_trim*.txt; do cat "$file"; echo "----------"; done > log4_all_trim.txt; find . -name "log4_trim*.txt" -exec rm {} \;

less log4_all_trim.txt
```

.

### SCRIPT 5: Run FASTQC Again, on All Trimmed FASTQ files

After trimming, run another qc step to check this has been successful. As before, this requests 24 cores, if the cluster is busy, you may want to cancel the job, edit the number of CPUs requested and resubmit it.

```
sbatch 5_sbatch_qc2.sh

squeue -u vroulstone 	# check the job queue
scancel <job_id> 		# cancel the job using the numerical jobID
nano 5_sbatch_qc2.sh 	# resubmit sbatch job after editing with nano
```

The end of script 5 submits an sbatch job to sync the ALMA scratch location project folder to the RDS. Use the normal operating system graphical user interface to open the .html file of multiqc at `alignment_files/fastqc_trimmed/multiqc_report.html`.

.

### SCRIPT 6: Run Hisat2-Stringtie Alignment

Now you can actually run the alignment using script 6. This script is not an sbatch script to submit a single job to SLURM, like the trimmomatic script, it submits individual SLURM jobs for each sample. It requests 8 cores, so should be ok getting a slot on the cluster.

```
sbatch 6_intbash_align.sh
```

When it's done, again it produces individual log files, so you will need to merge them using the below code. Use `less` to check the overall alignment rate is ~90+%.

```
for file in log6_align*.txt; do cat "$file"; echo "----------"; done > log6_all_align.txt; find . -name "log6_align*.txt" -exec rm {} \;

less log6_all_align.txt
```

.

### SCRIPT 7: Tidy Up and Final Sync From ALMA to RDS

The final script to run on ALMA is number 7. This quick sbatch SLURM job script runs the prepDE.py3 (prep for differential expression - ie DESeq2) script to produce the counts tables for both genes and transcripts. 'counts_gene.csv' is the file we are looking for. This is the raw counts used as the input for differential expression analysis. Script 7 also tidies up the stringtie output (ballgown folder), BAM files, and creates two folders, analysis and alma_logs. The end of script 7 automatically (like scripts 3 and 5) submits a final sbatch job to sync the completed alignment folder to the RDS.

```
sbatch 7_sbatch_tidy.sh

less log7_tidy.txt 			#log7 doesn't say much
```

A SLURM email notification for job name ***syncRDS*** indicates the alignment on ALMA is now done.

.

### SCRIPT 8: Post-Alignment Large File Reduction

You can delete the project folder on the ALMA scratch disk using the following commands. It's already copied to the RDS, though you may wish to wait for some post alignment analysis before doing this, and other steps, to reduce the large files produced as a results of the alignment. Remember be very careful with the use of rm! The use of -I will ask for confirmation if there are more than three files before deleting. The use of -I is only possible in ALMA, it is not a flag available with the bsd version of rm that is installed on macOS.


```
cd .. 										# go back one level from the ALMA scratch project directory
ls -l 										# check to see you are where you need to be
rm -rI RNAseq_4434_JKVR_JKVR002_RP1aPD1 	# delete the project folder on the ALMA SCRATCH disk
exit 										# exit interactive session to login node
exit 										# logout of ALMA
```

Navigate to the project folder on the RDS under a now local terminal bash shell. Run script 8 as a bash script to remove large files post-alignment (trimmed fastq files, unpaired fastq files, BAM files, indexes folder). This script leaves the original (untrimmed) fastq files in place. There is no log produced by script 8. There are tracking files saved to indicate where files have been deleted from as confirmation.

```
cd ~/RDS_vroulstone/RNAseq_4434_JKVR_JKVR002_RP1aPD1/ # If a shortcut has been set up
cd /data/rds/DRI/URTHY/TARGTHER/vroulstone/RNAseq_4434_JKVR_JKVR002_RP1aPD1/ # or full RDS directory path
bash 8_localbash_cleanup.sh
```

### End

































