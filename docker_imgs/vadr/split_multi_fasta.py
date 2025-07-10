#!/usr/bin/env python3

import os
import sys

def write_fasta(header, sequence_lines, out_dir):
    """Write a single FASTA entry to a file."""
    seq_id = header.split()[0][1:]  # Remove the leading ">"
    output_file = os.path.join(out_dir, seq_id + ".fasta")
    with open(output_file, "w") as out_file:
        out_file.write(header + "\n")
        out_file.write("\n".join(sequence_lines) + "\n")

def main():
    if len(sys.argv) != 3:
        print("Usage: python split_multi_fasta.py <multi_fasta_file> <output_directory>")
        sys.exit(1)

    multi_fasta = sys.argv[1]
    out_dir = sys.argv[2]

    if not os.path.exists(out_dir):
        os.makedirs(out_dir)

    with open(multi_fasta, "r") as infile:
        header = None
        sequence_lines = []
        for line in infile:
            line = line.rstrip()
            if line.startswith(">"):
                if header:
                    write_fasta(header, sequence_lines, out_dir)
                header = line
                sequence_lines = []
            else:
                sequence_lines.append(line)
        # Write last entry
        if header:
            write_fasta(header, sequence_lines, out_dir)

    print(f"FASTA entries written to: {out_dir}")

if __name__ == "__main__":
    main()
