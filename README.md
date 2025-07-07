# vadr-vscan-local
Nextflow pipeline for running [VADR](https://github.com/ncbi/vadr) v-scan for annotating HCoV, HMPV, HPIV, MeV, MuV or RuV sequences using Greninger-lab hosted VADR model libraries. 

# Dependencies
Nextflow - [installation instructions](https://www.nextflow.io/docs/latest/install.html)

Docker - [installation instructions](https://docs.docker.com/get-started/get-docker/)

# Command line
    nextflow run greninger-lab/vadr-vscan-local --input sample_fastas.csv --outdir ./out -profile docker

#### vadr-vscan-local will automatically detect which model library to use for annotation.  Input sequences must be from one of the following currently supported species:
HCoV, HMPV, HPIV, MeV, MuV or RuV.

#### Input sample_fastas.csv format:
---------
    sample,fasta
    SAMPLE1,/PATH/TO/SAMPLE1.fasta
    SAMPLE2,/PATH/TO/SAMPLE2.fasta
---------

# Example 
Download [example.tgz](./assets/example.tgz)
    tar xvzf example.tgz
    nextflow run greninger-lab/vadr-vscan-local --input example.csv --outdir ./out -profile docker





