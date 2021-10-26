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
# Navigate to group RDS folder /<group_name>/<user_name>/
```

mkdir -p 