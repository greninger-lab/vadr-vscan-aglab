from Bio import SeqIO
from Bio.Seq import Seq
import sys
import os

def strict_back_transcribe(seq: Seq, allow_dna=False) -> Seq:
    seq_str = str(seq).upper()
    has_u = 'U' in seq_str
    has_t = 'T' in seq_str

    if has_u and has_t:
        raise ValueError("Invalid sequence: contains both U and T (mixed RNA/DNA).")
        sys.exit(1)
    if has_u:
        return seq.back_transcribe()
    if has_t:
        if allow_dna:
            return seq
        else:
            raise ValueError("DNA detected. Set allow_dna=True to accept.")
    return seq.back_transcribe()  # U/T absent (e.g., ACG-only), assume RNA

def process_fasta_strict(input_path, output_path, allow_dna=False):
    with open(output_path, "w") as out_f:
        for record in SeqIO.parse(input_path, "fasta"):
            try:
                converted_seq = strict_back_transcribe(record.seq, allow_dna=allow_dna)
                if 'U' in str(record.seq).upper():
                    record.description += " [moltype=cRNA]"
                record.seq = converted_seq
                SeqIO.write(record, out_f, "fasta")
            except ValueError as e:
                print(f"Skipping {record.id}: {e}", file=sys.stderr)

if __name__ == "__main__":
    if len(sys.argv) < 3 or len(sys.argv) > 4:
        print("Usage: python fasta_rna_to_dna_strict.py input.fasta output.fasta [--allow-dna]", file=sys.stderr)
        sys.exit(1)

    input_fasta = sys.argv[1]
    output_fasta = sys.argv[2]
    allow_dna_flag = "--allow-dna" in sys.argv

    if not os.path.exists(input_fasta):
        print(f"Input file {input_fasta} does not exist.", file=sys.stderr)
        sys.exit(1)

    process_fasta_strict(input_fasta, output_fasta, allow_dna=allow_dna_flag)
    print(f"Finished. Output written to: {output_fasta}")
