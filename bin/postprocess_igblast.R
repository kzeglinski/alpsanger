#!/usr/bin/env Rscript
# bin/postprocess_igblast.R
#
# Reads merged IgBLAST AIRR-format TSV output and writes an Excel workbook
# matching Amy's requested column layout:
#
#  A: Nb name
#  B: CDR3 AA seq
#  C: Full AA seq
#  D: CDR3 Cluster_size (#clones in clonal group)
#  E: CDR1 AA sequence
#  F: CDR2 AA sequence
#  G: FR1 AA sequence
#  H: FR2 AA sequence
#  I: FR3 AA sequence
#  J: FR4 AA sequence
#  K: NT sequence
#
# AIRR column reference: https://docs.airr-community.org/en/stable/datarep/rearrangements.html

suppressPackageStartupMessages({
  library(openxlsx)
  library(dplyr)
  library(stringr)
  library(readr)
  library(CellaRepertorium)
})

# ── Read IgBLAST AIRR output ──────────────────────────────────────────────────
airr <- read_tsv("combined_igblast.tsv")

# ── Map AIRR columns → template columns ──────────────────────────────────────
# AIRR field names used:
#  sequence_id      → Nb name
#  cdr3_aa          → CDR3 AA seq
#  sequence_aa      → Full AA seq
#  cdr1_aa          → CDR1 AA sequence
#  cdr2_aa          → CDR2 AA sequence
#  fwr1_aa          → FR1 AA sequence
#  fwr2_aa          → FR2 AA sequence
#  fwr3_aa          → FR3 AA sequence
#  fwr4_aa          → FR4 AA sequence
#  sequence         → NT sequence
#
# then just need to cluster on CDR3 sequence to get CDR3 cluster size
# and an ID for the cluster. finally, prep a collapse and uncollapsed
# sheet of the excel workbook

airr <- airr %>% select(
  sequence_id, cdr3_aa, sequence_aa, cdr1_aa, cdr2_aa,
  fwr1_aa, fwr2_aa, fwr3_aa, fwr4_aa, sequence)

# ── Clustering with CD-HIT ───────────────────────────────────────────────────
# create named vector then remove NA so we can join back later
to_cluster <- airr$cdr3_aa
names(to_cluster) <- airr$sequence_id
to_cluster <- na.omit(to_cluster)

# do clustering
cdhit_result <- CellaRepertorium::cdhit(
        Biostrings::AAStringSet(to_cluster),
        identity = 0.9, # % identity
        min_length = 5, # throws out anything shorter than this
        s = 0.9, # 90% length tolerance
        G = 1, # global alignment (default)
        g = 1, # slow but accurate mode
        only_index = FALSE) %>%
        rename(cdr3_aa = seq, sequence_id = query_name)

# join back with query name
output_table <- airr %>%
  left_join(cdhit_result, by = c("sequence_id", "cdr3_aa")) %>%
  rename(
    cluster_size = n_cluster,
    cluster_id = cluster_idx,
    sequence_nt = sequence
  )

output_table_collapsed <- output_table %>%
  # remove those that weren't clustered
  filter(!is.na(cdr3_aa)) %>%
  group_by(cluster_id, cdr3_aa) %>%
  add_count() %>% 
  ungroup() %>%
  group_by(cluster_id) %>%
  summarise(
    cluster_size = cluster_size[1],
    sequence_id = paste(sequence_id, collapse = ", "),
    cdr3_aa = cdr3_aa[which.max(n)],
    cdr1_aa = cdr1_aa[which.max(n)],
    cdr2_aa = cdr2_aa[which.max(n)],
    fwr1_aa = fwr1_aa[which.max(n)],
    fwr2_aa = fwr2_aa[which.max(n)],
    fwr3_aa = fwr3_aa[which.max(n)],
    fwr4_aa = fwr4_aa[which.max(n)],
    sequence_aa = sequence_aa[which.max(n)],
    sequence_nt = sequence_nt[which.max(n)],
  )

# ── Build Excel workbook ──────────────────────────────────────────────────────
wb <- createWorkbook()
addWorksheet(wb, "collapsed_data")
addWorksheet(wb, "full_data")

# Header style — bold, light grey background, thin bottom border
header_style <- createStyle(
  fontName       = "Arial",
  fontSize       = 11,
  fontColour     = "#000000",
  fgFill         = "#D9D9D9",
  halign         = "left",
  textDecoration = "bold",
  border         = "Bottom",
  borderStyle    = "thin"
)

# Data style — plain
data_style <- createStyle(
  fontName = "Arial",
  fontSize = 11,
  halign   = "left",
  wrapText = FALSE
)

# Write header row manually so style can be applied
writeData(wb, "collapsed_data", output_table_collapsed, startRow = 1, startCol = 1,
          headerStyle = header_style, borders = "none")

# Apply data style to all data rows
if (nrow(output_table_collapsed) > 0) {
  addStyle(wb, "collapsed_data", style = data_style,
           rows = 2:(nrow(output_table_collapsed) + 1),
           cols = 1:ncol(output_table_collapsed),
           gridExpand = TRUE)
}

# Column widths (approximate, matching template spirit)
col_widths <- c(10, 12, 40, 35, 18, 18, 20, 18, 20, 18, 50)
setColWidths(wb, "collapsed_data", cols = 1:ncol(output_table_collapsed), widths = col_widths)

# Freeze top row
freezePane(wb, "collapsed_data", firstRow = TRUE)

# repeat same for the full data 
writeData(wb, "full_data", output_table, startRow = 1, startCol = 1,
          headerStyle = header_style, borders = "none")

if (nrow(output_table) > 0) {
  addStyle(wb, "full_data", style = data_style,
           rows = 2:(nrow(output_table) + 1),
           cols = 1:ncol(output_table),
           gridExpand = TRUE)
}

col_widths <- c(20, 30, 45, 18, 18, 18, 20, 18, 20, 18, 50)
setColWidths(wb, "full_data", cols = 1:ncol(output_table), widths = col_widths)

# Freeze top row
freezePane(wb, "full_data", firstRow = TRUE)

# ── Save ──────────────────────────────────────────────────────────────────────
saveWorkbook(wb, "alpsanger_results.xlsx", overwrite = TRUE)

# also write out plain csv (more for myself)
write_csv(output_table, "full_data.csv")
write_csv(output_table_collapsed, "collapsed_data.csv")
