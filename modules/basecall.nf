// basecalls .ab1 sanger trace files to FASTA using tracy.
// https://www.gear-genomics.com/docs/tracy/

nextflow.preview.types = true

process basecall {
    label 'process_low'

	container "${ (workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container) ?
    'oras://community.wave.seqera.io/library/tracy:0.8.1--869f2d602de8570b' :
    'community.wave.seqera.io/library/tracy:0.8.1--0988e4620d7132d3' }"

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
