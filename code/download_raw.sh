#!/bin/bash

set -euo pipefail


MAX_ARTICLES="${1:-10000}"

API_BASE="https://eutils.ncbi.nlm.nih.gov/entrez/eutils"
SEARCH_TERM=$2

RAW_DIR="data/raw"
PMIDS_FILE="${RAW_DIR}/pmids.xml"

SLEEP_SECONDS=1

mkdir -p "${RAW_DIR}"

SEARCH_URL="${API_BASE}/esearch.fcgi?db=pubmed&term=${SEARCH_TERM}&retmax=${MAX_ARTICLES}"

curl -s "${SEARCH_URL}" > "${PMIDS_FILE}"
echo "Saved PMIDs to: ${PMIDS_FILE}"

PMID_LIST=$(grep -oP '(?<=<Id>)[0-9]+(?=</Id>)' "${PMIDS_FILE}")

if [ -z "$PMID_LIST" ]; then
    echo "ERROR: No PMIDs extracted. Check search term or network."
    exit 1
fi


PMID_LIST=$(echo "$PMID_LIST" | head -n "${MAX_ARTICLES}")

echo "Extracted $(echo "$PMID_LIST" | wc -l) PMIDs."


COUNT=0     

for PMID in ${PMID_LIST}; do
    COUNT=$((COUNT + 1))

    OUTPUT_FILE="${RAW_DIR}/article-data-${PMID}.xml"
    FETCH_URL="${API_BASE}/efetch.fcgi?db=pubmed&id=${PMID}&retmode=xml"

    echo "(${COUNT}) Downloading article for PMID: ${PMID}"

    curl -s "${FETCH_URL}" > "${OUTPUT_FILE}"

    
    if ! grep -q "<PubmedArticle" "${OUTPUT_FILE}" 2>/dev/null; then
        echo "WARNING: Empty or invalid XML for PMID ${PMID}. Removing..."
        rm -f "${OUTPUT_FILE}"
        continue
    fi

    sleep "${SLEEP_SECONDS}"
done

echo
echo "============================"
echo " Download Completed "
echo "Articles saved in: ${RAW_DIR}"
echo "============================"
