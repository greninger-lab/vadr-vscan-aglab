# vadr-vscan-local
Nextflow pipeline for running [VADR](https://github.com/ncbi/vadr) v-scan to annotate HCoV, HMPV, HPIV, MeV, MuV or RuV viral sequences using Greninger-lab developed VADR model libraries.  If a [Submission Template (.sbt) file](https://submit.ncbi.nlm.nih.gov/genbank/template/submission/) and a [Source Modifiers Table (.src) file](https://www.ncbi.nlm.nih.gov/WebSub/html/help/genbank-source-table.html) are included, ASN.1 Format (.sqn) files will be generated for GenBank submission of your sequences.

# Dependencies
Nextflow - [installation instructions](https://www.nextflow.io/docs/latest/install.html)

Docker - [installation instructions](https://docs.docker.com/get-started/get-docker/)

# Command line
    nextflow run greninger-lab/vadr-vscan-local -r main -latest --input sample_fastas.csv --outdir ./out -profile docker

#### vadr-vscan-local will automatically detect which model library to use for annotation.  Input sequences must be from one of the following currently supported species:
HCoV, HMPV, HPIV, MeV, MuV or RuV.

#### Input csv sample,fasta format:
---------
    sample,fasta
    SAMPLE1,/PATH/TO/SAMPLE1.fasta
    SAMPLE2,/PATH/TO/SAMPLE2.fasta
---------

### Command line options:
| option | description | 
|--------|-------------|
| `--input  /path/to/your/sample_fastas.csv` | (required) path to a csv sample,fasta input file |
| `--outdir /path/to/output`                | (required) output directory |
| `--vadr_keep`                             | (optional) keeps all VADR output in the output/vadr directory (SAMPLE_out) |
| `--sbt <file>`        | (optional) path to a [GenBank Submission Template (.sbt) file](https://submit.ncbi.nlm.nih.gov/genbank/template/submission/) | 
| `--src <file>`        | (optional) path to a [Source Modifiers Table (.src) file](https://www.ncbi.nlm.nih.gov/WebSub/html/help/genbank-source-table.html) |
| `-profile docker`                         | (required) |
| `-c /path/to/your/custom.config`          | (optional) used for configuring computational environments (e.g., AWS) |



# Example 
Download [example.zip](https://github.com/greninger-lab/vadr-vscan-local/raw/refs/heads/main/assets/example.zip)
    
    unzip example.zip
    cd example
    nextflow run greninger-lab/vadr-vscan-local -r main -latest --input example.csv --outdir ./out -profile docker

## Example output
```
out
├── pipeline_info
├── summary
|   ├── batch_classify_pass_fail.tsv
|   └── batch_error_alert.tsv
└── vadr
    ├── AB470486.fsa
    ├── AB470486.gbf
    ├── AB470486.sqn
    ├── AB470486_out
    │   ├── AB470486_out.muv.vadr.alc
    │   ├── AB470486_out.muv.vadr.alt
    │   ├── AB470486_out.muv.vadr.alt.list
    │   ├── <additional VADR output files>
    ├── AB470486_out.vadr.tbl

```






