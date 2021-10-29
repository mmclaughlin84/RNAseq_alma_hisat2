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

## Obtaining FASTQ files


If sequencing carried out by TPU, have files transfered to **SHARED** folder on RDS move to correct location. If using genewiz download files by connecting to sftp using the following instructions.

```sh
# Connect using sftp and enter password (may require two attempts)
sftp <user_name>@gweusftp.brooks.com

# List the files, or navigate about to check directory structure
ls -lh
cd <directory_name>

# Set ‘local directory’, ie where on your computer to download the folder to - Use lls to confirm location is as expected
lcd /Volumes/DATA/DRI/URTHY/TARGTHER/<user_name>/
lls

# start transfer with flags: -r recursive and -a attempt to resume partial transfers of existing files 
mget -ra <directory_name>

# If files fail to transfer, repeat the above line
# exit sftp
exit

```
MMnote: Need to add directory checksum (conda install checksum)

## Setup RDS Project Folder

Now that fastq files are avilable, setup the following project folder structure using the following code.

```sh
# Navigate to group RDS folder /Volumes/DATA/DRI/URTHY/<group_name>/<user_name>/
# Use mkdir to make subfolders
mkdir -p alignment_files/{samples,indexes}

gh repo clone mmclaughlin84/RNAseq_alma_hisat2
curl -LJO https://github.com/mmclaughlin84/RNAseq_alma_hisat2/1_Rstudio_rename.R
curl https://github.com/mmclaughlin84/RNAseq_alma_hisat2.git
```

## Alignment Pipeline

Login to ALMA













