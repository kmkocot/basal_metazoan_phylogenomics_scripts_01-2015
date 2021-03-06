#!/bin/bash
#
# Developed by:
#	Kevin M. Kocot
#	Nathan V. Whelan
#	Damien Waits
#	Auburn University
#	Department of Biological Sciences
# 
# THIS SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS 
# OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL 
# THE CONTRIBUTORS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, 
# WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF 
# OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS WITH THE 
# SOFTWARE.


#This script takes the output of HAMSTR and performs several steps to remove groups and sequences that are not suitable for phylogenomic analysis.
#The final product of this script is a set of trimmed amino acid alignments representing putatively orthologous groups suitable for phylogenomic analysis.
#This version of the script requires GNU parallel be installed on your machine.
#A number of programs must also be in the path including Aliscore, Alicut, MAFFT PhyloTreePruner, HaMStR (for nentferner.pl), and the uniqHaplo.pl script.
#The path for AlignmentCompare (packaged with this script) must be specified inside the script and compiled prior to running this script.
#A number of variables must be modified for your purposes within the bash script. We suggest you examine the entire script carefully and modify it as needed.
#Input fasta file headers must be in the following format: >orthology_group_ID|species_name_abbreviation|annotation_or_sequence_ID_information
#Example: >0001|LGIG|Contig1234
#Fasta headers may not include spaces or non-alphanumeric characters except for underscores (pipes are OK as field delimiters only).


########################################################################
################## Change these before your first use ##################
########################################################################
#Set values for variables
MIN_SEQUENCE_LENGTH=50 #Deletes original seqs shorter than this length
MIN_ALIGNMENT_LENGTH=50 #Minimum length of a trimmed alignment in amino acids
MIN_TAXA=37 #Minimum number of OTUs to keep an OG
CORES=2 #NUMBER OF CORES TO USE IN PARALLEL
CLASS_PATH=/usr/local/genome/bin/ #Location of PhyloTreePruner and Alignment Compare .class files
########################################################################


#Backup all sequences
echo "Making a backup of all sequences before beginning..."
mkdir unedited_sequences
cp *.fa ./unedited_sequences/
echo
echo Done
echo


#Use nentferner.pl to remove newlines.
echo "Removing linebreaks in sequences using nentferner.pl"
for FILENAME in *.fa
do
nentferner.pl -in=$FILENAME -out=$FILENAME.nent
done
rename .fa.nent .fa *.fa.nent
echo Done
echo


#Changes any name that was XSP. to XSPP and removed anything after the first space in the fasta header
#This step was specific to one taxon naming issue in this analysis and probably won't be relevant to other users
#PLEASE CHECK THAT THESE STEPS ARE APPROPRIATE FOR YOUR FASTA HEADERS BEFORE RUNNING

echo "Fixing taxon abbreviations..." 
#sed -i 's/SP.|/SPP|/' *.fa
sed -i 's/ .*//g' *.fa
sed -i 's/(//g' *.fa
sed -i 's/)//g' *.fa
sed -i 's\./\_/g' *.fa
sed -i 's/:/\_/g' *.fa


#Delete sequences shorter than $MIN_SEQUENCE_LENGTH
echo "Deleting sequences shorter than $MIN_SEQUENCE_LENGTH AAs..."
for FILENAME in *.fa
do
grep -B 1 "[^>].\{$MIN_SEQUENCE_LENGTH,\}" $FILENAME > $FILENAME.out
sed -i 's/--//g' $FILENAME.out
sed -i '/^$/d' $FILENAME.out
rm -rf $FILENAME
mv $FILENAME.out $FILENAME
done
echo Done
echo


#If fewer than $MIN_TAXA different species are represented in the file, move that file to the "rejected_few_taxa" directory. 
echo "Removing groups with fewer than $MIN_TAXA taxa..."
mkdir -p rejected_few_taxa_1
for FILENAME in *.fa
do
awk -F"|" '/^>/{ taxon[$2]++ } END{for(o in  taxon){print o,taxon[o]}}' $FILENAME > $FILENAME\.taxon_count #Creates temporary file with taxon abbreviation and number of sequences for that taxon in $FILENAME
taxon_count=`grep -v 0 $FILENAME\.taxon_count | wc -l` #Counts the number of lines with an integer >0 (= the number of taxa with at least 1 sequence)
if [ "$taxon_count" -lt "$MIN_TAXA" ] ; then 
echo $FILENAME
mv $FILENAME ./rejected_few_taxa_1/
fi
done
rm -rf *.taxon_count
echo Done
echo


