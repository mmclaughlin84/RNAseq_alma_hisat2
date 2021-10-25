#! /bin/bash

############################
### Final Step: Cleanup ###
############################

### Run this at the end of analysis when everything is confirmed to be good
### Script to remove large files post alignment
### run in project base directory (ie where the scripts are all kept)

### leave a note of deleted files
### Find files and remove

# Bam files
find ./alignment_files/bam_files/ -name "*.bam" -type f | sort > alignment_files/bam_files/cleanup_bam_list.txt
find ./alignment_files/bam_files/ -name "*.bam" -type f -delete

# Trimmed fastq files
find ./alignment_files/samples/ -name "*_trim.fq.gz" -type f | sort > alignment_files/samples/cleanup_trim_list.txt
find ./alignment_files/samples/ -name "*_trim.fq.gz" -type f -delete

# Unpaired reads after trimming
find ./alignment_files/samples/ -name "*_unpaired.fq.gz" -type f | sort > alignment_files/samples/cleanup_unpaired_list.txt
find ./alignment_files/samples/ -name "*_unpaired.fq.gz" -type f -delete


