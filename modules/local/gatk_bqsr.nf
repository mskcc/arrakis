process GATK_BQSR {
    tag "$meta.id"
    label 'process_medium'

    scratch true

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'docker://mskcc/gatk:3.3-0':
        'docker.io/mskcc/gatk:3.3-0' }"

    input:

    tuple val(meta), path(tumor_bam), path(normal_bam)
    tuple val(meta2), path(fasta), path(fai)
    tuple val(meta3), path(known_sites), path(known_sites_index)

    output:
    tuple val(meta), path("*.recal.matrix")               , emit: recal_matrix
    path "versions.yml"                                   , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"

    """
    java \
        -Xms${task.memory.toMega()/4}m \
        -Xmx${task.memory.toGiga()}g \
        -XX:-UseGCOverheadLimit \
        -Djava.io.tmpdir=${task.scratch} \
        -jar \
        /usr/bin/gatk.jar \
        -T \
        BaseRecalibrator \
        --input_file \
        ${bam} \
        --reference_sequence \
        ${fasta}
        --num_cpu_threads_per_data_thread \
        ${task.cpus * 2} \
        --read_filter \
        BadCigar \
        --covariate \
        CycleCovariate \
        ContextCovariate \
        ReadGroupCovariate \
        QualityScoreCovariate \
        --knownSites \
        ${known_sites} \
        --out \
        ${prefix}.recal.matrix

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        gatk: 3.3-0
        java: 8
    END_VERSIONS
    """

    stub:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}.recal.matrix


    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        gatk: 3.3-0
        java: 8
    END_VERSIONS
    """
}