#List the remaining OTUs.
echo "List of OTUs:"
cat *.fa | awk -F"|" '{print $2}' | sed 's/^$//g' | sort | uniq
echo


#Remove redundant sequences using uniqHaplo
echo "Removing redundant sequences using uniqHaplo..."
#THIS IS THE PARALLEL VERSION
ls *.fa | parallel -j $CORES 'uniqHaplo.pl -a {} > {}.uniq'
rename .fa.uniq .fa *.fa.uniq
echo Done
echo


#If one of the first 20 characters of a sequence is an X, that X and all characters before it are removed
echo "Trimming 5' ends..."
for FILENAME in *.fa
do
sed 's/^[^>]\{,19\}X//' $FILENAME > $FILENAME.trim
done
rename .fa.trim .fa *.fa.trim
echo Done
echo


#If one of the last 20 characters of a sequence is an X, that X and all characters after it are removed
echo "Trimming 3' ends..."
for FILENAME in *.fa
do
sed '/>/! s/X.\{,19\}$//' $FILENAME > $FILENAME.trim
done
rename .fa.trim .fa *.fa.trim
echo Done
echo


#Align the remaining sequences using Mafft.
mkdir preAlignment
cp *.fa preAlignment
echo "Aligning sequences using Mafft (auto)..."
mkdir backup_alignments
###THIS IS THE PARALLEL VERSION
ls *.fa | parallel -j $CORES 'mafft --auto --localpair --maxiterate 1000 {} > {}.aln'
###THIS IS THE PARALLEL VERSION
rm -rf *.fa
rename .fa.aln .fa *.fa.aln
cp *.fa ./backup_alignments/
echo Done
echo


#Use nentferner.pl to remove newlines.
echo "Removing linebreaks in sequences using nentferner.pl"
for FILENAME in *.fa
do
nentferner.pl -in=$FILENAME -out=$FILENAME.nent
done
rename .fa.nent .fa *.fa.nent
echo Done
echo


#Trim alignments using aliscore and alicut
echo "Trimming alignments in aliscore and alicut..."
##GET HEADERS RIGHT! Aliscore and alicut do not like the "|" symbol
sed -i 's/|/\_/g' *.fa ##MAKE ALL | underscores
sed -i 's/\_/@/' *.fa #CHANGES First Underscore to @
echo Done
echo


#Trim alignments using aliscore and alicut
echo "Trimming alignments in aliscore and alicut..."
##PARALLEL VERSION
ls *.fa | parallel -j $CORES 'perl /usr/local/genome/bin/aliscore.pl -N -e -i {}'
##PARALLEL VERSION
perl /usr/local/genome/bin/alicut.pl s ##RUNS ALICUT AFTER ALISCORE
#POST ALICUT
mkdir alicut_files
mv [0-9]*.fa ./alicut_files/
mv *.txt ./alicut_files/
mv *.svg ./alicut_files/
##TO RENAME ALICUT FILES!!
for FILE in ALICUT_*.fa
do
NAME=`echo $FILE | sed 's/ALICUT_//'`
mv $FILE $NAME.out
rename .fa.out .fa *.fa.out
sed -i 's/@/|/' *.fa ##CHANGES @ BACK TO |
sed -i 's/\_/|/' *.fa
echo "Aliscore and Alicut have finished"
done


#Use nentferner.pl to remove newlines.
echo "Removing linebreaks in sequences using nentferner.pl"
for FILENAME in *.fa
do
nentferner.pl -in=$FILENAME -out=$FILENAME.nent
done
rename .fa.nent .fa *.fa.nent
echo Done
echo


