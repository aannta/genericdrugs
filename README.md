# genericdrugs
## Objectives:
Generic Drugs Project aims to examine changes in prices of top generic drugs in the American pharmaceutical market to produce evidence for collusion. 
This segment of the project aims to explore the feasibility of carrying out the analysis from publicly available information. The deliverable is time-series information on drug pricing that can be segregated by manufacturers for visual examination. 

## Terminologies:
* NDC: National Drug Code identifies the specific pharmaceutical product on the market, and comprises the labeller/manufacturer (MFG) - product - packaging components. This comes in either 10- or 11-digit format, with a few possible ways to break down into individual components. 
* ANDA: Abbreviated New Drug Application identifies an application filed for FDA's approval for a new drug on the market.
* NADAC: National Average Drug Acquisition Cost is the approximate invoice price pharmacies pay for medications in the USA.

## Methodology:
Step 1: 1_NDC_MFG_mapping.R  
While the NDC has a 'labeller/manufacturer' component which is the starting 4 or 5 digits, it is not immediately apparent which specific manufacturer this manufacturer code identifies. The NDC-to-ANDA mapping is obtained from FDA’s NDC directory. The ANDA-to-MFG mapping is obtained from FDA’s Orange Book. Via ANDA codes, the drugs’ NDCs are linked to their respective manufacturers.

Input: ANDA_MFG.txt, NDC_ANDA_pipedelim.csv  

Output: mapping of NDC-to-MFG in final.Rda and FINAL.xlsx  

Step 2: 2_price_mapping.Rmd  
The FINAL file obtained from Step 1 does not have NDC that’s segregated into the individual components needed. This step segregates the NDC into components and due to the number of possible combinations, crosswalk file obtained from https://data.nber.org/data/ndc-to-labeler-code-product-code-crosswalk.html is used to verify the individual components post-segregation, especially for product code. Product code is then used in tandem with SUBSTANCENAME (the active ingredient’s name) to link up with price information. 
NADAC is obtained from https://dev.socrata.com/foundry/data.medicaid.gov/a4y5-998d for price information.   

Input: final.Rda, crosswalk.csv, NADAC_20200206.csv  

Output: mapping of NADAC, NDC, MFG and SUBSTANCENAME in nadac_mfg.Rda   

Step 3: 3_top_cartelized.R  
Clean up the active ingredients’ names in SUBSTANCENAME and filter down to match top 13 cartelized drugs in the US market obtained from literature. Mean unit price is calculated for each drug and each month, and a basket is constructed consisting of the 13 top cartelized drugs (later whittled down to 9) with mean unit price % change calculated for each month.  

Input: nadac_mfg.Rda, top_13.csv  

Output: basket_time_series_top_cartelized.Rda for % mean change in basket’s price, to_chart_final_top_cartelized.Rda for plotting mean unit price over time, nadac_appl_mthly_top_cartelized.Rda for plotting mean unit price over time segregated by manufacturer/applicant  

Step 4: 4_report.Rmd  
For each of the top cartelized drugs, mean unit price is plotted over time, with and without segregation by manufacturers/applicants.   

Input: to_chart_final_top_cartelized.Rda, nadac_appl_mthly_top_cartelized.Rda    

Output: report.html for the final report
