# vadr-vscan-aglab
A Nextflow pipeline for running [VADR](https://github.com/ncbi/vadr) v-scan to annotate nucleotide sequences using Greninger Lab developed VADR model libraries for the following viral species:
* Measles virus
* Human metapneumovirus
* Human parainfluenza virus (HPIV-1, HPIV-2, HPIV-3, HPIV-4)
* Mumps virus
* Rubella virus
* Seasonal human coronavirus (229E, NL63, HKU1, OC43)

# Dependencies required before using "vadr-vscan-aglab"
Nextflow - [installation instructions](https://www.nextflow.io/docs/latest/install.html)

Docker - [installation instructions](https://docs.docker.com/get-started/get-docker/)

# How vadr-vscan-aglab pipeline works
The tool compares a FASTA formatted nucleotide sequence to curated reference models to automatically annotate genomic features (.vadr.tbl) and report potential sequence anomalies (error_alert.tsv).
If a [Submission Template (.sbt) file](https://submit.ncbi.nlm.nih.gov/genbank/template/submission/) and a [Source Modifiers Table (.src) file](https://www.ncbi.nlm.nih.gov/WebSub/html/help/genbank-source-table.html) are included, ASN.1 Format (.sqn) files will be generated for [NCBI GenBank submission](https://www.ncbi.nlm.nih.gov/genbank/submit/) of your sequences by email to gb-sub@ncbi.nlm.nih.gov 

## Utility tools for creating a samplesheet of the fasta files (if needed)
This pipeline is a containerized application that can automatically scale to utilize the computing resources available (desktop, cloud, or cluster). To run efficiently, it needs a samplesheet in CSV format. This file helps the pipeline process multiple sequences in parallel, depending on the available resources. The samplesheet must indicate the FASTA header and the file path for each query sequence.

Note: the current version of the pipeline requires each query sequence to be stored in a separate FASTA file. Multi-FASTA files are not supported.

You are welcome to split multifasta and create the samplesheet manually, but we also provide scripts to generate it automatically for your convenience.


### Download [utils.zip](https://github.com/greninger-lab/vadr-vscan-aglab/raw/refs/heads/main/assets/utils.zip) and unzip.
#### To split a multi-FASTA file into single FASTA files:
Copy and paste the following command into your terminal, replacing <multi_fasta_file.fasta> with the name of your multi-FASTA file, and <output_directory> with the path to the folder where you want to save your individual FASTA files:

`python3 utils/split_multi_fasta.py <multi_fasta_file.fasta> <output_directory>`

#### To create a samplesheet csv file:
Copy and paste the following command into your terminal, replacing <input_fasta_directory> with the path to the folder containing your FASTA files, and <samplesheet_output.csv> with your desired samplesheet filename:

`python3 utils/generate_sample_fasta_csv.py <input_fasta_directory> <samplesheet_output.csv>`

##### Input samplesheet.csv example format:
---------
    sample,fasta
    SAMPLE1,/PATH/TO/SAMPLE1.fasta
    SAMPLE2,/PATH/TO/SAMPLE2.fasta
---------

# Running vadr-vscan-aglab
The input sequences must be nucleotide sequences from one of the currently supported virus species listed above. In the default version vadr-vscan-aglab will generate a 5-column annotation table and an annotated sequence in .gb format (with "test" metadata). Copy and paste the following command into your terminal, replacing <samplesheet_output.csv> with actual name of your samplesheet:

    nextflow run greninger-lab/vadr-vscan-aglab -r main -latest --input <samplesheet_output.csv> --outdir ./out -profile docker

However, if you also want to create the genbank submission .sqn files (and .gb files with complete metadata), you should indicate a [Submission Template (.sbt) file](https://submit.ncbi.nlm.nih.gov/genbank/template/submission/) and a [Source Modifiers Table (.src) file](https://www.ncbi.nlm.nih.gov/WebSub/html/help/genbank-source-table.html). Copy and paste the following command into your terminal, replacing <samplesheet_output.csv>, <submission_template.sbt> and <source_modifiers.src> with your actual filenames:

    nextflow run greninger-lab/vadr-vscan-aglab -r main -latest --input <samplesheet_output.csv> --sbt <submission_template.sbt> --src <source_modifiers.src> --outdir ./out -profile docker

## Command line options
| option | description | 
|--------|-------------|
| `--input  /path/to/your/sample_fastas.csv` | (required) path to a csv sample,fasta input file |
| `--outdir /path/to/output`                | (required) output directory |
| `--vadr_keep`                             | (optional) keeps all VADR output in the output/vadr directory (SAMPLE_out) |
| `--sbt <file>`        | (optional) path to a [GenBank Submission Template (.sbt) file](https://submit.ncbi.nlm.nih.gov/genbank/template/submission/) | 
| `--src <file>`        | (optional) path to a [Source Modifiers Table (.src) file](https://www.ncbi.nlm.nih.gov/WebSub/html/help/genbank-source-table.html) |
| `-profile docker`                         | (required) |
| `-c /path/to/your/custom.config`          | (optional) used specify a custom configuration file (see [Nextflow docs](https://www.nextflow.io/docs/latest/config.html) |

### You can test with the example input FASTA
Download [example.zip](https://github.com/greninger-lab/vadr-vscan-aglab/raw/refs/heads/main/assets/example.zip)
    
    unzip example.zip
    cd example
    nextflow run greninger-lab/vadr-vscan-aglab -r main -latest --input example.csv --outdir ./out -profile docker

#### The default (no "optional" command line options) output directory:
```
out
├── pipeline_info
├── summary
|   ├── batch_classify_pass_fail.tsv  ← ⚠️ Check this file for VADR pass/fail reports on each sequence
|   └── batch_error_alert.tsv         ← ⚠️ Check here for error alerts for any VADR failed sequences
└── vadr
    ├── AB470486.fsa
    ├── AB470486.gbf
    ├── AB470486_out.vadr.tbl
```

#### Using options "--vadr_keep", "--sbt" and "--src"
```
out
├── pipeline_info
├── summary
|   ├── batch_classify_pass_fail.tsv  ← ⚠️ Check this file for VADR pass/fail reports on each sequence
|   └── batch_error_alert.tsv         ← ⚠️ Check here for error alerts for any VADR failed sequences
└── vadr
    ├── AB470486.fsa
    ├── AB470486.gbf
    ├── AB470486.sqn  ← Created when --sbt <file> and --src <file> are provided
    ├── AB470486_out  ← Created when --vadr_keep is provided
    │   ├── AB470486_out.muv.vadr.alc
    │   ├── AB470486_out.muv.vadr.alt      ← VADR alert file (see below)
    │   ├── AB470486_out.muv.vadr.alt.list ← VADR alert file (used for generating batch_error_alert.tsv)
    │   ├── <additional VADR output files>
    ├── AB470486_out.vadr.tbl

```
## Notes about VADR (v-annotate.pl) error alerts
VADR v-annotate.pl detects and reports alerts for more than 70 types of unexpected sequence characteristics. Documentation for v-annotate.pl can be found [here](https://github.com/ncbi/vadr/blob/master/documentation/annotate.md), and extensive documentation for v-annotate.pl alerts is available [here](https://github.com/ncbi/vadr/blob/master/documentation/alerts.md).



