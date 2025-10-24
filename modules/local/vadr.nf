process VADR {
    tag "$meta.id"
    cpus   params.vadr_cpus
    memory params.vadr_mem

    container "quay.io/jefffurlong/vadr-dev"

    // Start with these extensions to save after annotation
    def extensions = [".tbl", ".gbf", ".fsa"]

    // Conditionally add .sqn if sbt file is provided
    if (params.sbt != null) {
        extensions << ".sqn"
    }

    // Add all VADR output if requested
    if (params.vadr_keep) {
        extensions << "_out"
    }

    // Join into a comma-separated string
    pattern = "*{${extensions.join(',')}}"

    publishDir "${params.outdir}/vadr", pattern: pattern, mode: 'copy'

    input:
        tuple val(meta), path(fasta)
        path(sbt)
        path(src)

    output:
        tuple val(meta), path("${meta.id}_out"),           emit: vadr_out
        tuple val(meta), path("${meta.id}_out.vadr.tbl"),  emit: tbl
        tuple val(meta), path("${meta.id}.gbf"),           emit: gbf
        tuple val(meta), path("${meta.id}.sqn"),           emit: sqn
        tuple val(meta), path("${meta.id}.fsa"),           emit: fsa
    

    shell:
    def prefix = task.ext.prefix ?: "${meta.id}"
    def src_file = src ? "-src-file ${src}" : ""

    """
    # Function: update_subgroup
    # Usage: update_subgroup "A71"
    # Replaces the subgroup value (4th field on line 4) in all .mdl files under current directory
    update_subgroup() {
        local new_subgroup="\$1"
    
        if [[ -z "\$new_subgroup" ]]; then
          echo "Error: subgroup value not provided." >&2
          return 1
        fi
    
        echo "Updating subgroup field to '\$new_subgroup' in all .mdl files..."
    
        find -L . -type f -name "*.mdl" | while read -r file; do
            echo "  Processing: \$file"
            awk -v newval="\$new_subgroup" '
              NR==4 { \$4=newval }   # modify subgroup (4th field)
              { print }             # print all lines
            ' "\$file" > "\${file}.tmp" && mv "\${file}.tmp" "\$file"
        done
    
        echo "Done."
    }

    # Limit the v-annotate.pl cpus to the task.cpus
    sed -i 's/\$(nproc)/${task.cpus}/g' /opt/vadr/combined.conf

    # Trim the sequence 
    /opt/vadr/vadr/miniscripts/fasta-trim-terminal-ambigs.pl --minlen 30 --maxlen 2000000 ${fasta} > ${meta.id}_temp.fasta
    
    # Use v-scan.pl to find the best model
    v-scan.pl -c /opt/vadr/combined.conf -m ${meta.id}_temp.fasta ${meta.id}_out
    
    # Cat the pass and fail tbl files and remove the Additional note
    pass_files=(${meta.id}_out/${meta.id}_out.*.vadr.pass.tbl)
    fail_files=(${meta.id}_out/${meta.id}_out.*.vadr.fail.tbl)

    # Check number of matching files
    if [[ \${#pass_files[@]} -ne 1 ]]; then
        echo "Error: Expected exactly one pass.tbl file, found \${#pass_files[@]}" >&2
        exit 1
    fi

    if [[ \${#fail_files[@]} -ne 1 ]]; then
        echo "Error: Expected exactly one fail.tbl file, found \${#fail_files[@]}" >&2
        exit 1
    fi

    # Assign filenames
    pass_tbl="\${pass_files[0]}"
    fail_tbl="\${fail_files[0]}"

    # Confirm files exist and concatenate
    if [[ -f "\$pass_tbl" && -f "\$fail_tbl" ]]; then
        cat "\$pass_tbl" "\$fail_tbl" > temp.${meta.id}_out.vadr.tbl
        echo "Combined into temp.${meta.id}_out.vadr.tbl"
    else
        echo "Error: One or both files do not exist" >&2
    exit 1
    fi

    sed -n '/Additional note/q;p' ./temp.${meta.id}_out.vadr.tbl > ./${meta.id}_out.vadr.tbl
    rm ./temp.${meta.id}_out.vadr.tbl

    # Get the model and set the appropriate moltype (cRNA)
    model=\$(find -L . -type f -name "*.mdl" | xargs -I {} awk 'NR==4 {print \$2}' {})

    # Set appropriate moltype, create \$note entry for genotype/sub lineage
    if [[ "\$model" == "hrvA" || "\$model" == "hrvB" || "\$model" == "hrvC" ]]; then
        
        gt=\$(/opt/sequtils/blast_genotype.py ${meta.id}_temp.fasta /opt/sequtils/blast_db/hrv_vp1 -o ${meta.id}_blast_genotype.tsv)

        # Check if gt is non-empty and prepare sequence source modifiers for description
        if [[ -n "\$gt" ]]; then
            # Construct the description string
            desc='[moltype=\"genomic RNA\"][note=\"Human rhinovirus genotype \${gt}\"]'
            update_subgroup "\$gt"
        else
            desc='[moltype=\"genomic RNA\"]'
        fi
        awk -v desc="\$desc" '/^>/ {print \$0" "desc; next} {gsub(/U/, "T"); print}' ${meta.id}_temp.fasta > ${meta.id}.fsa  
    elif [[ "\$model" == "229E" || "\$model" == "HKU1" || "\$model" == "NL63" || "\$model" == "OC43" ]]; then
        awk '/^>/ {print \$0" [moltype=\"genomic RNA\"]"; next} {gsub(/U/, "T"); print}' ${meta.id}_temp.fasta > ${meta.id}.fsa
    elif [[ "\$model" == "hpiv1" || "\$model" == "hpiv2" || "\$model" == "hpiv3" || "\$model" == "hpiv4" ]]; then
        awk '/^>/ {print \$0" [moltype=\"cRNA\"]"; next} {gsub(/U/, "T"); print}' ${meta.id}_temp.fasta > ${meta.id}.fsa
    elif [[ "\$model" == "mev" || "\$model" == "muv" || "\$model" == "ruv" ]]; then
        awk '/^>/ {print \$0" [moltype=\"cRNA\"]"; next} {gsub(/U/, "T"); print}' ${meta.id}_temp.fasta > ${meta.id}.fsa
    elif [[ "\$model" == "hmpv" ]]; then
        awk '/^>/ {print \$0" [moltype=\"cRNA\"]"; next} {gsub(/U/, "T"); print}' ${meta.id}_temp.fasta > ${meta.id}.fsa
    else
        echo "Unknown model type: \$model"
    fi

    table2asn -t ${sbt} -f ${meta.id}_out.vadr.tbl -V vb -i ${meta.id}.fsa ${src_file} || true

    """
}
