// modules/tracy_basecall.nf
// Basecalls .ab1 Sanger trace files to FASTA/FASTQ using tracy.
// https://www.gear-genomics.com/docs/tracy/

nextflow.preview.types = true

process tracy_basecall {

    tag "${sample_id}"
    label 'process_low'
    
	container "${ (workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container) ?
    'oras://community.wave.seqera.io/library/tracy:0.8.1--869f2d602de8570b' :
    'community.wave.seqera.io/library/tracy:0.8.1--0988e4620d7132d3' }"

    input:
    (sample_id, ab1_file): Tuple<String, Path>

    output:
    basecalled = tuple(sample_id, file("${sample_id}.fasta"), file("${sample_id}.fastq"))

    script:
    """
    # Basecall to FASTA (used for IgBLAST)
    tracy basecall \\
        -f fasta \\
        -o "${sample_id}.fasta" \\
        ${ab1_file}
    
    # Replace sequence header in FASTA with sample_id
    sed -i "1s/.*/>${sample_id}/" ${sample_id}.fasta

    # Basecall to FASTQ (used for QC)
    tracy basecall \\
        -f fastq \\
        -o "${sample_id}.fastq" \\
        ${ab1_file}

    # Replace sequence header in FASTQ with sample_id
    sed -i "1s/.*/@${sample_id}/" ${sample_id}.fastq
    """
}