#Remove spaces in sequences and delete gap-only columns and columns with four or fewer non-gap characters.
#This is somewhat complicated awk min-program, but it works...
echo "Removing gap-only columns..." 
for FILENAME in *.fa
do
awk 'BEGIN { FS = "" }
!/^>/ { \
  sequence[NR] = $0 
  for ( i = 1; i <= NF; i++ ) \
    position[i] += ($i ~ /[A-WY-Z]/) \
} \
/^>/ { \
  header[NR] = $0 \
} \
END { \
  for ( j = 1; j <= NR; j++ ) { \
    if ( j in header) print header[j]
    if ( j in sequence ) { 
    $0 = sequence[j]
    for ( i = 1; i <= NF; i++)
    if ( position[i] > 4 ) printf "%s", $i
    printf "\n"
    } \
  } \
}' $FILENAME > $FILENAME.nogaps
done
rename .fa.nogaps .fa *.fa.nogaps
echo Done
echo


#Move trimmed alignments shorter than $MIN_ALIGNMENT_LENGTH AAs to the short_alignment folder.
echo "Moving alignments shorter than $MIN_ALIGNMENT_LENGTH AAs to the rejected_short_alignment folder..."
mkdir -p rejected_short_alignment
for FILENAME in *.fa
do
length=`awk '!/^>/{ lines++; total+= length($1) } END { average=total/(lines); printf(average);}' $FILENAME`
if [ "$length" -lt "$MIN_ALIGNMENT_LENGTH" ] ; then 
mv $FILENAME ./rejected_short_alignment/
fi
done
echo Done
echo


#Remove any sequences that don't overlap with all other sequences by at least 20 amino acids. 
echo "Removing short sequences that don't overalp with all other sequences by at least 20 AAs..."
for FILENAME in *.fa
do
java -cp $CLASS_PATH AlignmentCompare $FILENAME 
done
echo Done
echo
rm -rf myTempFile.txt


#If fewer than $MIN_TAXA different species are represented in the file, move that file to the "rejected_few_taxa_2" directory
echo "Removing groups with fewer than $MIN_TAXA taxa..."
mkdir -p rejected_few_taxa_2
for FILENAME in *.fa
do
awk -F "|" '/^>/{ taxon[$2]++ } END{for(o in taxon){print o,taxon[o]}}' $FILENAME > $FILENAME\.taxon_count 
taxon_count=`grep -v 0 $FILENAME\.taxon_count | wc -l` #Counts the number of lines with an integer >0 (i.e. the number of taxa for each OG)
if [ "$taxon_count" -lt "$MIN_TAXA" ] ; then 
echo $FILENAME
mv $FILENAME ./rejected_few_taxa_2/
fi
done
rm *.fa.taxon_count
echo Done
echo

#Backup .fa files and then edit headers for downstream steps
echo "Making a backup of remaining .fa files and changing headers to remove OG number before making single copy alignments"
mkdir backup_pre-PhyloTreePruner
cp *.fa ./backup_pre-PhyloTreePruner/
sed -i 's/>[0-9][0-9][0-9][0-9]|/>/g' *.fa ##CHANGE IF YOUR OGs HAVE MORE THAN FOUR ZEROS !!! (e.g. if five change to 's/>[0-9][0-9][0-9][0-9][0-9]|/>/g')
sed -i 's/|/\_/' *.fa 
sed -i 's/\_/@/' *.fa
echo Done
echo


#Make single-gene trees in FastTree
echo "Making single-gene trees in FastTree..."
export OMP_NUM_THREADS=$CORES ##This tells fast tree to only use the number of cores used in other parallel steps
for FILENAME in *.fa
do
FastTreeMP -slow -gamma $FILENAME > $FILENAME.tre
done
rename .fa.tre .tre *.fa.tre
echo Done
echo


#Screen for overlooked paralogs with PhyloTreePruner
echo "Examining single-gene trees for evidence of paralogy with PhyloTreePruner..."
for FILENAME in *.tre
do
ORTHOLOGY_GROUP=`echo $FILENAME | cut -d . -f 1 | sed 's/.\+\///g'`
echo $ORTHOLOGY_GROUP
###################################################################################
####You may want to change some of the PhyloTreePruner settings in the next line###
############See PhyloTreePruner Manual for more information########################
###################################################################################
java -cp $CLASS_PATH PhyloTreePruner $ORTHOLOGY_GROUP".tre" $MIN_TAXA $ORTHOLOGY_GROUP".fa" 0.99 u  
done
echo Done


