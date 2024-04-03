include { ABRA } from '../../modules/local/abra'
include { GATK_BQSR } from '../../modules/local/gatk_bqsr'
include { GATK_PRINTREADS as normal_printreads; GATK_PRINTREADS as tumor_printreads } from '../../modules/local/gatk_printreads'
include { PICARD_COLLECT_MULTIPLE_METRICS as normal_multiple_metrics; PICARD_COLLECT_MULTIPLE_METRICS as tumor_multiple_metrics } from '../../modules/local/picard_collect_multiple_metrics'
include { PICARD_INDEX as normal_index; PICARD_INDEX as tumor_index } from '../../modules/local/picard_index'
include { GENERATE_DOWNSTREAM_SAMPLESHEET } from '../../modules/local/generate_downstream_samplesheet'

workflow REALLIGNMENT {

    take:
    ch_bams
    ch_fasta
    ch_known_sites                                             // channel: //  [ meta (id, assay, normalType), tumorBam, normalBam , bedFile]

    main:

    ch_versions = Channel.empty()

    ABRA(
        ch_bams,
        ch_fasta
    )

    ch_versions = ch_versions.mix(ABRA.out.versions)

    tumor_bams = ABRA.out.bams.map{
        new Tuple(it[0],it[1])
    }
    normal_bams = ABRA.out.bams.map{
        new Tuple(it[0],it[2])
    }

    tumor_index(
        tumor_bams
    )

    ch_versions = ch_versions.mix(tumor_index.out.versions)

    normal_index(
        normal_bams
    )

    ch_versions = ch_versions.mix(normal_index.out.versions)

    ch_indexed_bams = normal_index.out.bam.join(tumor_index.out.bam)

    GATK_BQSR(
        ch_indexed_bams,
        ch_fasta,
        ch_known_sites
    )

    ch_versions = ch_versions.mix(GATK_BQSR.out.versions)

    tumor_printreads(
        tumor_index.out.bam,
        ch_fasta,
        GATK_BQSR.out.recal_matrix

    )

    ch_versions = ch_versions.mix(tumor_printreads.out.versions)

    tumor_multiple_metrics(
        tumor_printreads.out.bam,
        ch_fasta
    )

    ch_versions = ch_versions.mix(tumor_multiple_metrics.out.versions)

    normal_printreads(
        normal_index.out.bam,
        ch_fasta,
        GATK_BQSR.out.recal_matrix

    )

    ch_versions = ch_versions.mix(normal_printreads.out.versions)

    normal_multiple_metrics(
        normal_printreads.out.bam,
        ch_fasta
    )

    ch_versions = ch_versions.mix(normal_multiple_metrics.out.versions)

    ch_samplesheet = create_samplesheet(tumor_printreads.out.bam,normal_printreads.out.bam,normal_printreads.out.published_path)

    GENERATE_DOWNSTREAM_SAMPLESHEET(ch_samplesheet)

    emit:

    normal_qual_metrics = normal_multiple_metrics.out.qual_metrics
    normal_qual_pdf = normal_multiple_metrics.out.qual_pdf
    tumor_qual_metrics = tumor_multiple_metrics.out.qual_metrics
    tumor_qual_pdf = tumor_multiple_metrics.out.qual_pdf
    normal_bam = normal_printreads.out.bam
    tumor_bam = tumor_printreads.out.bam
    samplesheet = GENERATE_DOWNSTREAM_SAMPLESHEET.out.samplesheet
    versions = ch_versions                                // channel: [ versions.yml ]
}

def create_samplesheet(tumor, normal, published_path) {
    tumor_channel = tumor
        .map{
            new Tuple(it[0].id,it)
            }
    normal_channel = normal
        .map{
            new Tuple(it[0].id,it)
            }
    path_channel = published_path
        .map{
            new Tuple(it[0].id,it)
            }
    mergedWithKey = tumor_channel
        .join(normal_channel)
        .join(path_channel)
    merged = mergedWithKey
        .map{
            "${it[1][0].id},${it[3][1]}/${it[1][1].getName()},${it[3][1]}/${it[2][1].getName()},${it[1][0].assay},${it[1][0].normalType}"
        }
        .toList()
    return merged

}
