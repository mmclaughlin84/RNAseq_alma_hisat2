### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### 
### WRANGLING FASTQ FILES TO RIGHT STRUCTURE -------------------------------------------------
### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### 

setwd(dirname(rstudioapi::getSourceEditorContext()$path)) # this will set the working directory based on script location
setwd("/Volumes/DATA/DRI/URTHY/TARGTHER/mmclaughlin/alma_testing/") # or manually
getwd() # to check

# Script generates the sample_names.csv file and wrangles fastq files into the current folder structure for next steps
# NOTE: sample_names.csv has a double use for this scrip and for the colData file for DESeq2

# old_sample_name         = a shorthand code provided to genewiz or the TPU that is extracted using the code below
# sample_names            = {experimentID}_{model}_{sampleID}_{timepoint}_{treatment}_{replicate} # NOTE: do not use hyphens
# treatment_wo_timepoint  = vehicle/PD1/RT/RT_PD1/etc
# timepoint               = 14d/21d, injected/contralateral, wt/KO, etc
# treatment               = vehicle_14d/PD1_14d/vehicle_21d/PD1_21d/etc (NOTE: timepoint AFTER treatment - it is critical for DESeq script!)

# list files using pattern to match only fastq files
# Use grepl to create columns containing R1 and R2 files
list.files(pattern = 'q.gz$', recursive = TRUE) # check here, then used in line below to make dataframe
file_list <- data.frame(old_address = list.files(pattern = 'q.gz', recursive = TRUE))
rename_details <- data.frame(R1_files = file_list[grepl('R1', file_list$old_address), ])
rename_details$R2_files <- file_list[grepl('R2', file_list$old_address), ]

# Use gsub to extract old sample name and place in new column
rename_details$old_sample_name <- gsub('alignment_files/samples/([A-Za-z0-9_-]*)/[A-Za-z0-9_-]*.[fastq]*.gz', '\\1', rename_details$R1_files)
rename_details

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
rm(sample_names, template, file_list) # tidying environment

# Order by sample_name as it makes the print() in the for loop below easier to follow
rename_details <- rename_details[order(rename_details$sample_name), ]

# Save tracking file
write.csv(rename_details, file = 'alignment_files/samples/tracking_rscript.csv')

# RENAMING/MOVE LOOP PROGRESSION:
# 1) create new folder based on new sample name provided
# 2) 'renaming' R1 file a) moves it to sample_name folder b) changes file name to R1.fq.gz (NOTE: .fq.gz not fastq.qz)
# 3) save txt file as QC, allowing the R1 renaming process to be tracked in case a mistake is identified later
# 4) rename R2 file a) moving to sample_name folder b) changing file name to R2.fq.gz (NOTE: .fq.gz not fastq.qz)
# 5) save txt file as QC, allowing the R2 renaming process to be tracked in case a mistake is identified later
# 6) $old_file_name folder is now empty, delete to remove

for (row in 1:nrow(rename_details)) {
  print(paste0('Row Number: ', row))
  # Creating New Sample Name Folder
  new_sample_name <- rename_details$sample_name[row] # create sample_name variable based on subsetting by row
  print(paste0('Creating Directory: ', new_sample_name)) # prints to console to allow tracking for loop
  dir.create(paste0('alignment_files/samples/', new_sample_name)) # create new directory based on new sample name variable
  old_sample_address_R1 <- rename_details$R1_files[row] # create old_sample_address variable based on subsetting by row
  # Renaming R1
  print(paste0('Renaming: ', old_sample_address_R1, ' >>> ', 'alignment_files/samples/', new_sample_name, '/R1.fq.gz')) # prints to console to allow tracking for loop 
  file.rename(old_sample_address_R1, paste0('alignment_files/samples/', new_sample_name, '/R1.fq.gz')) # 'move' by renaming old file, to new sample folder with fixed R1.fq.gz name
  cat(old_sample_address_R1, file=paste0('alignment_files/samples/', new_sample_name, '/R1_oldname.txt')) # save using cat the old file address for QC tracking
  # Renaming R2
  old_sample_address_R2 <- rename_details$R2_files[row] # create R2 old fastq file address
  print(paste0('Renaming: ', old_sample_address_R2, ' >>> ', 'alignment_files/samples/', new_sample_name, '/R2.fq.gz')) # prints to console to allow tracking for loop 
  file.rename(old_sample_address_R2, paste0('alignment_files/samples/', new_sample_name, '/R2.fq.gz')) # 'move' by renaming old file, to new sample folder with fixed R1.fq.gz name
  cat(old_sample_address_R2, file=paste0('alignment_files/samples/', new_sample_name, '/R2_oldname.txt')) # save using cat the old file address for QC tracking
  # Delete Old Sample Name Folder
  # Note: the final line assumes there is an old sample name folder to delete, there may not be, and this line may need silenced
  print(paste0('Deleting Directory: ', 'alignment_files/samples/', rename_details$old_sample_name[row])) # print deletion of directory to allow tracking for loop
  unlink(paste0('alignment_files/samples/', rename_details$old_sample_name[row]), recursive = TRUE) # using 'unlink' to delete old_sample_name folder
  rm(new_sample_name, old_sample_address_R1, old_sample_address_R2, row)
}



