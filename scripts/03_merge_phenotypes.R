#!/usr/bin/env Rscript
# 03_merge_phenotypes.R
# Stage C: build GEMMA phenotype + covariate files, aligned to .fam order.
#
# Reads:
#   - the full PLINK .fam (defines the 722 dogs AND their exact order)
#   - metadata/phenotype_lookup.tsv (VCF_ID -> breed, sex, white_head, white_chest)
# Writes (into processed_data/plink_full, next to the .fam):
#   - pheno_white_head.txt   (1 value per dog, GEMMA format, .fam order)
#   - pheno_white_chest.txt  (1 value per dog, GEMMA format, .fam order)
#   - covar_sex.txt          (intercept + sex, GEMMA covariate format, .fam order)
#
# GEMMA phenotype encoding used here: case = 1, control = 0, missing = NA
# (supplement codes were: case = 2, control = 1, not-used = NA)

# ---------- paths (edit only if your layout differs) ----------
proc_dir  <- "/media/caronelab/6TB_drive/Dog_Genome_Project/processed_data"
fam_file  <- file.path(proc_dir, "plink_full", "dogs_full_maf01.fam")
lookup    <- "metadata/phenotype_lookup.tsv"   # relative to project root
outdir    <- file.path(proc_dir, "plink_full")
# --------------------------------------------------------------

cat("### Reading .fam:", fam_file, "\n")
fam <- read.table(fam_file, header = FALSE, stringsAsFactors = FALSE)
# PLINK .fam columns: FID  IID  father  mother  sex  phenotype
colnames(fam)[1:2] <- c("FID", "IID")
cat("    dogs in .fam:", nrow(fam), "\n")

cat("### Reading lookup:", lookup, "\n")
lk <- read.table(lookup, header = TRUE, sep = "\t",
                 stringsAsFactors = FALSE, na.strings = "NA")
cat("    rows in lookup:", nrow(lk), "\n")

# ---------- match .fam IDs to the lookup, BY ID ----------
# The .fam's IID is the VCF sample id, which equals lookup$VCF_ID.
idx <- match(fam$IID, lk$VCF_ID)   # for each dog in .fam, its row in the lookup

n_missing <- sum(is.na(idx))
cat("\n### ID MATCH CHECK\n")
cat("    .fam dogs matched to lookup:", sum(!is.na(idx)), "/", nrow(fam), "\n")
if (n_missing > 0) {
  cat("    >>> WARNING:", n_missing, ".fam IDs had NO match in the lookup.\n")
  cat("    >>> First few unmatched IDs:\n")
  print(head(fam$IID[is.na(idx)], 10))
  stop("Unmatched IDs — stopping. Do NOT proceed until every dog matches.")
}
cat("    All dogs matched. Safe to proceed.\n")

# reorder the lookup into EXACT .fam order
lk_ord <- lk[idx, ]

# ---------- convert supplement codes -> GEMMA encoding ----------
# supplement: 2 = case, 1 = control, NA = not used
# GEMMA:      1 = case, 0 = control, NA = missing
recode <- function(x) ifelse(is.na(x), NA, ifelse(x == 2, 1, ifelse(x == 1, 0, NA)))

wh <- recode(lk_ord$white_head)
wc <- recode(lk_ord$white_chest)

# sex covariate: M/F -> numeric; GEMMA covariate file needs a leading intercept column of 1s
sex_num <- ifelse(lk_ord$Sex == "M", 1, ifelse(lk_ord$Sex == "F", 0, NA))

# ---------- write GEMMA files (no header, no IDs, .fam order) ----------
# phenotype files: one value per line
write.table(ifelse(is.na(wh), "NA", wh), file.path(outdir, "pheno_white_head.txt"),
            row.names = FALSE, col.names = FALSE, quote = FALSE)
write.table(ifelse(is.na(wc), "NA", wc), file.path(outdir, "pheno_white_chest.txt"),
            row.names = FALSE, col.names = FALSE, quote = FALSE)
# covariate file: column of 1s (intercept) + sex column
covar <- data.frame(intercept = 1, sex = sex_num)
write.table(covar, file.path(outdir, "covar_sex.txt"),
            row.names = FALSE, col.names = FALSE, quote = FALSE)

# ---------- validation report ----------
cat("\n### VALIDATION (should match the paper)\n")
cat("White head  -> cases:", sum(wh == 1, na.rm = TRUE),
    " controls:", sum(wh == 0, na.rm = TRUE),
    " (paper: 57 / 122)\n")
cat("White chest -> cases:", sum(wc == 1, na.rm = TRUE),
    " controls:", sum(wc == 0, na.rm = TRUE),
    " (paper: 100 / 95)\n")
cat("Sex covariate -> M:", sum(sex_num == 1, na.rm = TRUE),
    " F:", sum(sex_num == 0, na.rm = TRUE),
    " missing:", sum(is.na(sex_num)), "\n")
cat("\nFiles written to:", outdir, "\n")
cat("  pheno_white_head.txt, pheno_white_chest.txt, covar_sex.txt\n")
cat("### DONE\n")