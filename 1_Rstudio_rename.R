### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### 
### WRANGLING FASTQ FILES TO RIGHT STRUCTURE -------------------------------------------------
### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### 

#setwd(dirname(rstudioapi::getSourceEditorContext()$path)) # this will set the working directory based on script location
setwd("/Volumes/DATA/DRI/URTHY/TARGTHER/mmclaughlin/alma_testing/") # or manually
getwd() # to check

# Script generates the sample_names.csv file and wrangles fastq files into the current folder structure for next steps
# NOTE: sample_names.csv has a double use for 1_bash_Rscript_rename.R and colData in 1_DESeq.R

# old_sample_name         = a shorthand code provided to genewiz or the TPU that is extracted using the code below
# sample_names            = {experimentID}_{model}_{sampleID}_{timepoint}_{treatment}_{replicate} # NOTE: do not use hyphens
# treatment_wo_timepoint  = vehicle/PD1/RT/RT_PD1/etc
# timepoint               = 14d/21d, injected/contralateral, wt/KO, etc
# treatment               = 14d_vehicle/14d_PD1/21d_vehicle/21d_PD1/etc (NOTE: timepoint BEFORE treatment)

# list files using pattern to match only fastq files
list.files(pattern = 'q.gz$', recursive = TRUE) # check here, then used in line below to make dataframe
file_list <- data.frame(old_address = list.files(pattern = 'q.gz', recursive = TRUE))

# Split file list into two columns for R1 and R2 files separately and extract old sample name with regular expression and gsub
# These regular expression may need to be adjusted to extract the "old_sample_name"
# alignment_files/samples/old_sample_name/R1R2_files
# alignment_files/samples/old_sample_name_R1R2_files
rename_details <- data.frame(R1_files = file_list[grepl('R1', file_list$old_address), ])
rename_details$R2_files <- file_list[grepl('R2', file_list$old_address), ]
rename_details$old_sample_name <- gsub('alignment_files/samples/([A-Za-z0-9_-]*)/[A-Za-z0-9_-]*.[fastq]*.gz', '\\1', rename_details$R1_files)


### THIS SECTION SAVES A TEMPLATE FOR 'sample_names.csv' ###
template <- rename_details[ ,c('old_sample_name'), drop = FALSE]
template$sample_name <- ''
template$treatment_wo_timepoint <- ''
template$timepoint <- ''
template$treatment <- ''
write.csv(template, file = 'sample_names_template.csv', row.names = FALSE)
### GO RENAME "sample_names_template.csv" TO "sample_names.csv" AND POPULATE IT ###
suppressWarnings(file.remove('sample_names_template.csv'))

# Import sample_names.csv, merge with rename_details
sample_names <- read.csv('sample_names.csv')
rename_details <- merge(rename_details, sample_names, by = 'old_sample_name', all = TRUE)
rm(sample_names, file_list, template)

# STOPPED HERE

# Order by sample_name as it makes the print() in the for loops easier to follow
rename_details <- rename_details[order(rename_details$sample_name), ]

# Save tracking files
write.csv(rename_details, file = 'alignment_files/samples/tracking_rscript.csv')

# PROGRESSION: 2 loops - 1st for R1 files, 2nd for R2 files
# [Loop 1]
# 1) create new folder based on $sample_name
# 2) 'renaming' R1 file a) moves it to sample_name folder b) changes file name to R1.fq.gz (NOTE: .fq.gz not fastq.qz)
# 3) save txt file as QC, allowing the R1 renaming process to be tracked in case a mistake is identified later
# [Loop 2]
# 1) new folder based on $sample_name already created by R1 loop above
# 2) rename R2 file a) moving to sample_name folder b) changing file name to R2.fq.gz (NOTE: .fq.gz not fastq.qz)
# 3) save txt file as QC, allowing the R2 renaming process to be tracked in case a mistake is identified later
# 4) $old_file_name folder is now empty, delete to remove

location = 'alignment_files/samples/' # this makes the code below a little tidier

# Loop 1 [R1 RENAMING - START]
for (row in 1:nrow(rename_details_R1)) {
  new_sample_name_R1 <- rename_details_R1$sample_name[row] # create sample_name variable based on subsetting by row
  print(paste0('Creating Directory: ', new_sample_name_R1)) # prints to console to allow tracking for loop 
  dir.create(paste0(location, new_sample_name_R1)) # create new directory based on new sample name variable
  old_sample_address_R1 <- rename_details_R1$old_address[row] # create old_sample_address variable based on subsetting by row
  print(paste0('Renaming: ', old_sample_address_R1, ' >>> ', paste0(location, new_sample_name_R1, '/', 'R1.fq.gz'))) # prints to console to allow tracking for loop 
  file.rename(old_sample_address_R1, paste0(location, new_sample_name_R1, '/', 'R1.fq.gz')) # 'move' by renaming old file, to new sample folder with fixed R1.fq.gz name
  cat(old_sample_address_R1, file=paste0(location, new_sample_name_R1, '/', 'R1_oldname.txt')) # save using cat the old file address for QC tracking
  rm(row, new_sample_name_R1, old_sample_address_R1) # remove variables to tidy
}

# Loop 2 [R2 RENAMING - START]
for (row in 1:nrow(rename_details_R2)) {
  new_sample_name_R2 <- rename_details_R2$sample_name[row] # create R2 new sample name object
  old_sample_address_R2 <- rename_details_R2$old_address[row] # create R2 old fastq file address
  print(paste0('Renaming: ', old_sample_address_R2, ' >>> ', paste0(location, new_sample_name_R2, '/', 'R2.fq.gz'))) # print renaming details to allowing tracking for loop
  file.rename(old_sample_address_R2, paste0(location, new_sample_name_R2, '/', 'R2.fq.gz')) # file 'move' by renaming old fastq address to new sample name location
  cat(old_sample_address_R2, file=paste0(location, new_sample_name_R2, '/', 'R2_oldname.txt')) # save using cat the old file address for QC tracking
  print(paste0('Deleting Directory: ', paste0(location, rename_details_R2$old_sample_name[row]))) # print deletion of directory to allow tracking for loop
  # Note: this final line assumes there is an old sample name folder to delete, there may not be, and this line may need silenced
  unlink(paste0(location, rename_details_R2$old_sample_name[row]), recursive = TRUE) # using 'unlink' to delete old_sample_name folder
  rm(row, new_sample_name_R2, old_sample_address_R2) # remove variables to tidy
}

