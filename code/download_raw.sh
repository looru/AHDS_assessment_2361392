#!/bin/bash

API_BASE="https://eutils.ncbi.nlm.nih.gov/entrez/eutils"

SEARCH_TERM="\"gaming+disorder\"+OR+\"smartphone+addiction\"+OR+\"internet+addiction\""

PMIDS_FILE="data/raw/pmids.xml"

echo "--- starting PMID download ---"

SEARCH_URL="${API_BASE}/esearch.fcgi?db=pubmed&term=${SEARCH_TERM}&retmax=100000"

curl "${SEARCH_URL}" > "${PMIDS_FILE}"

echo "PMID list downloaded to ${PMIDS_FILE}"

echo "--- starting article metadata download ---"

PMID_LIST=$(grep -oP '(?<=<Id>)[0-9]+(?=</Id>)' "${PMIDS_FILE}")

COUNT=0
BATCH_SIZE=20
