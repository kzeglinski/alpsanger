// modules/multiqc.nf
// Aggregates all per-sample FastQC reports into a single MultiQC report.

nextflow.preview.types = true

process multiqc {

    tag 'multiqc'
    label 'process_low'

    input:
    zip_files: List<Path> // collected FastQC .zip reports from all samples

    output:
    report: Path = file('multiqc_report.html')

    script:
    """
    multiqc --outdir . .
    """
}
