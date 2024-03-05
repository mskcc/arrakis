/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT MODULES / SUBWORKFLOWS / FUNCTIONS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { paramsSummaryMap       } from 'plugin/nf-validation'
include { paramsSummaryMultiqc   } from '../subworkflows/nf-core/utils_nfcore_pipeline'
include { softwareVersionsToYAML } from '../subworkflows/nf-core/utils_nfcore_pipeline'
include { methodsDescriptionText } from '../subworkflows/local/utils_nfcore_arrakis_pipeline'
include ( REALLIGNMENT ) from '../subworkflows/local/reallignment'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow ARRAKIS {

    take:
    ch_samplesheet // channel: samplesheet read in from --input

    main:

    ch_versions = Channel.empty()
    ch_multiqc_files = Channel.empty()

    ref_index_list = []
    for(single_genome_ref in params.fasta_index){
        ref_index_list.add(file(single_genome_ref))
    }
    ch_fasta_ref = Channel.value([ "reference_genome", file(params.fasta), ref_index_list ])

    for(single_site in params.known_sites){
        known_site_list.add(file(single_site))
    }

    for(single_site in params.known_sites_index){
        known_site_index_list.add(file(single_site))
    }

    ch_known_sites = Channel.value(["known_sites", known_site_list, known_site_index_list])

    //
    // MODULE: Run Realignment
    //
    REALLIGNMENT (
        ch_samplesheet,
        ch_fasta_ref,
        ch_known_sites
    )
    ch_versions = ch_versions.mix(REALLIGNMENT.out.versions)

    //
    // Collate and save software versions
    //
    softwareVersionsToYAML(ch_versions)
        .collectFile(storeDir: "${params.outdir}/pipeline_info", name: 'nf_core_pipeline_software_mqc_versions.yml', sort: true, newLine: true)
        .set { ch_collated_versions }

    summary_params                        = paramsSummaryMap(workflow, parameters_schema: "nextflow_schema.json")
    ch_workflow_summary                   = Channel.value(paramsSummaryMultiqc(summary_params))



    emit:
    versions                 = ch_versions                 // channel: [ path(versions.yml) ]
    normal_qual_metrics      = REALLIGNMENT.out.normal_qual_metrics
    normal_qual_pdf          = REALLIGNMENT.out.normal_qual_pdf
    tumor_qual_metrics       = REALLIGNMENT.out.tumor_qual_metrics
    tumor_qual_pdf           = REALLIGNMENT.out.tumor_qual_pdf
    normal_bam               = REALLIGNMENT.out.normal_bam
    tumor_bam                = REALLIGNMENT.out.tumor_bam
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
