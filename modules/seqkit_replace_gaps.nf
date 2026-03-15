// modules/seqkit_replace_gaps.nf
// Replaces '-' gap characters with 'N' in FASTA files using seqkit.
// This is required for IgBLAST compatibility when sequences come directly
// from Sanger alignment exports (no basecalling).

nextflow.preview.types = true

process seqkit_replace_gaps {

    tag "${sample_id}"
    label 'process_low'

    container "${ (workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container) ?
    'oras://community.wave.seqera.io/library/seqkit:2.13.0--205358a3675c7775' :
    'community.wave.seqera.io/library/seqkit:2.13.0--05c0a96bf9fb2751' }"


    input:
    (sample_id, fasta_file): Tuple<String, Path>

    output:
    fasta = tuple(sample_id, file("${sample_id}_clean.fasta"))

    script:
    """
    seqkit replace \\
        --pattern '-' \\
        --replacement 'N' \\
        --by-seq \\
        ${fasta_file} \\
        --out-file ${sample_id}_clean.fasta
    """
}
