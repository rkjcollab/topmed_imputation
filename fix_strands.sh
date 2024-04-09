#!/bin/bash

#Set arguments
if [ "$#" -eq  "0" ]
then
    echo "Usage: ${0##*/} <pre_qc_dir> <post_qc_dir> <code_dir> <chr>"
    echo "Script uses output from TOPMed pre-imputation QC to fix strand"
    echo "flips. If "chr" input = "all", then the script will create one"
    echo "VCF file per chr. Otherwise, must be a single chr number '1',"
    echo "'2', etc. Crossover is from hg19 to hg38, this script should"
    echo "follow create_initial_input with crossover."
    exit
fi

pre_qc_dir=$1
post_qc_dir=$2
code_dir=$3
chr=$4


#Get list of SNPs to flip
Rscript --vanilla ${code_dir}/get_strand_flip_snp_names.R $pre_qc_dir $post_qc_dir

#Create vcf files for uploading to imputation server for QC
#Note that the encoding for chromosome is e.g. chr22, not 22
# If chr = "all", then create one VCF file per chr, otherwise
# chr must equal one chr number, so only make that VCF file
if [ "$chr" == "all" ]
then
    for ((chr=1; chr<=22; chr++)); do
        plink --bfile ${pre_qc_dir}/pre_qc \
            --flip ${post_qc_dir}/tmp_flip.txt \
            --chr $chr --recode vcf \
            --out ${post_qc_dir}/tmp_chr${chr}
        vcf-sort ${post_qc_dir}/tmp_chr${chr}.vcf | \
            sed -E 's/^([[:digit:]]+)/chr\1/' | \
            bgzip -c > ${post_qc_dir}/chr${chr}_post_qc.vcf.gz
    done
else
    plink --bfile ${pre_qc_dir}/pre_qc \
            --flip ${post_qc_dir}/tmp_flip.txt \
            --chr $chr --recode vcf \
            --out ${post_qc_dir}/tmp_chr${chr}
        vcf-sort ${post_qc_dir}/tmp_chr${chr}.vcf | \
            sed -E 's/^([[:digit:]]+)/chr\1/' | \
            bgzip -c > ${post_qc_dir}/chr${chr}_post_qc.vcf.gz
fi

#Cleanup
rm ${post_qc_dir}/tmp_*
