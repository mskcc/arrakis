process GENERATE_PUBLISHED_PATH {
    tag "generate_samplesheet"
    label 'process_medium'

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'docker://mskcc/alpine:3.8':
        'docker.io/mskcc/alpine:3.8' }"

    input:

    tuple val(meta), path(output_file), path(output_file_index)
    tuple val(meta1), val(output_path)

    output:
    tuple val(meta), stdout        , emit: full_path

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def file_path = output_path+"/"+output_file.getName()
    def output_file = new File("${file_path}").getCanonicalPath()
    """
    printf "${output_file}"
    """
}
