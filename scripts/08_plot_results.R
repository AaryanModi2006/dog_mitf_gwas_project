#!/usr/bin/env Rscript
# 08_plot_results.R
# Makes a Manhattan plot from a GEMMA .assoc.txt file, using base R only
# (no extra packages to install). Also highlights the MITF region and prints
# the strongest hits there.
#
# Usage (the runner script passes these two arguments):
#   Rscript scripts/08_plot_results.R <assoc_file> <output_png>

args <- commandArgs(trailingOnly = TRUE)
if (length(args) < 2) {
  stop("Need 2 arguments: <assoc_file> <output_png>")
}
assoc_file <- args[1]
out_png    <- args[2]

cat("### Reading:", assoc_file, "\n")
d <- read.table(assoc_file, header = TRUE, stringsAsFactors = FALSE)

# GEMMA assoc columns include: chr, rs, ps, ... p_wald
# Keep only what we need and drop any rows with missing p-values.
d <- d[, c("chr", "ps", "p_wald")]
d <- d[!is.na(d$p_wald) & d$p_wald > 0, ]
d$logp <- -log10(d$p_wald)

# chromosomes should be numeric now (script 05 stripped 'chr'); coerce safely
d$chr <- suppressWarnings(as.numeric(d$chr))
d <- d[!is.na(d$chr), ]
d <- d[order(d$chr, d$ps), ]

# ---- build a cumulative x-position so chromosomes sit side by side ----
chroms <- sort(unique(d$chr))
offset <- 0
d$xpos <- NA_real_
ticks <- numeric(length(chroms))
for (i in seq_along(chroms)) {
  c <- chroms[i]
  sel <- d$chr == c
  d$xpos[sel] <- d$ps[sel] + offset
  ticks[i] <- offset + (max(d$ps[sel]) / 2)
  offset <- offset + max(d$ps[sel]) + 1e6   # small gap between chromosomes
}

# Bonferroni threshold the paper used (~8.46 on -log10 scale)
thresh <- 8.46

# ---- draw ----
cat("### Writing plot:", out_png, "\n")
png(out_png, width = 1600, height = 600)
cols <- ifelse(d$chr %% 2 == 0, "grey40", "grey70")
plot(d$xpos, d$logp, pch = 20, cex = 0.4, col = cols,
     xlab = "Chromosome", ylab = "-log10(p)", xaxt = "n",
     main = basename(assoc_file))
axis(1, at = ticks, labels = chroms, cex.axis = 0.7)
abline(h = thresh, col = "red", lty = 2)

# highlight the MITF region on chr20 in red
mitf <- d$chr == 20 & d$ps >= 21786368 & d$ps <= 21869849
points(d$xpos[mitf], d$logp[mitf], pch = 20, cex = 0.9, col = "red")
invisible(dev.off())

# ---- report the MITF peak in text ----
cat("\n### Strongest hits in the MITF region (chr20:21,786,368-21,869,849):\n")
m <- d[mitf, ]
if (nrow(m) == 0) {
  cat("  (no variants in the MITF window — check chromosome naming)\n")
} else {
  m <- m[order(-m$logp), ]
  print(head(data.frame(chr = m$chr, pos = m$ps,
                        p_wald = signif(m$p_wald, 3),
                        neg_log10p = round(m$logp, 2)), 10), row.names = FALSE)
  cat("\n  Best MITF-region -log10(p):", round(max(m$logp), 2),
      " (genome-wide threshold is", thresh, ")\n")
  cat("  Above threshold?", ifelse(max(m$logp) >= thresh, "YES — reproduces the peak", "no"), "\n")
}
cat("### DONE\n")