// modules/fastqc.nf
// Runs FastQC on FASTQ output from tracy basecalling to assess base quality.

nextflow.preview.types = true

process fastqc {

    tag "${sample_id}"
    label 'process_low'

    container "${ (workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container) ?
    'oras://community.wave.seqera.io/library/fastqc:0.12.1--104d26ddd9519960' :
    'community.wave.seqera.io/library/fastqc:0.12.1--af7a5314d5015c29' }"

    input:
    (sample_id, fasta_file, fastq_file): Tuple<String, Path, Path>

    output:
    zip: Path = file("${sample_id}_fastqc.zip")

    script:
    """
    fastqc --outdir . --threads ${task.cpus} ${fastq_file}
    """
}
