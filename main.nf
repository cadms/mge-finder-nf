#!/usr/bin/env nextflow
//base folder for seqence inputs
params.in = "$baseDir/test-input/*.fas.gz"
params.outdir = "$baseDir/out"
params.gene_result_column = 1


//this is the folder structure of bactopia output
params.input_structure = "**/main/assembler/*.fna.gz"

process MEFINDER{
    publishDir "$baseDir/out"

    input:
        file seq

    output:
        path "${seq}.mge_mge_sequences.fna"
        path "${seq}.mge_result.txt"
        path "${seq}.mge.csv", emit: csv

    """
    mefinder find --contig $seq ${seq}.mge
    """
}


process UNZIP{
    input:
    file '*'

    output:
    path "unzipped_seqs/*"

    """
    mkdir unzipped_seqs
    for f in *.gz ; do gunzip -c "\$f" > unzipped_seqs/"\${f%.*}" ; done
    """
}

process CSV{
    debug true

    publishDir "$baseDir/out", mode: 'copy'

    input:
    val tables

    output:
    path 'mge_results.csv'

    exec:
    gene_list = []
    results = [:]
    tables.each { table ->
        sample_genes = []

        table
            .splitCsv(header: true, skip:5)
            .each {row -> sample_genes.push(row.name)}

        sample_genes.unique()
        gene_list += sample_genes
        sample_name = table.name.split("\\.").first()
        results[sample_name] = sample_genes
    }
    result_table = ""
    gene_list.unique().sort()
    results = results.sort()
    results.each{ sample_name, genes ->
        result_row = []
        gene_list.each { gene ->
            if (genes.contains(gene)){
                result_row += 1
            } else{
                result_row += 0
            }
        }
        result_row.push(sample_name)
        result_table += result_row.join(',') + "\n"
    }

    gene_list.push('Isolate')
    headers = gene_list.join(',') + "\n"
    result_table = headers + result_table

    csv_file = task.workDir.resolve('mge_results.csv')
    csv_file.text = result_table
}

workflow{
    input_seqs = Channel
        .fromPath("$baseDir/in/*")

    UNZIP(input_seqs)

    MEFINDER(UNZIP.out)
    CSV(MEFINDER.out.csv.collect())

}
