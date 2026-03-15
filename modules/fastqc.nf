// modules/fastqc.nf
// Runs FastQC on FASTQ output from tracy basecalling to assess base quality.

nextflow.preview.types = true

process fastqc {

    tag "${sample_id}"
    label 'process_low'

    input:
    (sample_id, fasta_file, fastq_file): Tuple<String, Path, Path>

    output:
    zip: Path = file("${sample_id}_fastqc.zip")

    script:
    """
    fastqc --outdir . --threads ${task.cpus} ${fastq_file}
    """
}
