#!/usr/bin/env nextflow

// ============================================================
// alpsanger — Sanger sequencing nanobody annotation pipeline
// Strict Nextflow syntax (NXF_SYNTAX_PARSER=v2)
// ============================================================

// Enable typed processes
nextflow.preview.types = true

// Import processes and subworkflows
include { validate_params } from './modules/validate_params'
include { tracy_basecall } from './modules/tracy_basecall'
include { seqkit_replace_gaps } from './modules/seqkit_replace_gaps'
include { fastqc } from './modules/fastqc'
include { multiqc } from './modules/multiqc'
include { igblast } from './modules/igblast'
include { postprocess } from './modules/postprocess'

// Pipeline parameters
params {
    input_dir:        String       // required: directory with .ab1 or .fasta/.fa files
    igblast_db:       String       
    out_dir:          Path
    basecall:         Boolean    // run tracy basecalling on .ab1 files
    igblast_organism: String
    help:             Boolean
}

// Help message function
def helpMessage() {
    log.info """
    ╔══════════════════════════════════════════════════════╗
    ║              alpsanger  v1.0.0                       ║
    ║  Sanger sequencing nanobody annotation pipeline      ║
    ╚══════════════════════════════════════════════════════╝

    Usage:
        nextflow run main.nf [options]

    Required:
        --input_dir   DIR   Directory containing .ab1 (if --basecall true)
                            or .fasta / .fa files (if --basecall false)
        --igblast_db  DIR   Path to alpaca IgBLAST germline database directory

    Optional:
        --out_dir      DIR   Output directory  [default: results]
        --basecall    BOOL  Run tracy basecalling on .ab1 files [default: false]
        --igblast_organism STR  Organism for IgBLAST [default: alpaca]
        --help              Show this help message
    """.stripIndent()
}

workflow {
    main:

    // Print help and exit if requested
    helpMessage()

    // Step 1 — validate parameters
    validate_params(
        params.input_dir,
        params.igblast_db,
        params.basecall
    )

    // Step 2 — build input channel, basecall if required, run QC
    if (params.basecall) {

        // Channel of .ab1 files, gated on validation
        ab1_ch = channel.fromPath("${params.input_dir}/*.ab1", checkIfExists: true)
            .map { file -> tuple(file.baseName, file) }

        // Basecall ab1 → fastq
        basecalled_ch = tracy_basecall(ab1_ch)

        // FastQC + MultiQC on fastq output from tracy
        fastqc_ch = fastqc(basecalled_ch)
        multiqc(fastqc_ch.collect())

        // make a fasta channel
        fasta_ch = basecalled_ch.map { sample_id, fasta, _fastq -> tuple(sample_id, fasta) }

    } else {

        // Channel of .fasta/.fa files, gated on validation
        raw_read_ch = channel.fromPath("${params.input_dir}/*.{fasta,fa}", checkIfExists: true)
            .map { file -> tuple(file.baseName, file) }

        // Prepare fasta: no format conversion needed, just replace gap characters
        fasta_ch = seqkit_replace_gaps(raw_read_ch)
    }

    // Step 3 — IgBLAST annotation
    igblast_input_ch = channel.fromPath(params.igblast_db, type: 'dir').combine(fasta_ch)
    igblast_ch = igblast(igblast_input_ch, params.igblast_organism)

    // Step 4 — R post-processing → Excel report
    postprocess_ch = postprocess(igblast_ch.tsv.collect())

    // Publish outputs
    publish:
    prepared_fasta   = fasta_ch
    igblast_tsv      = igblast_ch.tsv
    multiqc_report   = params.basecall ? multiqc.out.report : channel.empty() 
    results_xlsx     = postprocess_ch.xlsx
    results_csv     = postprocess_ch.csv

    // Completion message
    onComplete:
    log.info """
    =====================================================================================
    alpsanger — workflow execution summary
    =====================================================================================

    Completed at  : ${workflow.complete}
    Duration      : ${workflow.duration}
    Success       : ${workflow.success}
    Work directory: ${workflow.workDir}
    Exit status   : ${workflow.exitStatus}
    Results       : ${workflow.outputDir}

    =====================================================================================
    """.stripIndent()

    // Error message
    onError:
    log.error "Error: Pipeline execution stopped with the following message: ${workflow.errorMessage}"
}

// Set output paths
output {
    multiqc_report {
        path '2_qc'
    }
    
    prepared_fasta {
        path '1_clean_sequence'
    }
    igblast_tsv {
        path '3_igblast'
    }
    results_xlsx {
       path '4_results'
    }
    results_csv {
       path '4_results'
    }
}
