#!/bin/bash
set -euo pipefail

# ============================================================
# 06_run_gemma_white_head.sh
# Stage E (part 1): GWAS for the WHITE HEAD phenotype.
#
# Runs GEMMA's linear mixed model using:
#   - genotypes with numeric chromosomes (from script 05)
#   - the white-head phenotype (from script 03)
#   - sex as a covariate (from script 03)
#   - the kinship matrix (from script 05)
# Matches the paper: LMM, sex covariate, relatedness matrix, Wald test.
# ============================================================

PROJECT_DIR="/media/caronelab/6TB_drive/Dog_Genome_Project/dog_mitf_gwas_project"
PROC="/media/caronelab/6TB_drive/Dog_Genome_Project/processed_data"

GEMMA_DIR="$PROC/gemma"
GENO_PREFIX="$GEMMA_DIR/dogs_numchr"                 # numeric-chr genotypes (script 05)
KINSHIP="$GEMMA_DIR/dogs_kinship.cXX.txt"           # kinship matrix (script 05)
PHENO="$PROC/plink_full/pheno_white_head.txt"       # phenotype (script 03)
COVAR="$PROC/plink_full/covar_sex.txt"              # sex covariate (script 03)
OUT_NAME="white_head_gwas"

cd "$PROJECT_DIR"
mkdir -p logs
LOG="logs/06_run_gemma_white_head.log"
exec > >(tee "$LOG") 2>&1

echo "==================================================="
echo "Stage E: WHITE HEAD GWAS  —  started $(date)"
echo "==================================================="

# ---- Confirm every input exists before running ----
echo "### Checking inputs"
for f in "$GENO_PREFIX.bed" "$GENO_PREFIX.bim" "$GENO_PREFIX.fam" "$KINSHIP" "$PHENO" "$COVAR"; do
  if [ ! -f "$f" ]; then
    echo "ERROR: missing input: $f"
    echo ">>> Make sure scripts 03 and 05 both finished successfully first."
    exit 1
  fi
  echo "  found: $f"
done

# ---- Sanity: phenotype rows must equal number of dogs in .fam ----
NFAM=$(wc -l < "$GENO_PREFIX.fam")
NPHE=$(wc -l < "$PHENO")
NCOV=$(wc -l < "$COVAR")
echo ""
echo "### Row-count consistency (all must equal $NFAM)"
echo "  .fam dogs:      $NFAM"
echo "  phenotype rows: $NPHE"
echo "  covariate rows: $NCOV"
if [ "$NFAM" -ne "$NPHE" ] || [ "$NFAM" -ne "$NCOV" ]; then
  echo "ERROR: row counts don't match — phenotype/covariate not aligned to genotypes."
  exit 1
fi
echo "  OK — all aligned."

# ---- Run GEMMA association (LMM, Wald test = -lmm 1) ----
echo ""
echo "### Running GEMMA association (this is the GWAS itself)"
gemma \
  -bfile "$GENO_PREFIX" \
  -p "$PHENO" \
  -c "$COVAR" \
  -k "$KINSHIP" \
  -lmm 1 \
  -outdir "$GEMMA_DIR" \
  -o "$OUT_NAME"

ASSOC="$GEMMA_DIR/${OUT_NAME}.assoc.txt"
echo ""
echo "### Association output: $ASSOC"
if [ ! -f "$ASSOC" ]; then
  echo "ERROR: expected results file not found."; exit 1
fi
echo "Total variants tested:"; wc -l < "$ASSOC"

# ---- Preview the MITF region (chr20:21,786,368-21,869,849, now numeric '20') ----
echo ""
echo "### MITF region preview — strongest hits near chr20:21.78-21.87 Mb"
echo "### (columns include: chr  rs  ps ... p_wald as the LAST column)"
head -1 "$ASSOC"
awk 'NR>1 && $1==20 && $3>=21786368 && $3<=21869849' "$ASSOC" \
  | sort -g -k $(head -1 "$ASSOC" | awk '{print NF}') \
  | head -10

echo ""
echo "### Overall top 10 most-associated variants genome-wide:"
head -1 "$ASSOC"
awk 'NR>1' "$ASSOC" | sort -g -k $(head -1 "$ASSOC" | awk '{print NF}') | head -10

echo ""
echo "==================================================="
echo "DONE: White head GWAS complete  —  $(date)"
echo "Results: $ASSOC"
echo "==================================================="