make_heatmap <- function(df, heatmap_name = "") {
  # information about samples 1..70
  sample_info <- read_tsv(file.path(metadata_path, "detailed_sample_description.tsv"))
  
  concentrations <- as.matrix(sample_info[, c(colnames(sample_info)[grepl("concentration_", colnames(sample_info), fixed = TRUE)])])
  colnames(concentrations) <- str_remove(colnames(concentrations), "concentration_")
  rownames(concentrations) <- 1:70
  concentrations <- concentrations[, c("h9C12-Q97A", "h9C12-WT", "Brimab", "Umab", "PGT121", "PGDM1400")]
  
  
  n_peptides <- df %>%
    group_by(Sample, match_ig_type) %>%
    summarise(n_peptides=length(unique(Sequence))) %>%
    as.data.frame()
  
  n_peptides <- reshape(n_peptides[(n_peptides$match_ig_type != "CON") & (n_peptides$match_ig_type != "ab_multimap"), ], idvar="Sample", timevar="match_ig_type", direction="wide")
  
  all_abs_HC <- c("n_peptides.h9C12-Q97A_HC", "n_peptides.h9C12-WT_HC", 
                  "n_peptides.Brimab_HC", "n_peptides.Umab_HC", 
                  "n_peptides.PGT121_HC", "n_peptides.PGDM1400_HC")
  all_abs_LC <- c("n_peptides.h9C12_LC", 
                  "n_peptides.Brimab_LC", "n_peptides.Umab_LC", 
                  "n_peptides.PGT121_LC", "n_peptides.PGDM1400_LC")
  
  
  n_peptides[setdiff(c(all_abs_HC, all_abs_LC), colnames(n_peptides))] <- NA
  
  tmp <- data.frame(Sample=1:70)
  
  n_peptides_HC <- n_peptides[, c("Sample", all_abs_HC)]
  n_peptides_HC <- merge(tmp, n_peptides_HC, all.x = T, by = "Sample")
  n_peptides_HC <- n_peptides_HC[, -1]
  
  
  n_peptides_LC <- n_peptides[, c("Sample", all_abs_LC)]
  
  n_peptides_LC <- merge(tmp, n_peptides_LC, all.x = T, by = "Sample")
  n_peptides_LC <- n_peptides_LC[, -1]
  n_peptides_LC <- cbind(n_peptides_LC[, 1], n_peptides_LC)
  
  Heatmap(concentrations, 
          cell_fun = function(j, i, x, y, width, height, fill) { 
            if(!is.na(n_peptides_HC[i, j]) & !is.na(n_peptides_LC[i, j])) {
              grid.text(sprintf("H:%.f L:%.f", n_peptides_HC[i, j], n_peptides_LC[i, j]), x, y, gp = gpar(fontsize = 10))
            } else if (!is.na(n_peptides_HC[i, j])) {
              grid.text(sprintf("H:%.f", n_peptides_HC[i, j]), x, y, gp = gpar(fontsize = 10))
            } else if (!is.na(n_peptides_LC[i, j])) {
              grid.text(sprintf("L:%.f", n_peptides_LC[i, j]), x, y, gp = gpar(fontsize = 10))
            }
          } ,
          cluster_rows = FALSE,
          cluster_columns = FALSE,
          col=structure(c("white", brewer.pal(4,"Blues")), names = c("0", "1", "10", "100", "1000")), 
          row_names_gp = grid::gpar(fontsize = 10),
          name = "Concentration (ng)", 
          left_annotation = rowAnnotation(GingisKHAN = sample_info$has_GingisKHAN, 
                                          blood = sample_info$has_blood, 
                                          col = list(blood = c("TRUE" = "red", "FALSE" = "white"), 
                                                     GingisKHAN = c("TRUE" = "black", "FALSE" = "white"))),
          column_title = heatmap_name
  )
}