#!/bin/bash

set -euo pipefail

# ============================================================

# 02_convert_mitf_region.sh

#

# Purpose:

# Finish Stage A.

#

# This script:

# 1. Creates a bgzipped copy of the original dogs.vcf

# 2. Indexes the compressed VCF

# 3. Extracts the MITF region on chr20

# 4. Converts the MITF region to PLINK format

#

# Original VCF is NOT modified.

# ============================================================

# -----------------------------

# Paths

# -----------------------------

PROJECT_DIR="/media/caronelab/6TB_drive/Dog_Genome_Project/dog_mitf_gwas_project"
RAWVCF="/media/caronelab/6TB_drive/Dog_Genome_Project/dogs.vcf"
PROC="/media/caronelab/6TB_drive/Dog_Genome_Project/processed_data"

BGZVCF="$PROC/dogs.vcf.gz"
MITF_DIR="$PROC/mitf_test"
MITF_VCF="$MITF_DIR/mitf_test.vcf.gz"

THREADS=32

# -----------------------------

# Setup logging

# -----------------------------

cd "$PROJECT_DIR"
mkdir -p logs
mkdir -p "$PROC"
mkdir -p "$MITF_DIR"

LOG="logs/02_convert_mitf_region.log"
exec > >(tee "$LOG") 2>&1

echo "==================================================="
echo "Stage A: Compress/index VCF and test MITF region"
echo "==================================================="

echo ""
echo "Project directory:"
echo "$PROJECT_DIR"

echo ""
echo "Raw VCF:"
echo "$RAWVCF"

echo ""
echo "Processed data directory:"
echo "$PROC"

echo ""
echo "Using threads:"
echo "$THREADS"

echo ""
echo "Checking disk space:"
df -h /media/caronelab/6TB_drive

echo ""
echo "Checking required tools:"
bcftools --version | head -1
bgzip --help | head -1 || true
plink --version

# -----------------------------

# Step 1: Confirm raw VCF exists

# -----------------------------

echo ""
echo "==================================================="
echo "STEP 1: Confirm raw VCF exists"
echo "==================================================="

if [ ! -f "$RAWVCF" ]; then
echo "ERROR: Raw VCF not found:"
echo "$RAWVCF"
exit 1
fi

ls -lh "$RAWVCF"
file "$RAWVCF"

echo ""
echo "Counting samples in raw VCF:"
bcftools query -l "$RAWVCF" | wc -l

# -----------------------------

# Step 2: Compress VCF safely

# -----------------------------

echo ""
echo "==================================================="
echo "STEP 2: Create bgzipped copy of raw VCF"
echo "==================================================="

if [ -f "$BGZVCF" ]; then
echo "Compressed VCF already exists. Skipping compression."
ls -lh "$BGZVCF"
else
echo "Creating compressed copy:"
echo "$BGZVCF"
echo ""
echo "This may take a long time because the raw VCF is 1.8 TB."

```
time bgzip -@ "$THREADS" -c "$RAWVCF" > "$BGZVCF"

echo ""
echo "Compression finished."
ls -lh "$BGZVCF"
```

fi

echo ""
echo "Disk space after compression:"
df -h /media/caronelab/6TB_drive

# -----------------------------

# Step 3: Index compressed VCF

# -----------------------------

echo ""
echo "==================================================="
echo "STEP 3: Index compressed VCF"
echo "==================================================="

if [ -f "$BGZVCF.csi" ] || [ -f "$BGZVCF.tbi" ]; then
echo "Index already exists. Skipping indexing."
ls -lh "$BGZVCF"*
else
echo "Indexing compressed VCF:"
time bcftools index -c "$BGZVCF"

```
echo ""
echo "Indexing finished."
ls -lh "$BGZVCF"*
```

fi

echo ""
echo "Confirming compressed VCF sample count:"
bcftools query -l "$BGZVCF" | wc -l

echo ""
echo "Checking chr20:"
bcftools index -s "$BGZVCF" | grep chr20

# -----------------------------

# Step 4: Extract MITF region

# -----------------------------

echo ""
echo "==================================================="
echo "STEP 4: Extract MITF region"
echo "==================================================="

echo "MITF region:"
echo "chr20:21786368-21869849"

if [ -f "$MITF_VCF" ]; then
echo "MITF VCF already exists. Skipping extraction."
ls -lh "$MITF_VCF"
else
bcftools view 
-r chr20:21786368-21869849 
-Oz 
-o "$MITF_VCF" 
"$BGZVCF"

```
echo ""
echo "MITF extraction finished."
ls -lh "$MITF_VCF"
```

fi

if [ -f "$MITF_VCF.csi" ] || [ -f "$MITF_VCF.tbi" ]; then
echo "MITF VCF index already exists."
else
bcftools index -c "$MITF_VCF"
fi

echo ""
echo "MITF VCF files:"
ls -lh "$MITF_VCF"*

echo ""
echo "Number of variants in MITF region:"
MITF_VARIANTS=$(bcftools view -H "$MITF_VCF" | wc -l)
echo "$MITF_VARIANTS"

if [ "$MITF_VARIANTS" -eq 0 ]; then
echo "ERROR: MITF extraction returned 0 variants."
echo "Stop here and troubleshoot before continuing."
exit 1
fi

# -----------------------------

# Step 5: Convert MITF region to PLINK

# -----------------------------

echo ""
echo "==================================================="
echo "STEP 5: Convert MITF region to PLINK"
echo "==================================================="

if [ -f "$MITF_DIR/mitf_test.bed" ] && [ -f "$MITF_DIR/mitf_test.bim" ] && [ -f "$MITF_DIR/mitf_test.fam" ]; then
echo "MITF PLINK files already exist. Skipping conversion."
else
plink 
--vcf "$MITF_VCF" 
--make-bed 
--dog 
--allow-extra-chr 
--out "$MITF_DIR/mitf_test"
fi

echo ""
echo "MITF PLINK files:"
ls -lh "$MITF_DIR"/mitf_test.*

echo ""
echo "MITF .fam line count, expecting 722:"
wc -l "$MITF_DIR/mitf_test.fam"

echo ""
echo "MITF .bim variant count:"
wc -l "$MITF_DIR/mitf_test.bim"

echo ""
echo "First few MITF variants:"
head "$MITF_DIR/mitf_test.bim"

echo ""
echo "Final disk space:"
df -h /media/caronelab/6TB_drive

echo ""
echo "==================================================="
echo "DONE: Stage A MITF test complete"
echo "==================================================="
echo "Log saved to:"
echo "$LOG"
