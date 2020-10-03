library(tidyverse)
library(openxlsx)

# input is file with '|' delimiter
ndc_anda <- read.delim("input/NDC_ANDA_pipedelim.csv", header = TRUE, fill = TRUE, sep = "|")

# input is raw file downloaded from Orange Book
anda_mfg <- read.delim("input/ANDA_MFG.txt", header = TRUE, fill = TRUE, sep = "~", colClasses = ("Appl_No" = "character"))

draft_ndc_anda <- ndc_anda %>% 
  filter(MARKETINGCATEGORYNAME == "NDA AUTHORIZED GENERIC" | MARKETINGCATEGORYNAME == "NDA" | MARKETINGCATEGORYNAME == "ANDA") %>% 
  mutate(ANDA_end = gsub("^[a-z,A-Z]+([0-9]+)$", "\\1", APPLICATIONNUMBER)) %>%
  mutate(ANDA_start = gsub("^([a-z,A-Z]+)[0-9]+$", "\\1", APPLICATIONNUMBER))

draft_ndc_anda <- draft_ndc_anda %>% filter(ANDA_start != "BA" & ANDA_start != "BN") 
  
draft_ndc_anda <- draft_ndc_anda %>% mutate(ANDA_lookup = paste0(ifelse(ANDA_start == "ANDA", "A", ifelse(ANDA_start == "NDA", "N", "X")),ANDA_end))

draft_anda_mfg <- anda_mfg
# colnames(draft_anda_mfg)[7] <- "ANDA"
draft_anda_mfg <- draft_anda_mfg %>% mutate(ANDA_lookup = paste0(Appl_Type, Appl_No))

draft <- left_join(draft_ndc_anda, draft_anda_mfg, "ANDA_lookup")

# reorder columns
draft <- draft %>% select("PRODUCTNDC", "APPLICATIONNUMBER", "LABELERNAME", "Applicant", "Applicant_Full_Name", "ANDA_lookup", "PRODUCTTYPENAME", "PROPRIETARYNAME", "NONPROPRIETARYNAME", "DOSAGEFORMNAME", "ROUTENAME", "STARTMARKETINGDATE", "MARKETINGCATEGORYNAME", "SUBSTANCENAME", "ACTIVE_NUMERATOR_STRENGTH", "ACTIVE_INGRED_UNIT", "PHARM_CLASSES", "Ingredient", "DF.Route", "Trade_Name", "Strength", "Product_No", "TE_Code", "Approval_Date", "RLD", "RS", "Type")

#remove Applicant = NA
draft <- subset(draft, !is.na(Applicant))

# subsetting files
appl_vs_name <- draft %>% group_by(Applicant, Applicant_Full_Name) %>% 
  select(Applicant, Applicant_Full_Name) %>% summarize()
mfg_vs_labeler <- draft %>% group_by(Applicant, LABELERNAME) %>% summarize()

# save output
final <- draft
saveRDS(final,file = "final.Rda")
write.xlsx(final, 'FINAL.xlsx')