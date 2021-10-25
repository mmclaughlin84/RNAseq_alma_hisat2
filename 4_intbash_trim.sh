#!/bin/bash
### Launch individual sbatch jobs
sample_names=$(find ./alignment_files/samples/ -name "[A-Z][0-9].fq.gz" -type f | sort | xargs -I{} dirname {} | uniq | sed -E "s/.\/(alignment_files)\/(samples)\/([A-Za-z0-9_-]*)/\3/g")
path='alignment_files/samples'
echo ${sample_names[@]}
echo 'path:'$path

for sample_name in ${sample_names[@]}; do
	sbatch --time=00:40:00 --job-name=trim --partition=compute --mail-type=END,FAIL --mail-user=mmclaughlin@icr.ac.uk --cpus-per-task=4 --mem-per-cpu=1000 --output=log4_trim_${sample_name}.txt \
		--wrap="source activate MMrnaseqenv; \
			echo $sample_name; \
				srun trimmomatic PE $path/$sample_name/R1.fq.gz $path/$sample_name/R2.fq.gz \
					$path/$sample_name/R1_trim.fq.gz $path/$sample_name/R1_unpaired.fq.gz \
						$path/$sample_name/R2_trim.fq.gz $path/$sample_name/R2_unpaired.fq.gz \
							LEADING:3 TRAILING:3 SLIDINGWINDOW:5:25 MINLEN:75"
done


