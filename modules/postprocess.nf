// modules/postprocess.nf
// Merges all per-sample IgBLAST TSVs and runs the R post-processing script
// to produce the final Excel output in sanger_template format.

nextflow.preview.types = true

process postprocess {

    tag 'postprocess'
    label 'process_low'

    input:
    tsv_files: List<Path> // collected list of all per-sample .igblast.tsv files

    output:
    xlsx: Path = file('alpsanger_results.xlsx')
    csv: Set<Path> = files("*.csv")

    script:
    """
    # Concatenate TSVs: keep header from first file only
    head -n1 \$(ls *.igblast.tsv | head -1) > combined_igblast.tsv
    for f in *.igblast.tsv; do
        tail -n+2 "\$f" >> combined_igblast.tsv
    done

    Rscript ${projectDir}/bin/postprocess_igblast.R \\
        --input  combined_igblast.tsv \\
        --output alpsanger_results.xlsx
    """
}
