# basal_metazoan_phylogenomics_scripts_01-2015
Scripts used for basal metazoan phylogenomics

This script takes the output of HAMSTR and performs several steps to remove groups and sequences that are not suitable for phylogenomic analysis.

The final product of this script is a set of trimmed amino acid alignments representing putatively orthologous groups suitable for phylogenomic analysis.

This version of the script requires GNU parallel be installed on your machine.

A number of programs must also be in the path including Aliscore, Alicut, MAFFT PhyloTreePruner, and the uniqHaplo.pl script.

The path for AlignmentCompare (packaged with this script) must be specified inside the script. 

A number of variables must be modified for your purposes within the bash script. We suggest you examine the entire script carefully and modify it as needed.
