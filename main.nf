#!/usr/bin/env nextflow
//base folder for seqence inputs
params.in = "$baseDir/test-input/*.fas.gz"
params.outdir = "$baseDir/out"


//this is the folder structure of bactopia output
params.input_structure = "**/main/assembler/*.fna.gz"

// options.args = [
//     "--truncLength ${params.trunclength}",
//     "--sort-order ${params.sortorder}",
//     "--genomesize ${params.genomesize}",
//     "--mindepth ${params.mindepth}",
//     "--kmerlength ${params.kmerlength}",
//     "--sketch-size ${params.sketchsize}",
//     params.save_sketches ? "--save-sketches sketches/" : "",
// ].join(' ').replaceAll("\\s{2,}", " ").trim()

process MEFINDER{
    publishDir "$baseDir/out"

    input:
        file seq

    output:
        path "${seq}.mge_mge_sequences.fna"
        path "${seq}.mge_result.txt"
        path "${seq}.mge.csv"

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

workflow{
    input_seqs = Channel
        .fromPath("$baseDir/in/*")

    UNZIP(input_seqs)
    // UNZIP.out.view()
    // Channel.fromList(UNZIP.out).view()
   MEFINDER(UNZIP.out)
    // INFILE.out.view()

    // result = run_ksnp()
    // result.view { "Result: ${it}" }
}
