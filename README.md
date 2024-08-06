# 3RAD Demultiplexing
Demultiplex 3RAD sequence libraries and merge samples duplicated across and within plates.

## Usage

```
nextflow run \
  main.nf \
  --raw_read_paths <RAW READS>
  --i7_index_path <i7 INDEX PATH> 
  --barcode_dir <BARCODE DIR> 
  --outdir <OUTDIR> 
```

raw_read_paths: Path to raw reads. Use wildcard expansion. For example "*{1,2}.fq.gz".
i7_index_path: Path to i7 index file. See below for details.
barcode_dir: Path to directory containing sample barcode file. See below for details. 
outdir: Path to directory for output files. 


## i7 Index File
Should be a tab separated file with index sequence followed by ID. ID must have two parts. An index ID and a plate ID separated by a hyphen. The plate ID must match the first part of the sample barcode file name. Also see example file.

For example:
|   |   |
|---|---|
| CGATAGAG | iTru7_111_01-plate1 |
| TTCGTTGG | iTru7_111_02-plate1 |
| GACGAATG | iTru7_111_05-plate2 |
| CATGAGGA | iTru7_111_06-plate2 |
| CTTCGTTC | iTru7_111_11-plate3 |
| CCAATAGG | iTru7_111_12-plate3 |

## Sample Barcode File
Should be a tab separated file with a barcode sequence followed by an ID. Underscores may only be used for within plate, sample duplicates. The first part of the filename separated by a hyphen, must match the plate ID used in the i7 index file. Also see example file. 

For example:
`plate1-barcodes.tsv`
|   |   |   |
|---|---|---|
| CCGAATG | CTAACGT    | sampleA |
| CCGAATG | TCGGTACT   | sampleB |
| CCGAATG | GATCGTTGT  | sampleC |
| CCGAATG | AGCTACACTT | sampleC_2 |

`plate2-barcodes.tsv`
|   |   |   |
|---|---|---|
| CCGAATG | CTAACGT    | sampleD_1 |
| CCGAATG | TCGGTACT   | sampleD_2 |
| CCGAATG | GATCGTTGT  | sampleE |
| CCGAATG | AGCTACACTT | sampleF |

`plate3-barcodes.tsv`
|   |   |   |
|---|---|---|
| CCGAATG | CTAACGT    | sampleA |
| CCGAATG | TCGGTACT   | sampleB |
| CCGAATG | GATCGTTGT  | sampleC |
| CCGAATG | AGCTACACTT | sampleD |
