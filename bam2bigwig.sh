#!/bin/bash

## $1 is indicated as the input direcetory and $2 is indicated as the output directory
## The script should be run the following ./bam2bigwig.sh $1 $2

# Check for correct number of arguments
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <input_directory> <output_directory>"
    exit 1
fi

# Assign arguments to variables
input_dir="$1"
output_dir="$2"


# Create output directory if it doesn't exist
mkdir -p "$output_dir"

# Create log file
log_file="$output_dir/conversion_log.txt"
touch "$log_file"

# Create Conda environment and activate it
source $(dirname $(dirname $(which mamba)))/etc/profile.d/conda.sh
mamba create -n bam2bigwig --yes 
conda activate bam2bigwig
conda install -c bioconda deeptools samtools --yes

# Index BAM files in the temporary directory
for bam_file in "$input_dir"/*.bam; do
    if [ -e "$bam_file" ]; then
        bam_file_name=$(basename "$bam_file" .bam)
        nice samtools index "$bam_file" "$input_dir/${bam_file_name}.bai"
    fi
done

# Convert indexed BAM files to BigWig format
for indexed_bam_file in "$input_dir"/*.bai; do
    if [ -e "$indexed_bam_file" ]; then
        bam_file_name=$(basename "$indexed_bam_file" .bai)
        bigwig="$output_dir/${bam_file_name}.bw"
        nice bamCoverage -b "$input_dir/$bam_file_name.bam" -o "$bigwig" &>> "$log_file"
        echo "Converted $bam_file_name to $(basename "$bigwig")" >> "$log_file"
    fi
done


# Remove intermediary files and folders
conda deactivate
conda env remove -n bam2bigwig --yes
rm -rf "$output_dir/tmp"

# Print your name to the terminal
echo "Script executed by Raoul"
