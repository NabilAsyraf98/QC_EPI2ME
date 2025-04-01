#!/usr/bin/env nextflow

process NANOPLOT {
	publishDir params.out_dir, mode: 'copy'

	container 'community.wave.seqera.io/library/pip_nanoplot:465bd6ac9ccc268b'

	input:
	path(reads_file) 

	output:
	path("nanoplot_logs")
	//.html (report), .png (plots), .txt(Stats from Nanoplot), .log, .yml (containing software versions)
	
	script:
	"""
	mkdir nanoplot_logs

	#specifying Nanoplot command based on user choice
	if [[ ${params.fileType} == "bam" ]]; 
	then
		NanoPlot --bam ${reads_file} --outdir nanoplot_logs --threads 8 --loglength

	elif [[ ${params.fileType} == "fastq" ]]; then
		NanoPlot --fastq ${reads_file} --outdir nanoplot_logs --threads 8 --loglength
	fi

	cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        nanoplot: \$(echo \$(NanoPlot --version 2>&1) | sed 's/^.*NanoPlot //; s/ .*\$//')
    END_VERSIONS
	"""
}

workflow {
	//input is a path to a directory containing reads
	//if else condition to collect files from directory based on user input (bam/fastq) and feed into Nanoplot
				
	if("${params.fileType}" == "bam") {
		reads_channel=Channel
						.fromPath("${params.fastq}/*.${params.fileType}", type: 'file') 
						.collect()
	}
	else if ("${params.fileType}" == "fastq") {
		reads_channel=Channel
						.fromPath("${params.fastq}/*.${params.fileType}.gz", type: 'file')
						.collect()
	}
	
	NANOPLOT(reads_channel)
	
}


