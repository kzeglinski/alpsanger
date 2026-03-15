// modules/validate_params.nf
// Validates all required pipeline parameters before any compute begins.

nextflow.preview.types = true

process validate_params {

    tag 'param_check'

    input:
    input_dir:  String
    igblast_db: String
    basecall:   Boolean

    output:
    validated: String = 'ok'

    exec:
    def input_path  = file(input_dir)
    def db_path     = file(igblast_db)

    // ── input_dir ────────────────────────────────────────────
    if (!input_path) {
        error """
        [alpsanger] ERROR: --input_dir is required.
        Provide the path to a directory containing:
          - .ab1 files  (when --basecall true)
          - .fasta/.fa files (when --basecall false, the default)
        """.stripIndent()
    }
    print(input_path)
    print(input_path.exists())
    if (!input_path.exists()) {
        error "[alpsanger] ERROR: --input_dir '${input_path}' does not exist."
    }
    if (!input_path.isDirectory()) {
        error "[alpsanger] ERROR: --input_dir '${input_path}' is not a directory."
    }

    // Check that the directory has relevant files
    def found = basecall
        ? input_path.listFiles().findAll { it.name.endsWith('.ab1') }
        : input_path.listFiles().findAll { it.name =~ /\.(fasta|fa)$/ }

    if (!found) {
        def mode = basecall ? '.ab1 (basecall=true)' : '.fasta/.fa (basecall=false)'
        error "[alpsanger] ERROR: No ${mode} files found in '${input_dir}'."
    }

    // ── igblast_db ────────────────────────────────────────────
    if (!db_path) {
        error """
        [alpsanger] ERROR: --igblast_db is required.
        Provide the path to the alpaca IgBLAST germline database directory
        """.stripIndent()
    }

    if (!db_path.exists() || !db_path.isDirectory()) {
        error "[alpsanger] ERROR: --igblast_db '${db_path}' does not exist or is not a directory."
    }

        // Inside that folder, there must be one called 'databases' and one called
    // 'igdata', inside 'igdata' there should be an 'internal_data' folder and an
    // 'optional_file' folder
    def database_path = file("${igblast_db}/databases")
    if (!database_path.exists() || !database_path.isDirectory()) {
        error "[alpsanger] ERROR: --igblast_db is missing the required 'databases' subdirectory. " +
              "Expected: ${igblast_db}/databases"
    }

    def igdata_path = file("${igblast_db}/igdata")
    if (!igdata_path.exists() || !igdata_path.isDirectory()) {
        error "[alpsanger] ERROR: --igblast_db is missing the required 'igdata' subdirectory. " +
              "Expected: ${igblast_db}/igdata"
    }

    def intdata_path = file("${igblast_db}/igdata/internal_data")
    if (!intdata_path.exists() || !intdata_path.isDirectory()) {
        error "[alpsanger] ERROR: --igblast_db is missing the required 'igdata/internal_data' subdirectory. " +
              "Expected: ${igblast_db}/igdata/internal_data"
    }

    def optfile_path = file("${igblast_db}/igdata/optional_file")
    if (!optfile_path.exists() || !optfile_path.isDirectory()) {
        error "[alpsanger] ERROR: --igblast_db is missing the required 'igdata/optional_file' subdirectory. " +
              "Expected: ${igblast_db}/igdata/optional_file"
    }

    log.info """
    ╔══════════════════════════════════════════════════════╗
    ║              alpsanger  — parameter check            ║
    ╚══════════════════════════════════════════════════════╝
     input_dir  : ${input_dir}
     igblast_db : ${igblast_db}
     basecall   : ${basecall}
     n_files    : ${found.size()}
    """.stripIndent()
}
