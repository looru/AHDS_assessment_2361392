#!/usr/bin/env python3

import os
import glob
import re
import csv
import xml.etree.ElementTree as ET

RAW_DIR = "../data/raw"
OUT_DIR = "../data/processed"
OUTPUT_TSV = os.path.join(OUT_DIR, "pmid_year_title.tsv")

os.makedirs(OUT_DIR, exist_ok=True)

def extract_year(pubdate_elem):
    """Try to extract a 4-digit year from PubDate."""
    if pubdate_elem is None:
        return ""
    year_elem = pubdate_elem.find("Year")
    if year_elem is not None and year_elem.text:
        return year_elem.text.strip()
    medline_date = pubdate_elem.findtext("MedlineDate", default="").strip()
    match = re.search(r"\b(19|20)\d{2}\b", medline_date)
    return match.group(0) if match else ""

def parse_article_xml(xml_path):
    """Return (pmid, year, title) for one article XML file."""
    tree = ET.parse(xml_path)
    root = tree.getroot()

    # PMID
    pmid = root.findtext(".//MedlineCitation/PMID")
    if pmid is None:
        pmid = root.findtext(".//PMID", default="").strip()
    else:
        pmid = pmid.strip()

    # Title
    title = root.findtext(".//Article/ArticleTitle", default="").strip()

    # Year
    pubdate = root.find(".//Article/Journal/JournalIssue/PubDate")
    year = extract_year(pubdate)

    return pmid, year, title

def main():
    xml_files = glob.glob(os.path.join(RAW_DIR, "article-data-*.xml"))
    print(f"Found {len(xml_files)} article XML files.")

    with open(OUTPUT_TSV, "w", newline="", encoding="utf-8") as f:
        writer = csv.writer(f, delimiter="\t")
        writer.writerow(["PMID", "year", "title"])

        for i, xml_file in enumerate(xml_files, start=1):
            try:
                pmid, year, title = parse_article_xml(xml_file)
                if pmid:  # only write rows with a PMID
                    writer.writerow([pmid, year, title])
                print(f"[{i}/{len(xml_files)}] Processed {os.path.basename(xml_file)}")
            except Exception as e:
                print(f"Error parsing {xml_file}: {e}")

    print(f"\nDone. TSV written to: {OUTPUT_TSV}")

if __name__ == "__main__":
    main()
