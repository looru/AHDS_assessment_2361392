#!/usr/bin/env Rscript

library(xml2)
library(dplyr)
library(purrr)
library(stringr)
library(readr)

# ----- Paths (relative to project root) -----
raw_dir  <- "data/raw"        # where article-data-*.xml live
out_dir  <- "data/processed"  # where outputs will go
dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)


# ---------- Helper: extract 4-digit year ----------
get_year <- function(article_node) {
  year_node <- xml_find_first(
    article_node,
    ".//Article/Journal/JournalIssue/PubDate/Year"
  )
  year <- xml_text(year_node)

  if (!is.na(year) && str_detect(year, "^[0-9]{4}$")) {
    return(year)
  }

  # Fallback: MedlineDate like "2016 Jan-Feb"
  medline_node <- xml_find_first(
    article_node,
    ".//Article/Journal/JournalIssue/PubDate/MedlineDate"
  )
  medline_text <- xml_text(medline_node)
  year2 <- str_extract(medline_text, "\\b(19|20)[0-9]{2}\\b")
  ifelse(is.na(year2), "", year2)
}


# ---------- Parse ONE PubMed XML file ----------
# returns tibble(PMID, year, title, abstract)
parse_pubmed_file <- function(path) {
  doc <- read_xml(path)

  # Usually there is one PubmedArticle per file, but be robust
  articles <- xml_find_all(doc, ".//PubmedArticle")
  if (length(articles) == 0L) {
    articles <- list(doc)
  }

  map_dfr(articles, function(a) {
    # PMID
    pmid <- xml_text(xml_find_first(a, ".//MedlineCitation/PMID"))
    if (is.na(pmid) || pmid == "") {
      pmid <- xml_text(xml_find_first(a, ".//PMID"))
    }

    # Title (strip inner XML tags like <i>…</i>)
    title_node <- xml_find_first(a, ".//Article/ArticleTitle")
    title_raw  <- xml_text(title_node, trim = TRUE)

    title <- title_raw %>%
      # extra safety: remove any remaining <tag> patterns
      str_replace_all("<[^>]+>", "") %>%
      str_squish()

    # Year
    year <- get_year(a)

    # Abstract: join all <AbstractText> parts
    abstract_nodes <- xml_find_all(a, ".//Abstract/AbstractText")
    abstract <- abstract_nodes %>%
      xml_text(trim = TRUE) %>%
      paste(collapse = " ") %>%
      str_squish()

    tibble(
      PMID     = ifelse(is.na(pmid), "", pmid),
      year     = ifelse(is.na(year), "", year),
      title    = ifelse(is.na(title), "", title),
      abstract = ifelse(is.na(abstract), "", abstract)
    )
  })
}


# ---------- Safe wrapper: skip bad / non-XML files ----------
safe_parse_pubmed_file <- function(path) {
  tryCatch(
    {
      parse_pubmed_file(path)
    },
    error = function(e) {
      message("Skipping file due to parse error: ", path)
      tibble(
        PMID     = character(),
        year     = character(),
        title    = character(),
        abstract = character()
      )
    }
  )
}


# ---------- Main pipeline ----------
xml_files <- list.files(
  raw_dir,
  pattern = "^article-data-.*\\.xml$",
  full.names = TRUE
)

cat("Found", length(xml_files), "XML files\n")

if (length(xml_files) == 0L) {
  stop("No XML files found in ", raw_dir,
       " matching 'article-data-*.xml'. Check your paths.")
}

articles <- map_dfr(xml_files, safe_parse_pubmed_file)

# Remove rows without a title & deduplicate by PMID
articles_clean <- articles %>%
  filter(title != "") %>%
  distinct(PMID, .keep_all = TRUE)

cat("After filtering, kept", nrow(articles_clean), "articles\n")

# (1–3) TSV with three columns: PMID, year, title
write_tsv(
  articles_clean %>% select(PMID, year, title),
  file.path(out_dir, "pmid_year_title.tsv")
)

# (4) TSV with abstracts: PMID, abstract
write_tsv(
  articles_clean %>% select(PMID, abstract),
  file.path(out_dir, "pmid_abstract.tsv")
)

cat("Wrote:\n",
    "  - ", file.path(out_dir, "pmid_year_title.tsv"), "\n",
    "  - ", file.path(out_dir, "pmid_abstract.tsv"), "\n")
