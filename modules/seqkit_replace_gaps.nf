// modules/seqkit_replace_gaps.nf
// Replaces '-' gap characters with 'N' in FASTA files using seqkit.
// This is required for IgBLAST compatibility when sequences come directly
// from Sanger alignment exports (no basecalling).

nextflow.preview.types = true

process seqkit_replace_gaps {

    tag "${sample_id}"
    label 'process_low'

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
