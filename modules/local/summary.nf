process SUMMARY {

    label 'process_single'
    container 'nf-core/ubuntu:20.04'

    input:
    path(vadr_outs)

    output:
    path "batch_error_alert.tsv", emit: error_alerts
    path "batch_classify_pass_fail.tsv", emit: classify


    script:
    """
    find  -L . -type f -name '*vadr.alt.list' -exec awk 'FNR==1 && NR!=1{next}{print}' {} + > batch_error_alert.tsv
    echo 'sample\tidx\tmodel\tgroup\tsubgroup\tnum_seqs\tnum_pass\tnum_fail' > batch_classify_pass_fail.tsv
    find -L . -type f -name "*.mdl" | xargs -I {} sh -c 'file={}; printf "%s\t" "\$(echo "\$file" | cut -d/ -f3- | sed "s/_out\\.vadr\\.mdl\$//")"; sed -n "4p" "\$file" | tr -s " " "\t"' >> batch_classify_pass_fail.tsv
    """
}