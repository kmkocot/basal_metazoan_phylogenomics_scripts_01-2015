import java.io.*;
import java.util.ArrayList;

public class AlignmentCompare {

	public static void main(String[] args) throws IOException {

		boolean notFinished = true;
		String line1;
		String line2;
		String writeLine;
		int overlaps;
		int badLine;
		int i;
		int j;
		
		//Dr. Steve Brule has an opinion on not providing input files.
		if (args[0] == null) {
			System.out.print("Ever wonder why ice cubes taste so boring? " +
					"It’s cuz you make ‘em outta stupid water, you bimbo! " +
					"Put some fruit juice in there and freeze it into ice " +
					"cubes, and put THAT in your milk. " +
					"Also, gimme a file to run this on, ya dummy!)");
			System.exit(0);
		}
		//Runs until each line overlaps with every other by at least 20.
		while (notFinished) {
			File alignmentFilename = new File(args[0]);
			File tempFilename = new File("myTempFile.txt");
			
			//Reader for iterating through lines to be compared.
			BufferedReader AlignmentReader1 = new BufferedReader(
					new FileReader(alignmentFilename));
			//Reader for going through remaining lines to compare to Reader1 lines.
			BufferedReader AlignmentReader2 = null;

			BufferedWriter AlignmentWriter = new BufferedWriter(new FileWriter(
					tempFilename));

			line1 = null;
			line2 = null;
			writeLine = null;
			overlaps = 0;
			badLine = 0;
			i = 0;
			j = 0;
			
			//ArrayList of ArrayList that holds the line numbers that don't overlaps
			// for each line.
			ArrayList<ArrayList<Integer>> noOverlaps = new ArrayList<ArrayList<Integer>>(
					0);
			//Stores the number of amino acids in each line.
			ArrayList<Integer> lineLengths = new ArrayList<Integer>(0);
			int lineToDelete;

			//While loop for comparisons of 1 line to each other line.
			while ((line1 = AlignmentReader1.readLine()) != null) {
				//ArrayList to keep track of the line numbers that don't overlap with
				// with the line currently being looked at.
				ArrayList<Integer> currentNoOverlaps = new ArrayList<Integer>(0);
				AlignmentReader2 = new BufferedReader(new FileReader(
						alignmentFilename));
				//If the current line is a header, skip it.
				if (line1.charAt(0) == '>') {
					line1 = AlignmentReader1.readLine();
					i++;
				}
				//Line 1 shouldn't be compared to line 1. Move down to the line after
				// the line that Reader1 just read.
				j = i;
				for (int inc = 0; inc < i; inc++) {
					@SuppressWarnings("unused")
					String temp = AlignmentReader2.readLine();

				}
				//Here we use Reader2 to start reading in all lines after Reader1's
				// current line for comparison.
				while ((line2 = AlignmentReader2.readLine()) != null) {
					//Skip headers
					if (line2.charAt(0) == '>') {
						line2 = AlignmentReader2.readLine();
						j++;
					}
					overlaps = 0;
					//Counting overlaps.
					for (int k = 0; k < line1.length() && k < line2.length(); k++) {
						//If both chars at position k aren't gaps, increment.
						if (checkForGaps(line1, k) == -1
								&& checkForGaps(line2, k) == -1) {
							overlaps++;
						}
					}
					//If we don't have more than 20 overlaps, add this line to our list.
					if (overlaps <= 20) {
						currentNoOverlaps.add(j);
					}
					j++;
				}
				//Reader2 has iterated through the whole file. Close reader2.
				AlignmentReader2.close();
				//Get the length of this line in amino acids.
				lineLengths.add(findLength(line1, i));
				//Add this line's results to the ArrayList of ArrayLists.
				noOverlaps.add(currentNoOverlaps);
				i++;
			}
			//Reader1 has iterated through the whole file. Close reader1.
			AlignmentReader1.close();
			
			//To determine which line is the worst and should be deleted, we
			// count the number of lines that don't overlap with it.
			int[] overlapCounts;
			overlapCounts = new int[noOverlaps.size()];

			for (int l = 0; l < noOverlaps.size(); l++) {
				for (int m = 0; m < noOverlaps.get(l).size(); m++) {
					badLine = noOverlaps.get(l).get(m);
					if (badLine != 0) {
						badLine = (badLine + 1) / 2;
						//Since comparisons don't go backwards(1 was recorded as not
						// overlapping with 2, but not vice versa) we need to account
						// for this.
						overlapCounts[badLine - 1]++;
						overlapCounts[l]++;
					}
				}
			}
			
			//Use findLargestAndSmallest to determine which line has the most lines that
			// do not overlaps with it.
			lineToDelete = findLargestAndSmallest(overlapCounts, lineLengths);
			
			//Stop when all lines overlap.
			if (lineToDelete == 0) {
				notFinished = false;
				break;
			}
			//Start readering in file for writing.
			AlignmentReader1 = new BufferedReader(new FileReader(
					alignmentFilename));

				// Find the lineToDelete and don't write it.
				i = 1;
				while ((writeLine = AlignmentReader1.readLine()) != null) {
					//Doubling lineToDelete to account for headers.
					if ((i != (lineToDelete * 2))
							&& ((i + 1) != (lineToDelete * 2))) {
						AlignmentWriter.write(writeLine);
						AlignmentWriter.newLine();
					}
					i++;
				}
			
			AlignmentReader1.close();
			AlignmentWriter.close();
			tempFilename.renameTo(alignmentFilename);
		}
	}

	//Method to check if the current char is a gap.
	public static int checkForGaps(String line, int inc) {
		String badChars = "-X?";
		int check = badChars.indexOf(line.charAt(inc));
		return check;
	}
	
	//Determines which line has the most non-overlapping lines and returns it.
	public static int findLargestAndSmallest(int[] integers,
			ArrayList<Integer> lengths) {
		boolean conflict = false;
		int largestNonOverlaps = 0;
		int smallestLength = 0;
		int position = 0;
		//If two lines have the same number of non-overlapping lines, this ArrayList
		// holds their positions.
		ArrayList<Integer> choices = new ArrayList<Integer>(1);
		
		//Checking which has the most non-overlaps.
		for (int i = 0; i < integers.length; i++) {
			if (integers[i] > largestNonOverlaps) {
				conflict = false;
				choices.clear();
				choices.add(i + 1);
				largestNonOverlaps = integers[i];
				//Save which line has the most non-overlaps.
				position = i + 1;
				//If equal to the current line with most non-overlaps,
				// add to choices without clearing it.
			} else if (integers[i] == largestNonOverlaps) {
				conflict = true;
				choices.add(i + 1);
			}
		}
		//If there are no overlaps, we're done.
		if (largestNonOverlaps == 0) 
			return 0;
		//If two lines have the same amount of non-overlapping lines,
		// find the one with the smallest number of amino acids.
		if (conflict) {
			smallestLength = lengths.get(choices.get(0));
			position = choices.get(0);
			for (int j = 1; j < choices.size(); j++) {
				if (lengths.get((choices.get(j)-1)) < smallestLength) {
					smallestLength = lengths.get((choices.get(j)-1));
					position = choices.get(j);
				}
			}
		}
		//Returns the line number of line with the most non-overlaps/smallest length
		// of amino acids.
		return position;
	}
	
	//Finds the length in amino acids of a line.
	public static int findLength(String line, int position) {
		int length = 0;
		for (int i = 0; i < line.length(); i++) {
			if (checkForGaps(line, i) == -1)
				length++;
		}
		return length;
	}
}
