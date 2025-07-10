#!/usr/bin/env python3

import os
import sys
import csv

def main():
    if len(sys.argv) != 3:
        print("Usage: python generate_sample_fasta_csv.py <input_fasta_directory> <csv_filename>")
        sys.exit(1)

    fasta_dir = sys.argv[1]
    csv_filename = sys.argv[2]

    if not os.path.isdir(fasta_dir):
        print(f"Error: Directory not found: {fasta_dir}")
        sys.exit(1)

    if not csv_filename.lower().endswith(".csv"):
        csv_filename += ".csv"

    output_csv_path = os.path.abspath(csv_filename)

    fasta_files = [
        f for f in os.listdir(fasta_dir)
        if f.endswith(".fasta") or f.endswith(".fa")
    ]

    if not fasta_files:
        print(f"No FASTA files found in directory: {fasta_dir}")
        sys.exit(0)

    with open(output_csv_path, "w", newline="") as out_csv:
        writer = csv.writer(out_csv)
        writer.writerow(["sample", "fasta"])

        for filename in sorted(fasta_files):
            sample_name = os.path.splitext(filename)[0]
            fasta_path = os.path.abspath(os.path.join(fasta_dir, filename))
            writer.writerow([sample_name, fasta_path])

    print(f"CSV file written to: {output_csv_path}")

if __name__ == "__main__":
    main()
