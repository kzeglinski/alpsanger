// basecalls .ab1 sanger trace files to FASTA using tracy.
// https://www.gear-genomics.com/docs/tracy/

nextflow.preview.types = true

process basecall {
    label 'process_low'

    input:
    input_dir:  Path

    output:
    fasta: Path = file("*.fasta")

    script:
    """
    #!/usr/bin/env bash

    # basecall all ab1 files in the directory
    # need to loop over the files in the directory
    # and run tracy on each one
    # this is because tracy doesn't support wildcards
    for file in ${input_dir}/*.ab1; do
        # get the sample name from the file name
        file_name=\$(basename "\$file" .ab1)
        # run tracy on the file
        tracy basecall \$file --format fasta --otype consensus --output \${file_name}.fasta
    done
    """
}
