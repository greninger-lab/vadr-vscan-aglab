//
// This file holds several functions specific to the main.nf workflow in the pipeline
//

import nextflow.Nextflow

class WorkflowMain {
    //
    // Validate parameters and print summary to screen
    //
    public static void initialise(workflow, params, log) {

        // Print workflow version and exit on --version
        if (params.version) {
            String workflow_version = NfcoreTemplate.version(workflow)
            log.info "${workflow.manifest.name} ${workflow_version}"
            System.exit(0)
        }

        if (params.help) {
            log.info "The following command line options are available:\n" +
                    "   `--input  /path/to/your/sample_fasta.csv`  (required)\n" +
                    "   `--outdir /path/to/output`                 (required)\n" +
                    "   `--vadr_keep`                              (optional) keeps all VADR output\n" +
                    "   `--sbt`                                    (optional) GenBank submission template file\n" +
                    "   `--src`                                    (optional) GenBank source modifier table file\n" +
                    "   `-profile docker`                          (required)\n" +
                    "   `-c /path/to/your/custom.config`           (optional) used for configuring computational environments (e.g., AWS)\n"
            System.exit(0)
        }

        // Check that a -profile or Nextflow config has been provided to run the pipeline
        NfcoreTemplate.checkConfigProvided(workflow, log)

        // Check AWS batch settings
        NfcoreTemplate.awsBatch(workflow, params)

        // Check input has been provided
        if (!params.input) {
            Nextflow.error("Please provide an input sample fastas file to the pipeline e.g. '--input sample_fastas.csv'")
        }              
    }

}
