#!/bin/bash

###########################################
# [STEP 6: ALIGN w/ HISAT2-STRINGTIE]
###########################################

### Launch individual sbatch jobs for hisat2-samtools-stringtie
### parse sample names from folder using find _trim.fq.gz, sort, sed and uniq used to extract sample name
sample_names=$(find . -name "*_trim.fq.gz" -type f | sort | sed -E "s/.\/(alignment_files)\/(samples)\/([A-Za-z0-9_-]+)\/(.*)/\3/g" | uniq)
echo ${sample_names[@]}

### SOURCE LINKS
### M. musculus NCBI GRCm38 Index From HISAT2 website
### https://cloud.biohpc.swmed.edu/index.php/s/grcm38/download
### GTF 
### ftp://ftp.ensembl.org/pub/release-102/gtf/mus_musculus
### ftp://ftp.ensembl.org/pub/release-102/gtf/mus_musculus/Mus_musculus.GRCm38.102.gtf.gz
reference_genome=alignment_files/indexes/genome
reference_gtf=alignment_files/indexes/Mus_musculus.GRCm38.102.gtf
echo $reference_genome
echo $reference_gtf

# single sbatch job for each individual PE sample
for sample_name in ${sample_names[@]}
  do
    sbatch --time=03:00:00 --job-name=align --partition=compute --mail-type=END,FAIL --mail-user=mmclaughlin@icr.ac.uk --cpus-per-task=8 --mem-per-cpu=4000 --output=log6_align_${sample_name}.txt \
		--wrap="echo 'Sample_Name:'${sample_name}; echo 'SLURM_CPUS:'\$SLURM_CPUS_PER_TASK; module load SAMtools anaconda/3; source activate MMrnaseqenv; \
			date; \
				srun hisat2 -p \$SLURM_CPUS_PER_TASK --dta -x $reference_genome -1 alignment_files/samples/${sample_name}/R1_trim.fq.gz -2 alignment_files/samples/${sample_name}/R2_trim.fq.gz -S ${sample_name}.sam; \
					date; \
						srun samtools sort -@ \$SLURM_CPUS_PER_TASK -o ${sample_name}.bam ${sample_name}.sam; \
							date; \
								srun stringtie -e -B -p \$SLURM_CPUS_PER_TASK -G $reference_gtf -o ballgown/${sample_name}/${sample_name}.gtf ${sample_name}.bam; \
									date; \
										rm ${sample_name}.sam"
done

