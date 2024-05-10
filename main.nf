
process i7_demux {

    tag { lane }

    input:
    tuple val(lane), path(reads) 

    output:
    path "*.1.fq.gz", emit: r1
    path "*.2.fq.gz", emit: r2

    script:
    """
    process_radtags \
      -1 ${reads[0]} \
      -2 ${reads[1]} \
      --barcodes $params.i7_index_path \
      --threads $task.cpus \
      --in-type gzfastq \
      --barcode_dist_1 2 \
      --rescue \
      --index_null \
      --disable_rad_check \
      --retain_header
    rename .rem.1.fq.gz .1.rem.fq.gz *.rem.1.fq.gz
    rename .rem.2.fq.gz .2.rem.fq.gz *.rem.2.fq.gz
    """
}


process sample_demux {

    tag {i7}

    input:
    tuple val(i7), val(plate), path(r1), path(r2)

    output:
    path "*.1.fq.gz", emit: r1
    path "*.2.fq.gz", emit: r2

    script:
    """
    process_radtags \
        -1 $r1 \
        -2 $r2 \
        -b ${params.barcode_dir}/${plate}-barcodes.tsv \
        --renz_1 xbaI \
        --renz_2 ecoRI \
        --barcode_dist_1 2 \
        --barcode_dist_2 2 \
        --in-type gzfastq \
        --rescue \
        --quality \
        --clean \
        --filter_illumina \
        --inline_inline \
        --retain_header
    rename .rem.1.fq.gz .1.rem.fq.gz *.rem.1.fq.gz
    rename .rem.2.fq.gz .2.rem.fq.gz *.rem.2.fq.gz
    """
}

process concat_samples {
    
    tag {sample}

    publishDir params.outdir, mode: "move"

    input:
    tuple val(sample), val(r1), val(r2)

    output:
    path "*.1.fq.gz", emit: r1
    path "*.2.fq.gz", emit: r2

    script:
    """
    cat $r1 > ${sample}.1.fq.gz
    cat $r2 > ${sample}.2.fq.gz
    """
}


workflow {
    raw_reads = channel.fromFilePairs(params.raw_read_paths)

    // Demultiplex i7 indexes
    i7_demux(raw_reads)

    // Prepare channel for sample demultiplexing
    // Map i7 index id to output filepaths, # TODO: Is it necessary to do this twice and then join? Could possibly map once, output as array, and pass three separate channels to process.
    i7_demux1 = i7_demux.out.r1.flatten().map { it -> tuple(it.simpleName, it) }
    i7_demux2 = i7_demux.out.r2.flatten().map { it -> tuple(it.simpleName, it) }
    // Join mapped filepaths for r1 and r2 into a single tuple
    i7_demux_joined = i7_demux1.join(i7_demux2)
    .map { // get the plate id associated with the i7 index
        id, r1, r2 -> 
        def sp = id.split('-', limit=2)
        tuple(sp[0], sp[1], r1, r2)
    }

    // Demultiplex samples
    sample_demux(i7_demux_joined)

    // Prepare channel for concatenation
    // Map sample id to output filepaths
    sample_demux1 = sample_demux.out.r1.flatten().map { it -> tuple(it.simpleName.split('_')[0], it) }
    sample_demux2 = sample_demux.out.r2.flatten().map { it -> tuple(it.simpleName.split('_')[0], it) }
    // Join mapped filepaths for r1 and r2 into a single tuple 
    sample_demux_joined = sample_demux1.join(sample_demux2) //TODO: Run these through fastqc
    // Group each sample and it's paths into tuples
    sample_demux_grouped = sample_demux_joined.groupTuple()
    // convert list of paths to a string since nextflow throws error due to dup file names TODO: better way to do this?
    .map { id, r1, r2 -> tuple(id, r1.join(' '), r2.join(' ')) } 

    // Concatenate all files for a sample into single file
    concat_samples(sample_demux_grouped) // TODO: Run output through fastqc
    
    // TODO: Summarize fastqc with multiqc
}

