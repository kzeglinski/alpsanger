// modules/seqkit_replace_gaps.nf
// Replaces '-' gap characters with 'N' in FASTA files using seqkit.
// This is required for IgBLAST compatibility when sequences come directly
// from Sanger alignment exports (no basecalling).

nextflow.preview.types = true

process replace_gaps {
    label 'process_low'

    input:
    (sample_id, fasta_file): Tuple<String, Path>

    output:
    fasta: Path = file("${sample_id}.clean.fasta")

    script:
    """
    seqkit replace \\
        --pattern '-' \\
        --replacement 'N' \\
        --by-seq \\
        ${fasta_file} \\
        --out-file ${sample_id}.clean.fasta
    """
}
