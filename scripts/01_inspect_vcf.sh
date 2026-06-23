#!/bin/bash
# 01_inspect_vcf.sh
# Stage A, part 1: inspect the VCF. Looks and reports only — never modifies the VCF.
#
# Run from the project root (DOG_MITF_GWAS_PROJECT):
#   bash scripts/01_inspect_vcf.sh 2>&1 | tee logs/01_inspect_log.txt

set -u  # stop on an unset variable — catches typos in filenames

# ---- EDIT THIS LINE: path to your VCF on the server ----
VCF=/media/caronelab/6TB_drive/Dog_Genome_Project/dogs.vcf
# --------------------------------------------------------

echo "### Inspecting: $VCF"; echo

echo "### 1. Are the tools available?"
bcftools --version | head -1
plink --version | head -1
echo

echo "### 2. Does the file exist, and what type is it really?"
if [ ! -f "$VCF" ]; then
    echo ">>> ERROR: not found at $VCF. Fix the path on the EDIT line."; exit 1
fi
ls -lh "$VCF"*
echo "file reports: $(file -b "$VCF")"
echo

echo "### 3. Is it indexed? (the next script needs this for fast extraction)"
if [ -f "${VCF}.tbi" ] || [ -f "${VCF}.csi" ]; then
    echo ">>> Index already present. Good."
else
    echo ">>> No index. Trying to make one (works only if the file is true bgzip)..."
    bcftools index "$VCF" && echo ">>> Indexed OK." \
        || echo ">>> Indexing FAILED — likely plain gzip, not bgzip. Bring this back to Claude."
fi
echo

echo "### 4. How many samples? (expecting 722)"
bcftools query -l "$VCF" | wc -l
echo

echo "### 5. First few sample IDs (we'll match these to the supplement later):"
bcftools query -l "$VCF" | head
echo

echo "### 6. How is chromosome 20 named? (look for '20' vs 'chr20')"
bcftools index -s "$VCF"
echo

echo "### 7. Assembly hint (hoping to see CanFam3.1):"
bcftools view -h "$VCF" | grep -iE "##reference|##contig=<ID=(chr)?20," | head
echo

echo "### DONE. Copy logs/01_inspect_log.txt back to Claude."