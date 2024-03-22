#!/usr/bin/env nextflow

params.input = "$baseDir/in"
params.output = "$baseDir/out"
params.gene_result_column = 1
params.gzip = false


//this is the folder structure of bactopia output
params.input_structure = "**/main/assembler/*.fna.gz"

process MEFINDER{
    //we're saving it as {sample_name}/{results_files}
    publishDir (
        path: params.output,
        saveAs: { fn -> "${((fn =~ /([^.\s]+)/)[0][0])}/$fn" }
    )

    input:
    file fasta

    output:
    path "${fasta.getSimpleName()}.mge_mge_sequences.fna", emit: fna
    path "${fasta.getSimpleName()}.mge_result.txt", emit: txt
    path "${fasta.getSimpleName()}.mge.csv", emit: csv

    script:
    def prefix = fasta.getSimpleName()
    def is_compressed = fasta.getName().endsWith(".gz") ? true : false
    def fasta_name = fasta.getName().replace(".gz", "")
    """
    if [ "$is_compressed" == "true" ]; then
        gzip -c -d $fasta > $fasta_name
    fi

    mkdir $prefix
    mefinder find --contig $fasta_name ${prefix}.mge
    """

}

process CSV{
    debug true

    publishDir params.output, mode: 'copy'

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

process ZIP{
    publishDir params.output, mode: 'copy'

    input:
    path files
    path csv

    output:
    path '*.tar.gz'

    """
    current_date=\$(date +"%Y-%m-%d")
    outfile="plasmindfinder_\${current_date}.tar.gz"
    tar -chzf \${outfile} ${files.join(' ')} $csv
    """
}

workflow{
    input_seqs = Channel
        .fromPath("$params.input/*{fas,gz,fasta,fsa,fsa.gz,fas.gz}")

    MEFINDER(input_seqs)
    results = MEFINDER.out
    CSV(results.csv.collect())
    if (params.gzip){
        all_results = results.csv
                .mix(results.txt)
                .mix(results.fna)
                .collect()
        ZIP(all_results,CSV.out)
    }
}
