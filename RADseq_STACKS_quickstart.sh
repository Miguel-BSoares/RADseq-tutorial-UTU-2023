
PLEASE READ DOCUMENTATION ON WORKING IN THE UNIX COMMAND LINE BEFOREHAND
THE WALKTHROUGH IS DESIGNED FOR A MASTER-LEVEL DEGREE IN BIOINFORMATICS


All scripts written below required data files to be placed in the correct place. 
This is a very simple tutorial to perform the first steps of RADseq data, both with and without a reference genome.
Here we utilize STACKS, arguably the most commonly used software to analyze RADseq data from scratch - but there are of course other programs.
Many of the scripts utilized here have been adapted from STACKS manual, feel free to consult the manual and adapted them as you wish.

About the program STACKS:
https://catchenlab.life.illinois.edu/stacks/

Because we utilize shared computational resources provided by CSC, it is educated to learn about it before using it.
I strongly recommend to go through some tutorials to know how to navigate in the server, what commands to use, and general rules of conduct.

About the server CSC:
https://docs.csc.fi/

Basics of file, text manipulation and general navigation in the server:

1 - create files with "nano" command, which is basically a text editor
2 - create directories with "mkdir" command
3 - navigate in the server with "cd <DIRECTORY NAME>" to enter a directory and "cd .." to exit it.
4 - use "pwd" to know where you are
5 - use "cp" if you wish to copy files from one place to another. I.e., "cp <FILETOCOPY> <WHERETOCOPY>
6 - use tab to autocomplete. If does not autocomplete, it does not exist in that location.


The following lines constitute the headed of all .sh (bash script files) that will be utilized in this course:

"
#!/bin/bash -l
#SBATCH --job-name=bwa_mem
#SBATCH --output=bwa_mem_out
#SBATCH --error=bwa_mem_err
#SBATCH --time=72:00:00
#SBATCH --account=project_2005451
#SBATCH --mem-per-cpu=10000
#SBATCH --partition=large
#SBATCH --ntasks=80
"
Script files .sh are always submitted with the command sbatch <.SH FILENAME>
Ongoing jobs can be consulted with the command squeue -u <USERNAME>
The lines marked with "#" are not part of the code itself but rather instructions for the cluster to assign your jobs to different nodes.
It also allocates running time (--time) and memory (--mem-per-cpu) to a project (--account=project_2005451). 
It is advisable to adjust memory requirements to the job at hand, but at this stage there is no need to edit header´s parameters.
Finally, it produces log files of whatever you submitted and should be consulted for errors and outputs (--output; --error). 

To create a .sh file:

1- Type "nano" and paste the header
2- Paste the code
3- Exit saving with name, DO NOT FORGET TO ADD .sh as suffix.

---------------------------------STARTS HERE-----------------------
###This first script is utilized to map RADseq reads (.gz) to a reference genome (v5.fasta)
###It contains code to activate programs you  will use (module) and the actions to be performed (mkdir, etc)
###Please pay attention to the paths of where files are located, otherwise nothing will happen
###Do not forget to copy the header to the .sh file

"
module load gcc
module load bwa-mem2
module load samtools

mkdir -p aligned

files="942
943
944
926
955"

for sample in $files
do
        bwa-mem2 mem -t 10 /scratch/project_2005451/practical_radseq/genome/v5.fasta ${sample}_R1.fastq.gz ${sample}_R2.fastq.gz |
         samtools view -b |
         samtools sort --threads 10 > aligned/${sample}.bam
done
"
#Mapped reads can be visualized in any sort of genome viewer, such as IGV

https://software.broadinstitute.org/software/igv/download

#However, there is no information to be taken from visualization - at least at this stage.

###Second script is simply to check the mapping statistics of in each .bam files

"
module load samtools

for file in ./*bam
do
    filename=`basename $file`
    samplename=${filename%.bam}
    total_reads=`samtools view -c $file`
    mapped_reads=`samtools view -c -F 4 $file`
    unmapped_reads=`samtools view -c -f 4 $file`
    mapq_20=`samtools view -c -q 20 $file`
    percent_mapped=`bc <<< "scale = 3; ($mapped_reads/$total_reads)*100"`
    percent_mapq20=`bc <<< "scale = 3; ($mapq_20/$total_reads)*100"`     
    echo -e "$samplename\t$total_reads\t$mapped_reads\t$unmapped_reads\t$mapq_20\t$percent_mapped\t$percent_mapq20" >> bam.txt

done 
"
## Now that reads have been mapped to a genome, we will utilize STACKS to call variants
"
module load gcc
module load samtools
module load stacks

mkdir -p 01_gstacks

gstacks -I ./aligned  -M popmap -O 01_gstacks -t 20
"
##We can check the distribution of SNPs in the the created file .log files


---------------------DE NOVO ASSEMBLY-------------------------- 

###Now we will perform the first instances of RADseq assembly without a reference genome
###

module load gcc
module load samtools
module load stacks

mkdir -p 00_ustacks

i=1
for file in *.gz; do ustacks -i $i -t gzfastq -f $file -o 00_stacks -m 3 -M 4 -r; let "i+=1";
done

###You can play with the following parameters to verify how formation of stacks and coverage varies:
-m (number of reads to form a stack) 
-M (number of mismatches allowed to form a stack) 

##With this snippet you will be able to parse relevant information for each sample
##You can modify anything with ' ' to search for other string of characters
##Results will be passed on to a file name u_logs
##Note that log files might change and this the following command might not work. Change the contents of '/ /' accordingly. 

sed -nr '/Parsing|After remainders merged|Number of utilized reads/p' u_logfile >u_logs

###We can also utilize STACKS wrapper program denovo.pl to go through all the denovo assembly softwares

"
module load gcc
module load samtools
module load stacks

mkdir -p denovo

denovo_map.pl -M 3 -T 10 -o ./denovo --popmap popmap --samples ./samples --rm-pcr-duplicates --paired
"
##The denovo_map.log file contains all information


Post-hoc visualization and analyses continue in R. 
