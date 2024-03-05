process ABRA {
    tag "$meta.id"
    label 'process_high'

    scratch true

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'docker://mskcc/abra:2.17':
        'docker.io/mskcc/abra:2.17' }"

    input:

    tuple val(meta), path(normal), path(normal_index), path(tumor), path(tumor_index), path(targets)
    tuple val(meta2), path(fasta), path(fai)

    output:
    tuple val(meta), path("tumor/*.abra.bam"), path("normal/*.abra.bam")              , emit: bams
    path "versions.yml"                                                               , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"

    """
    java \
        -Xms${task.memory.toMega()/4}m \
        -Xmx${task.memory.toGiga()}g \
        -jar \
        /usr/bin/abra.jar \
        --tmpdir \
        ${task.scratch}
        --threads ${task.cpus * 2} \
        --ref ${fasta} \
        --targets ${targets} \
        --out ${tumor.basename}.abra.bam,${normal.basename}.abra.bam
        --in ${tumor},${normal}
    mkdir tumor
    mkdir normal
    cp ${tumor.basename}.abra.bam tumor
    cp ${normal.basename}.abra.bam normal

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        abra: 2.17
        java: 8
    END_VERSIONS
    """

    stub:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}.tumor.abra.bam
    touch ${prefix}.normal.abra.bam


    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        abra: 2.17
        java: 8
    END_VERSIONS
    """
}
