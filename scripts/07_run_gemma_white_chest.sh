#!/bin/bash
set -euo pipefail

# ============================================================
# 07_run_gemma_white_chest.sh
# Stage E (part 2): GWAS for the WHITE CHEST phenotype.
# Same setup as script 06, using the white-chest phenotype.
# ============================================================

PROJECT_DIR="/media/caronelab/6TB_drive/Dog_Genome_Project/dog_mitf_gwas_project"
PROC="/media/caronelab/6TB_drive/Dog_Genome_Project/processed_data"

GEMMA_DIR="$PROC/gemma"
GENO_PREFIX="$GEMMA_DIR/dogs_numchr"
KINSHIP="$GEMMA_DIR/dogs_kinship.cXX.txt"
PHENO="$PROC/plink_full/pheno_white_chest.txt"
COVAR="$PROC/plink_full/covar_sex.txt"
OUT_NAME="white_chest_gwas"

cd "$PROJECT_DIR"
mkdir -p logs
LOG="logs/07_run_gemma_white_chest.log"
exec > >(tee "$LOG") 2>&1

echo "==================================================="
echo "Stage E: WHITE CHEST GWAS  —  started $(date)"
echo "==================================================="

echo "### Checking inputs"
for f in "$GENO_PREFIX.bed" "$GENO_PREFIX.bim" "$GENO_PREFIX.fam" "$KINSHIP" "$PHENO" "$COVAR"; do
  if [ ! -f "$f" ]; then
    echo "ERROR: missing input: $f"
    echo ">>> Make sure scripts 03 and 05 both finished successfully first."
    exit 1
  fi
  echo "  found: $f"
done

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

echo ""
echo "### Running GEMMA association (the GWAS itself)"
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

echo ""
echo "### MITF region preview — strongest hits near chr20:21.78-21.87 Mb"
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
echo "DONE: White chest GWAS complete  —  $(date)"
echo "Results: $ASSOC"
echo "==================================================="