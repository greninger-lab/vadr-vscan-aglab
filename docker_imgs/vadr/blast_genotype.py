#!/usr/bin/env python3
"""
blast_genotype.py

Run a nucleotide BLAST search of a single query FASTA against
a specified local BLAST database and output the raw tabular
results as TSV with a header line. Also print the genotype
(substring after the underscore in the top sacc) to stdout.
"""

import subprocess
import sys
import os
import argparse

def main():
    parser = argparse.ArgumentParser(description="Run BLAST and extract genotype from top hit.")
    parser.add_argument("query", help="Query FASTA file")
    parser.add_argument("db", help="Local BLAST database")
    parser.add_argument("-o", "--output", required=True, help="Output TSV file for BLAST results")
    parser.add_argument("--perc_identity", dest="perc_identity", required=True, help="Percent identity")
    parser.add_argument("--evalue", dest="evalue", required=True, help="evalue")
    parser.add_argument("--word_size", dest="word_size", required=True, help="word size")
    args = parser.parse_args()

    # Determine blastn path
    blastn_path = os.path.join(os.environ.get("VADRBLASTDIR", ""), "blastn")

    # Run BLAST
    try:
        result = subprocess.run(
            [
                blastn_path,
                "-query", args.query,
                "-db", args.db,
                "-outfmt", "6 qacc sacc pident length qstart qend sstart send evalue bitscore",
                "-max_target_seqs", "10",
                "-perc_identity", args.perc_identity,
                "-evalue", args.evalue,
                "-word_size", args.word_size
            ],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            check=True
        )
    except subprocess.CalledProcessError as e:
        sys.stderr.write(f"\nBLAST failed:\n{e.stderr}\n")
        sys.exit(1)

    # Write header + results to file
    with open(args.output, "w") as f:
        f.write("qacc\tsacc\tpident\tlength\tqstart\tqend\tsstart\tsend\tevalue\tbitscore\n")
        f.write(result.stdout)

    # Print the top hit genotype to stdout (e.g., "A34")
    first_line = result.stdout.strip().splitlines()[0] if result.stdout.strip() else None
    if first_line:
        cols = first_line.split("\t")
        if len(cols) > 1:
            sacc = cols[1]
            # Extract substring after last underscore
            genotype = " ".join(sacc.split("_")[1:])
            print(genotype)
        else:
            print("No sacc found in BLAST output", file=sys.stderr)
    else:
        print("No hits found", file=sys.stderr)

if __name__ == "__main__":
    main()
