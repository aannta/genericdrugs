options(scipen = 999) # explicitly disables scientific notation
library(tidyverse)
library(stringr)
library(lubridate)

draft_nadac_mfg <- readRDS('nadac_mfg.Rda')
top13 <- read.delim(file.path("input","top13.csv"), header = TRUE)
top13 <- top13 %>% mutate(Drug.Name = toupper(as.character(Drug.Name)))

########### create a df for tracking mean unit price of each of the top 13 cartelized drug over time
# filter the df down to single SUBSTANCENAME without ; (except the few cases with ; changed to &)
draft_basket <- na.omit(draft_nadac_mfg %>% 
                          select(NADAC_Per_Unit, Effective_Date, SUBSTANCENAME) %>%
                          mutate(SUBSTANCENAME = as.character(SUBSTANCENAME)) %>%
                          mutate(SUBSTANCENAME = str_replace(SUBSTANCENAME, "FOSINOPRIL SODIUM; HYDROCHLOROTHIAZIDE", "FOSINOPRIL SODIUM & HYDROCHLOROTHIAZIDE")) %>%
                          mutate(SUBSTANCENAME = str_replace(SUBSTANCENAME, "GLIPIZIDE; METFORMIN HYDROCHLORIDE", "GLIPIZIDE & METFORMIN HYDROCHLORIDE")) %>%
                          mutate(SUBSTANCENAME = str_replace(SUBSTANCENAME, "GLYBURIDE; METFORMIN HYDROCHLORIDE", "GLYBURIDE & METFORMIN HYDROCHLORIDE")))

draft_basket <- draft_basket %>%
  filter(!grepl(";", SUBSTANCENAME))

# comb through top 13 drugs and compile those with matching SUBSTANCE NAME
dummy_basket <- draft_basket %>% filter(grepl(top13$Drug.Name[1], SUBSTANCENAME)) %>% 
  mutate(SIMPSUBSTANCENAME = top13$Drug.Name[1])
i <- 2
for (i in 2:13) {
  indv_basket <- draft_basket %>% 
    filter(grepl(top13$Drug.Name[i], SUBSTANCENAME)) %>%
    mutate(SIMPSUBSTANCENAME = top13$Drug.Name[i])
  dummy_basket <- rbind(dummy_basket, indv_basket)
}

draft_basket <- dummy_basket

# floor date for all datapoints to convert to aggregate to month
draft_basket <- draft_basket %>%
  mutate(Effective_Month = floor_date(Effective_Date, "month")) %>%
  group_by(SIMPSUBSTANCENAME, Effective_Month) %>% 
  mutate(Mean_NADAC = mean(NADAC_Per_Unit)) %>%
  ungroup()

#r remove all except Mean NADAC aggregated at month granularity
to_chart <- draft_basket %>% 
  select(SIMPSUBSTANCENAME, Effective_Month, Mean_NADAC) %>%
  group_by(SIMPSUBSTANCENAME, Effective_Month, Mean_NADAC) %>% summarize() %>% 
  ungroup() %>%
  arrange(SIMPSUBSTANCENAME, Effective_Month)

# most restrictive Month Range from 2013-11-01 to 2019-09-01, remove other months out of range
# fix hard-code
to_chart <- to_chart %>% filter(Effective_Month > as.Date("2013-10-01") & Effective_Month < as.Date("2019-10-01"))

# create a list of individual dfs for each SUBSTANCE to lag Mean_NADAC
subst_list <- vector(mode = "list", length = 13)
to_chart_final <- data.frame()

for (i in 1:13) {
  subst_list[[i]] <- to_chart %>% filter(SIMPSUBSTANCENAME == top13$Drug.Name[i])
  subst_list[[i]] <- cbind(subst_list[[i]], mutate_all(subst_list[[i]], lag))[,c(1,2,3,6)]
  subst_list[[i]][1,4] <- subst_list[[i]][1,3]
  subst_list[[i]] <- subst_list[[i]] %>%
    mutate(Pc_Change = (Mean_NADAC - Mean_NADAC.1) / Mean_NADAC.1 * 100)
  if (!(i %in% c(1, 2, 3, 11))) {
    to_chart_final <- rbind(to_chart_final, subst_list[[i]])
  }
}

# after compiling, turns out there are only 9 cartelized drugs that can match with original list from literature
saveRDS(to_chart_final ,file = "to_chart_final_top_cartelized.Rda")


########### create a df for tracking mean unit price of top cartelized drugs (contained in one 'basket') over time
basket_time_series <- to_chart_final %>% group_by(Effective_Month) %>% summarize(Mean_Change = mean(Pc_Change)) %>% ungroup()
saveRDS(basket_time_series ,file = "basket_time_series_top_cartelized.Rda")


########### create a df for segregating top cartelized drugs by applicants/manufacturers
draft_nadac_appl_mthly <- na.omit(draft_nadac_mfg %>% 
                                    select(NADAC_Per_Unit, Effective_Date, Applicant, SUBSTANCENAME) %>%
                                    mutate(SUBSTANCENAME = as.character(SUBSTANCENAME), Applicant = as.character(Applicant)) %>%
                                    mutate(SUBSTANCENAME = str_replace(SUBSTANCENAME, "FOSINOPRIL SODIUM; HYDROCHLOROTHIAZIDE", "FOSINOPRIL SODIUM & HYDROCHLOROTHIAZIDE")) %>%
                                    mutate(SUBSTANCENAME = str_replace(SUBSTANCENAME, "GLIPIZIDE; METFORMIN HYDROCHLORIDE", "GLIPIZIDE & METFORMIN HYDROCHLORIDE")) %>%
                                    mutate(SUBSTANCENAME = str_replace(SUBSTANCENAME, "GLYBURIDE; METFORMIN HYDROCHLORIDE", "GLYBURIDE & METFORMIN HYDROCHLORIDE")))

draft_nadac_appl_mthly <- draft_nadac_appl_mthly %>%
  filter(!grepl(";", SUBSTANCENAME))

# comb through top 13 drugs and compile those with matching SUBSTANCE NAME
dummy_basket <- draft_nadac_appl_mthly %>% filter(grepl(top13$Drug.Name[1], SUBSTANCENAME)) %>% 
  mutate(SIMPSUBSTANCENAME = top13$Drug.Name[1])
i <- 2
for (i in 2:13) {
  indv_basket <- draft_nadac_appl_mthly %>% 
    filter(grepl(top13$Drug.Name[i], SUBSTANCENAME)) %>%
    mutate(SIMPSUBSTANCENAME = top13$Drug.Name[i])
  dummy_basket <- rbind(dummy_basket, indv_basket)
}

draft_nadac_appl_mthly <- dummy_basket

# floor date for all datapoints to convert to aggregate to month
draft_nadac_appl_mthly <- draft_nadac_appl_mthly %>%
  mutate(Effective_Month = floor_date(Effective_Date, "month"))

saveRDS(draft_nadac_appl_mthly ,file = "nadac_appl_mthly_top_cartelized.Rda")
