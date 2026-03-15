// modules/multiqc.nf
// Aggregates all per-sample FastQC reports into a single MultiQC report.

nextflow.preview.types = true

process multiqc {

    tag 'multiqc'
    label 'process_low'

    container "${ (workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container) ?
    'oras://community.wave.seqera.io/library/multiqc:1.33--e3576ddf588fa00d' :
    'community.wave.seqera.io/library/multiqc:1.33--ee7739d47738383b' }"

    input:
    zip_files: List<Path> // collected FastQC .zip reports from all samples

    output:
    report: Path = file('multiqc_report.html')

    script:
    """
    multiqc --outdir . .
    """
}
