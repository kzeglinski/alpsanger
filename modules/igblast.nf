// modules/igblast.nf
// Runs IgBLAST on cleaned FASTA using the specified organism's germline reference databases.
// Outputs AIRR-format TSV (--outfmt 19) for downstream R processing.

nextflow.preview.types = true

process igblast {

    tag "${sample_id}"
    label 'process_medium'

    container "${ (workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container) ?
    'oras://community.wave.seqera.io/library/igblast:1.22.0--3588511b44218582' :
    'community.wave.seqera.io/library/igblast:1.22.0--df7afc24896f633e' }"
    
    input:
    (igblast_db, sample_id, fasta_file): Tuple<Path, String, Path>
    igblast_organism: String

    output:
    tsv: Path = file("${sample_id}.igblast.tsv")

    script:
    // IGDATA must point to the igdata directory (contains internal_data and optional_file).
    // The databases directory contains the pre-formatted BLAST databases for V, D, J genes.
    """
    export IGDATA="${igblast_db}/igdata"
    export IGBLASTDB="${igblast_db}/databases"
    echo \$IGDATA
    echo \$IGBLASTDB

    igblastn \\
        -germline_db_V   ${igblast_db}/databases/imgt_${igblast_organism}_ighv \\
        -germline_db_D   ${igblast_db}/databases/imgt_${igblast_organism}_ighd \\
        -germline_db_J   ${igblast_db}/databases/imgt_${igblast_organism}_ighj \\
        -auxiliary_data  ${igblast_db}/igdata/optional_file/${igblast_organism}_gl.aux \\
        -organism        ${igblast_organism} \\
        -ig_seqtype      Ig \\
        -query           ${fasta_file} \\
        -outfmt          19 \\
        -out             ${sample_id}.igblast.tsv \\
        -num_threads     ${task.cpus}
    """
}