# Dog MITF GWAS Project

This project aims to reproduce the published canine GWAS association between MITF and white spotting phenotypes, including white head and white chest/belly markings.

The analysis will use the Plassais et al. whole-genome sequencing VCF containing 722 canid genomes and approximately 91 million variants.

## Main goal

Run GWAS for:

- white head
- white chest / belly / ventral white spotting

Then check whether the strongest association signal appears near MITF on canine chromosome 20 around 21.8 Mb.

## Workflow

1. Inspect the VCF.
2. Test-convert the MITF region.
3. Merge sample metadata with phenotype data.
4. Convert the full VCF to PLINK format.
5. Build a kinship matrix.
6. Run GEMMA GWAS.
7. Plot results and check the MITF locus.

## Important note

Large genomic data files, including VCF, PLINK, and GWAS output files, should not be committed to GitHub.