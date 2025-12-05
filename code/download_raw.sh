#!/bin/bash

API_BASE="https://eutils.ncbi.nlm.nih.gov/entrez/eutils"

SEARCH_TERM="\"gaming+disorder\"+OR+\"smartphone+addiction\"+OR+\"internet+addiction\""

PMIDS_FILE="../data/raw/pmids.xml"

echo "--- starting PMID download ---"

SEARCH_URL="${API_BASE}/esearch.fcgi?db=pubmed&term=${SEARCH_TERM}&retmax=100000"

curl "${SEARCH_URL}" > "${PMIDS_FILE}"

echo "PMID list downloaded to ${PMIDS_FILE}"

echo "--- starting article metadata download ---"

PMID_LIST=$(grep -oP '(?<=<Id>)[0-9]+(?=</Id>)' "${PMIDS_FILE}")

COUNT=0
BATCH_SIZE=20


for PMID in ${PMID_LIST}; do

    if [ "$COUNT" -ge "$MAX_ARTICLES" ]; then
        echo "Reached maximum article limit of ${MAX_ARTICLES}. Stopping download."
        break
    fi

    FETCH_URL="${API_BASE}/efetch.fcgi?db=pubmed&id=${PMID}&retmode=xml"
    OUTPUT_FILE="../data/raw/article-data-${PMID}.xml"

    echo "Downloading article metadata for PMID: ${PMID} (${COUNT}/${MAX_ARTICLES})"


    curl -s "${FETCH_URL}" > "${OUTPUT_FILE}"

    sleep 1


    COUNT=$((COUNT + 1))
done

echo "--- Article metadata download complete ---"