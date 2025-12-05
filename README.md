## Applied Health Data Science Summative Assessment  
# Health Data Science Mini Project

This repository contains the code and outputs for my summative assessment on **text mining PubMed articles related to gaming and digital addiction** using **tidyverse**, **tidytext**, and **topic modelling (LDA)**.

---

## Project Overview

The project uses the PubMed E-utilities API to:

1. **Download article metadata and abstracts** for a search on  
   `"gaming disorder" OR "smartphone addiction" OR "internet addiction" OR "social media addiction"`.
2. **Parse and clean the XML** into a tidy tabular format.
3. **Process article titles and abstracts** using tidytext:
   - Tokenisation (one-token-per-row)
   - Stop-word and digit removal
   - Optional stemming
4. **Perform descriptive and advanced text analyses**, including:
   - Trends in key title words over time
   - Comparison word cloud of title words across years
   - **LDA topic modelling applied to abstracts**
   - Temporal trends in topic prevalence over publication years

Key outputs are stored in `data/processed/` and visualisations in `figures/`.

---

## Repository Structure

```text
.
├─ code/
│  ├─ download_raw.sh                 # Bash script: download PMIDs + article XML from PubMed
│  ├─ extract_articles.R              # Parse XML -> TSV (PMID, year, title, abstract)
│  ├─ process_titles.R                # Tidytext processing of titles (tokens, stopwords, digits)
│  ├─ comparison_cloud_year.R         # Comparison cloud + 4-segment word×year table
│  ├─ advanced_lda_topics_over_time.R # LDA topic model + temporal topic trends
│  └─ output1.R, output2.R            # Additional analysis / plotting scripts (if used)
│
├─ data/
│  ├─ raw/                            # Raw XML files downloaded from PubMed
│  └─ processed/                      # Cleaned TSV outputs
│       ├─ pmid_year_title_abstract.tsv
│       ├─ title_tokens_clean.tsv
│       ├─ comparison_cloud_by_year_table.tsv
│       ├─ lda_topic_top_terms.tsv
│       └─ ...
│
├─ figures/
│  ├─ word_trends.png                 # Trends of key title words over time
│  ├─ comparison_cloud_by_year.png    # Comparison cloud of title words by year
│  └─ lda_topics_over_time.png        # LDA topic proportions over time
│
├─ config.yaml                        # Config for Snakemake / environment
├─ env_2361392.yml                    # Conda environment file
├─ Snakefile                          # (Optional) pipeline definition using Snakemake
└─ scripts.R                          # Wrapper to run the full pipeline from R



Methods: Snakemake Pipeline Design

The analysis workflow was implemented using Snakemake, which provides a reproducible, rule-based framework for automating multi-step data-processing pipelines. Each rule encodes the transformation of specific input files into corresponding outputs, allowing Snakemake to construct a directed acyclic graph (DAG) and execute only the steps required to generate missing or outdated outputs. This modular design ensures reusability, transparency, and efficient reruns, while maintaining strict control over software environments through a conda configuration.

Rule: download_raw

This rule retrieves PubMed article metadata and full XML records using the NCBI E-utilities API. It calls a Bash script (download_raw.sh) that accepts a parameter for the number of articles to download. The value is controlled by the configuration file (config.yaml), enabling the pipeline to operate in either test mode (20 articles) or full mode (all available articles). The rule outputs pmids.xml and a directory of raw article XML files in data/raw/.

Rule: extract_articles

This rule parses the downloaded XML files into a tidy tabular dataset containing PMIDs, publication years, titles, and abstracts. An R script (extract_articles.R) uses xml2, dplyr, and purrr to extract and clean the relevant metadata. The processed dataset is saved as pmid_year_title_abstract.tsv in data/processed/ and serves as the core dataset for all subsequent analyses.

Rule: process_titles

This rule performs tokenisation and cleaning of article titles using tidytext principles. The script removes XML residue, punctuation, digits, and stopwords, producing a tidy table of tokenised title words. This table supports downstream descriptive analyses and word-frequency visualisation. The rule outputs title_tokens_clean.tsv.

Rule: word_trends

This rule generates descriptive visualisations of keyword frequencies across publication years. Using tidytext and ggplot2, the script constructs time-series plots for selected terms (e.g., gaming, internet, smartphone, addiction). The resulting word_trends.png provides an initial overview of thematic changes in the literature.

Rule: comparison_cloud

This rule produces two outputs: a four-segment word-frequency table by year and a comparison word cloud illustrating the differential prominence of title words across the most frequent publication years. It uses tidyverse for text processing and the wordcloud package for visualisation. Outputs include comparison_cloud_by_year_table.tsv and comparison_cloud_by_year.png.

Rule: lda_topics

This rule runs the advanced Latent Dirichlet Allocation (LDA) topic model on article abstracts. Using topicmodels, tidytext, and ggplot2, the script fits an LDA model with 
𝑘
=
5
k=5 topics, extracts both term-level and document-level topic probabilities, and assigns human-readable topic names. Topic proportions are aggregated by publication year to produce a temporal trend plot (lda_topics_over_time.png). A table of top terms per topic (lda_topic_top_terms.tsv) is also saved to support interpretation.

Rule: all

The final rule specifies the complete list of target outputs required for the workflow. Snakemake uses this rule to infer dependencies and execute the entire pipeline from raw data to final figures. This ensures that the pipeline is fully automated and can be reproduced simply by running:

snakemake --profile .
