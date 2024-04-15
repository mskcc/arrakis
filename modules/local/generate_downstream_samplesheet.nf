process GENERATE_DOWNSTREAM_SAMPLESHEET {
    tag "generate_samplesheet"
    label 'process_medium'

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'docker://mskcc/alpine:3.8':
        'docker.io/mskcc/alpine:3.8' }"

    publishDir "${params.outdir}/", pattern: "*.csv", mode: params.publish_dir_mode

    input:

    val(combined)

    output:
    path("*.csv")        , emit: samplesheet

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def output_file = "pairId,tumorBam,normalBam,assay,normalType,bedFile\n"+combined.join("\n")

    """
    printf "${output_file}" > realignment_bams_samplesheet.csv
    """
}
