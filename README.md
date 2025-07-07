# vadr_annotator
Nextflow pipeline for running batch VADR annotation.

#### sample_fastas.csv format:
---------
    sample,fasta
    SAMPLE1,/PATH/TO/SAMPLE1.fasta
    SAMPLE2,/PATH/TO/SAMPLE2.fasta
---------

### Command line:
   nextflow run ../vadr_annotator 
      --input  sample_fastas.csv 
      --outdir ./out_final_1/ 
      --mdir /Users/jfurlong/dev/HSV-2-vadr/hsv_vadr_annotation/vadr_hsv/NC_001798 
      --mkey NC_001798.vadr 
      --sbt /Users/jfurlong/dev/HSV-2-vadr/test.sbt 
      -profile docker 
      -c nextflow_aws.config 
      -with-tower
      -r main 



