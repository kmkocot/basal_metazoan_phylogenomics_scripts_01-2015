Scripts used for basal metazoan phylogenomics--These have been tested on Scientific Linux, but aside from potentially necessary changes to "rename" commands it should work in any linux environment.

HaMSrR_v13SciLinux_concatenate.sh renames the files output by hamstr into a format appropriate for orthology determination. Organisms included in the core ortholog set can be added or removed from each OG (see end of script)
The rename command will need to be changed if you run this script on Ubuntu.

basalMetazoan_orthologyScript_HaMSTR13_parallel.sh takes the output of HAMSTR and performs several steps to remove groups and sequences that are not suitable for phylogenomic analysis.

The final product of this script is a set of trimmed amino acid alignments representing putatively orthologous groups suitable for phylogenomic analysis.

This version of the script requires GNU parallel (http://www.gnu.org/software/parallel/) be installed on your machine.

A number of programs must also be in the path including Aliscore, Alicut, MAFFT PhyloTreePruner, HaMStR (for nentferner.pl), and the uniqHaplo.pl script.

The path for AlignmentCompare (packaged with this script) must be specified inside the script, and AlignmentCompare should be compiled beofer running this script

A number of variables must be modified for your purposes within the bash script. We suggest you examine the entire script carefully and modify it as needed.

Input fasta file headers must be in the following format: >orthology_group_ID|species_name_abbreviation|annotation_or_sequence_ID_information

Example: >0001|LGIG|Contig1234

Fasta headers may not include spaces or non-alphanumeric characters except for underscores (pipes are OK as field delimiters only).
