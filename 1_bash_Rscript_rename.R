### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### 
### RENAMING SEQUENCING FASTQ FILES TO CORRECT FORMAT -------------------------------------------------
### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### 

### Place in project folder on RDS, the same as for all other scripts used with ALMA
### run with: Rscript 1_bash_Rscript_rename.R > log1_rename.txt

### This script uses a input file sample_names.csv with the following columns
### NOTE: sample_names.csv has a double use for 1_rename.R and colData in 1_DESeq.R
### Only c('old_sample_name', 'sample_name') are used for this script, with old_sample_name = genewiz/tpu name

# sample_names.csv MUST contain colnames('old_sample_name', 'sample_name', 'treatment_wo_timepoint', 'timepoint', 'treatment')
# It can contain other columns for the purposes of record keeping, but the above five are essential to 1_bash_Rscript_rename.R and DESeq2
# It must have a column called 'old_sample_name' that corresponds exactly to that of rename_data$old_sample_name in code of this script
# sample_names            = {experimnetid}_{model}_{timepoint}_{treatment}_{replicate} # NOTE: do not use hyphens
# old_sample_name         = if a previous sample name used, ie a shorthand code provided to genewiz or the TPU
# treatment_wo_timepoint  = vehicle/PD1/RT/RT_PD1/etc
# timepoint               = 14d/21d, injected/contralateral, wt/KO, etc
# treatment               = 14d_vehicle/14d_PD1/21d_vehicle/21d_PD1/etc (note timepoint before treatment)

### OLD SCRIPT RETAINED FOR RUNNING WITHIN RSTUDIO ###
#setwd(dirname(rstudioapi::getSourceEditorContext()$path))
#getwd()
### OLD SCRIPT RETAINED FOR RUNNING WITHIN RSTUDIO ###

location = 'alignment_files/samples/'

# Parse old (ie current) address, old folder, and old file using recursive list.files
print('[START] Files Matching pattern = *q.gz')
list.files(pattern = 'q.gz', recursive = TRUE) # for output tracking
rename_data <- data.frame(old_address = list.files(pattern = 'q.gz', recursive = TRUE))
rename_data$old_sample_name <- gsub('(alignment_files/samples/)([A-Za-z0-9_-]*)\\/([A-Za-z0-9_-]*.[fastq]*.gz)', '\\2', rename_data$old_address)
rename_data$old_file_name <- gsub('(alignment_files/samples/)([A-Za-z0-9_-]*)\\/([A-Za-z0-9_-]*.[fastq]*.gz)', '\\3', rename_data$old_address)

###
###
### SAVE TEMPLATE FOR sample_names.csv IF NEEDED ###
sample_names_template <- rename_data[ ,c('old_sample_name'), drop = FALSE]
sample_names_template$sample_name <- ''
sample_names_template$treatment_wo_timepoint <- ''
sample_names_template$timepoint <- ''
sample_names_template$treatment <- ''
write.csv(sample_names_template, file = 'sample_names_template.csv', row.names = FALSE)
file.remove('sample_names_template.csv')
###
###
###

# Import sample_names.csv, only need 'old_sample_name' and 'sample_name' - merge with rename_data
sample_names <- read.csv('sample_names.csv')
sample_names <- sample_names[ , c('old_sample_name', 'sample_name')]
rename_data <- merge(rename_data, sample_names, by = 'old_sample_name', all = TRUE)
rm(sample_names)

# Below line is to account for test purposes, to remove NAs, that are created if running on a reduced number of folders
rename_data <- rename_data[!is.na(rename_data$old_file_name), ]

# Order by sample_name is it makes the print() in the for loops easier to follow
rename_data <- rename_data[order(rename_data$sample_name), ]

# Separate into two lists for R1 and R2 files 
rename_data_r1 <- rename_data[grepl('R1', rename_data$old_file_name), ]
rename_data_r2 <- rename_data[grepl('R2', rename_data$old_file_name), ]

# Save tracking files
write.csv(rename_data, file = paste0(location, 'tracking_rscript.csv'))
write.csv(rename_data_r1, file = paste0(location, 'tracking_rscript_r1.csv'))
write.csv(rename_data_r2, file = paste0(location, 'tracking_rscript_r2.csv'))

# PROGRESSION: 2 loops - 1st for R1 files, 2nd for R2 files
# [Loop 1]
# 1) create new folder based on $sample_name
# 2) 'renaming' R1 file a) moves it to sample_name folder b) changes file name to R1.fq.gz (NOTE: .fq.gz not fastq.qz)
# 3) save txt file as QC, allowing the R1 renaming process to be tracked in case a mistake is identified later
# [Loop 2]
# 1) new folder already created by R1 loop
# 2) rename R2 file a) to sample_name folder b) changing file name to R2.fq.gz (NOTE: .fq.gz not fastq.qz)
# 3) save txt file as QC, allowing the R2 renaming process to be tracked in case a mistake is identified later
# 4) $old_file_name folder is now empty, delete to remove

print('[R1 RENAMING - START]')

# Loop 1 (R1)
for (line in 1:nrow(rename_data_r1)) {
  new_sample_name_r1 <- rename_data_r1$sample_name[line]
  old_sample_address_r1 <- rename_data_r1$old_address[line]
  print(paste0('Creating Directory: ', new_sample_name_r1))
  dir.create(paste0(location, new_sample_name_r1))
  print(paste0('Renaming: ', old_sample_address_r1, ' >>> ', paste0(location, new_sample_name_r1, '/', 'R1.fq.gz')))
  file.rename(old_sample_address_r1, paste0(location, new_sample_name_r1, '/', 'R1.fq.gz'))
  cat(old_sample_address_r1, file=paste0(location, new_sample_name_r1, '/', 'R1_oldname.txt'))
  rm(line, new_sample_name_r1, old_sample_address_r1)
}
print('...R1 Renaming Complete')

print('[R2 RENAMING - START]')
# Loop 2 (R2)
for (line in 1:nrow(rename_data_r2)) {
  new_sample_name_r2 <- rename_data_r2$sample_name[line]
  old_sample_address_r2 <- rename_data_r2$old_address[line]
  print(paste0('Renaming: ', old_sample_address_r2, ' >>> ', paste0(location, new_sample_name_r2, '/', 'R2.fq.gz')))
  file.rename(old_sample_address_r2, paste0(location, new_sample_name_r2, '/', 'R2.fq.gz'))
  cat(old_sample_address_r2, file=paste0(location, new_sample_name_r2, '/', 'R2_oldname.txt'))
  print(paste0('Deleting Directory: ', paste0(location, rename_data_r2$old_sample_name[line])))
  unlink(paste0(location, rename_data_r2$old_sample_name[line]), recursive = TRUE)
  rm(line, new_sample_name_r2, old_sample_address_r2)
}
print('...R2 Renaming Complete')
print('[END] Script Complete')


