process VADR {
    tag "$meta.id"
    cpus   params.vadr_cpus
    memory params.vadr_mem

    container "quay.io/jefffurlong/vadr"

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
    # Check for U in sequence.  If it is mRNA then replace with T and add [moltype=mRNA] to description
    python3 /opt/sequtils/fasta_rna_to_dna_strict.py ${fasta} ${meta.id}_untrimmed.fasta --allow-dna

    env > test.txt
    echo \$0 >> test.txt

    # Trim the sequence 
    /opt/vadr/vadr/miniscripts/fasta-trim-terminal-ambigs.pl --minlen 30 --maxlen 2000000 ${meta.id}_untrimmed.fasta > ${meta.id}_temp.fasta
    
    # Use v-scan.pl to find the best model
    v-scan.pl -c /opt/vadr/combined.conf -m ${meta.id}_temp.fasta ${meta.id}_out
    
    # cat the pass and fail tbl files and remove the Additional note
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

    cp ${meta.id}_temp.fasta ${meta.id}.fsa
    table2asn -t ${sbt} -f ${meta.id}_out.vadr.tbl -V vb -i ${meta.id}.fsa ${src_file} || true

    """
}
