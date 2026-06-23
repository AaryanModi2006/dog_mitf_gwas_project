#!/bin/bash

set -euo pipefail

# ============================================================

# 04_convert_full_vcf.sh

#

# Purpose:

# Stage B.

#

# This script converts the full compressed/indexed dog VCF

# into PLINK binary format.

#

# It assumes scripts/02_convert_mitf_region.sh has already

# created:

#

# /media/caronelab/6TB_drive/Dog_Genome_Project/processed_data/dogs.vcf.gz

#

# Original VCF is NOT modified.

# ============================================================

# -----------------------------

# Paths

# -----------------------------

PROJECT_DIR="/media/caronelab/6TB_drive/Dog_Genome_Project/dog_mitf_gwas_project"
PROC="/media/caronelab/6TB_drive/Dog_Genome_Project/processed_data"

BGZVCF="$PROC/dogs.vcf.gz"
PLINK_FULL_DIR="$PROC/plink_full"
FULL_PREFIX="$PLINK_FULL_DIR/dogs_full_maf01"

# -----------------------------

# Setup logging

# -----------------------------

cd "$PROJECT_DIR"
mkdir -p logs
mkdir -p "$PLINK_FULL_DIR"

LOG="logs/04_convert_full_vcf.log"
exec > >(tee "$LOG") 2>&1

echo "==================================================="
echo "Stage B: Full VCF to PLINK conversion"
echo "==================================================="

echo ""
echo "Project directory:"
echo "$PROJECT_DIR"

echo ""
echo "Compressed VCF:"
echo "$BGZVCF"

echo ""
echo "PLINK output prefix:"
echo "$FULL_PREFIX"

echo ""
echo "Checking disk space before full conversion:"
df -h /media/caronelab/6TB_drive

echo ""
echo "Checking required tools:"
plink --version
bcftools --version | head -1

# -----------------------------

# Step 1: Confirm compressed VCF exists

# -----------------------------

echo ""
echo "==================================================="
echo "STEP 1: Confirm compressed VCF exists"
echo "==================================================="

if [ ! -f "$BGZVCF" ]; then
echo "ERROR: Compressed VCF not found:"
echo "$BGZVCF"
echo ""
echo "Run scripts/02_convert_mitf_region.sh first."
exit 1
fi

if [ ! -f "$BGZVCF.csi" ] && [ ! -f "$BGZVCF.tbi" ]; then
echo "ERROR: Compressed VCF index not found."
echo "Run scripts/02_convert_mitf_region.sh first."
exit 1
fi

ls -lh "$BGZVCF"*

echo ""
echo "Confirming sample count:"
bcftools query -l "$BGZVCF" | wc -l

# -----------------------------

# Step 2: Full conversion

# -----------------------------

echo ""
echo "==================================================="
echo "STEP 2: Convert full VCF to PLINK"
echo "==================================================="

if [ -f "$FULL_PREFIX.bed" ] && [ -f "$FULL_PREFIX.bim" ] && [ -f "$FULL_PREFIX.fam" ]; then
echo "Full PLINK files already exist. Skipping conversion."
ls -lh "$FULL_PREFIX".*
else
echo "Starting full conversion."
echo "This may take a long time."

```
time plink \
  --vcf "$BGZVCF" \
  --make-bed \
  --dog \
  --allow-extra-chr \
  --biallelic-only strict \
  --maf 0.01 \
  --geno 0.01 \
  --out "$FULL_PREFIX"

echo ""
echo "Full conversion finished."
```

fi

# -----------------------------

# Step 3: Check output

# -----------------------------

echo ""
echo "==================================================="
echo "STEP 3: Check PLINK output"
echo "==================================================="

echo ""
echo "Full PLINK files:"
ls -lh "$FULL_PREFIX".*

echo ""
echo "Full .fam line count, expecting 722:"
wc -l "$FULL_PREFIX.fam"

echo ""
echo "Full .bim variant count:"
wc -l "$FULL_PREFIX.bim"

echo ""
echo "First few variants:"
head "$FULL_PREFIX.bim"

echo ""
echo "Checking disk space after full conversion:"
df -h /media/caronelab/6TB_drive

echo ""
echo "==================================================="
echo "DONE: Stage B full VCF conversion complete"
echo "==================================================="
echo "Log saved to:"
echo "$LOG"
