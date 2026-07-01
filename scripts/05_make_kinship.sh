#!/bin/bash
set -euo pipefail

# ============================================================
# 05_make_kinship.sh
# Stage D: build the GEMMA relatedness (kinship) matrix.
#
# Handles two things:
#  1. Strips the "chr" prefix (GEMMA needs numeric chromosomes),
#     working on a COPY so the Stage B output stays untouched.
#  2. Computes the centered relatedness matrix from genotypes.
#
# Kinship is computed from GENOTYPES only. The dummy phenotype
# added below is just so GEMMA runs; it does NOT affect the matrix.
# ============================================================

PROJECT_DIR="/media/caronelab/6TB_drive/Dog_Genome_Project/dog_mitf_gwas_project"
PROC="/media/caronelab/6TB_drive/Dog_Genome_Project/processed_data"

SRC_PREFIX="$PROC/plink_full/dogs_full_maf01"       # Stage B output (untouched)
GEMMA_DIR="$PROC/gemma"                              # everything GEMMA-related
NUM_PREFIX="$GEMMA_DIR/dogs_numchr"                  # chr-renamed copy
OUT_NAME="dogs_kinship"                              # kinship output name

cd "$PROJECT_DIR"
mkdir -p logs "$GEMMA_DIR"
LOG="logs/05_make_kinship.log"
exec > >(tee "$LOG") 2>&1

echo "==================================================="
echo "Stage D: Kinship matrix  —  started $(date)"
echo "==================================================="

# ---- Confirm Stage B inputs exist ----
for ext in bed bim fam; do
  if [ ! -f "$SRC_PREFIX.$ext" ]; then
    echo "ERROR: missing $SRC_PREFIX.$ext — is Stage B output in place?"; exit 1
  fi
done
echo "Found Stage B fileset: $SRC_PREFIX.{bed,bim,fam}"

# ---- Step 1: make a chr-stripped COPY (original stays untouched) ----
echo ""
echo "### Step 1: copy fileset and strip 'chr' prefix from chromosome names"
cp "$SRC_PREFIX.bed" "$NUM_PREFIX.bed"
cp "$SRC_PREFIX.fam" "$NUM_PREFIX.fam"
# chromosome names live ONLY in the .bim (col 1); .bed is binary and unaffected.
sed 's/^chr//' "$SRC_PREFIX.bim" > "$NUM_PREFIX.bim"

echo "Before (original .bim, first line):"; head -1 "$SRC_PREFIX.bim"
echo "After  (renamed  .bim, first line):"; head -1 "$NUM_PREFIX.bim"

# ---- Step 2: give the copy a dummy phenotype so GEMMA will run ----
# GEMMA refuses to run if the .fam phenotype (col 6) is all missing.
# We set col 6 to 1 for every dog. This does NOT affect the kinship matrix,
# which is computed from genotypes only.
echo ""
echo "### Step 2: set a dummy phenotype in the copied .fam (kinship-only)"
awk '{ $6 = 1; print }' "$NUM_PREFIX.fam" > "$NUM_PREFIX.fam.tmp" && mv "$NUM_PREFIX.fam.tmp" "$NUM_PREFIX.fam"
echo "Copied .fam first line now:"; head -1 "$NUM_PREFIX.fam"

# ---- Step 3: compute the centered relatedness matrix ----
echo ""
echo "### Step 3: run GEMMA -gk 1 (centered relatedness matrix)"
echo "This is a real computation over all variants; may take minutes to a couple hours."
gemma \
  -bfile "$NUM_PREFIX" \
  -gk 1 \
  -outdir "$GEMMA_DIR" \
  -o "$OUT_NAME"

# ---- Step 4: confirm output ----
echo ""
echo "### Step 4: check kinship output"
KIN="$GEMMA_DIR/${OUT_NAME}.cXX.txt"
if [ -f "$KIN" ]; then
  echo "Kinship matrix written: $KIN"
  ROWS=$(wc -l < "$KIN")
  COLS=$(head -1 "$KIN" | wc -w)
  echo "Matrix dimensions: $ROWS rows x $COLS cols  (expecting 722 x 722)"
else
  echo "ERROR: expected kinship file not found: $KIN"; exit 1
fi

echo ""
echo "==================================================="
echo "DONE: Stage D kinship matrix complete  —  $(date)"
echo "Kinship matrix: $KIN"
echo "==================================================="