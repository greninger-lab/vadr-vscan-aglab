process SUMMARY {

    label 'process_single'
    container 'nf-core/ubuntu:20.04'

    input:
    path(vadr_outs)
    //path(blast_gts)

    output:
    path "batch_error_alert.tsv", emit: error_alerts
    path "batch_classify_pass_fail.tsv", emit: classify
    path "batch_blast_genotype_summary.tsv", optional: true, emit: blast_summary


    script:
    """
    find  -L . -type f -name '*vadr.alt.list' -exec awk 'FNR==1 && NR!=1{next}{print}' {} + > batch_error_alert.tsv
    echo 'sample\tidx\tmodel\tgroup\tsubgroup\tnum_seqs\tnum_pass\tnum_fail' > batch_classify_pass_fail.tsv
    find -L . -type f -name "*.mdl" | xargs -I {} sh -c 'file={}; printf "%s\t" "\$(echo "\$file" | cut -d/ -f3- | sed "s/_out\\.vadr\\.mdl\$//")"; sed -n "4p" "\$file" | tr -s " " "\t"' >> batch_classify_pass_fail.tsv
    
    # --- summarize blast genotype ---
    echo -e "qacc\tsacc\tpident\tlength\tqstart\tqend\tsstart\tsend\tevalue\tbitscore" > batch_blast_genotype_summary.tsv
    find -L . -type f -name "*_blast_genotype.tsv" | sort | while read -r f; do
        awk 'NR==2' "\$f" >> batch_blast_genotype_summary.tsv
    done    
    
    """
}