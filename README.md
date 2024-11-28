# SchemaNLP
Automated Scoring of Schematic Content using Natural Language Processing.

Remembering past events and imagining future events requires individuals to draw on their knowledge of what typically happens in a situation (i.e., schemas). To enable researchers to study schemas, we developed a measure of typical content in narratives. We used GloVe to create large dictionaries of relevant content (e.g., containing words like “sand” and “waves” for the memory cue ‘beach’). To get schema-counts, we counted how many words in each narrative (e.g., a beach narrative) were found in the relevant dictionary (e.g., a word list of beach-related words). We used this measure in a recent study ([Wynn et al., 2022](https://www.sciencedirect.com/science/article/pii/S1053810022000344?casa_token=x0LIK_gDaRsAAAAA:6LItAH6udi70-SEGwkJ3i3QAlHiqvzMIz9cPwRVPGzZch0Wgb-Ucf49ktBYPjMs4mdY9lSv-mQ)).
  
  
Practicalities:
  
  
Data setup when using code:  
 -- .csv file with:  
   -- four columns entitled Subject, Trial,	Cue, Transcript  
   -- Subject is a number, trial is a number, cue is word (e.g. 'beach'), and transcript is the text.  
 
You will need to edit the code to point to your csv file. Your scores will be written out in the same folder as your code.
Even if you do not edit the code, please read through the comments in the code before use, since they provide some helpful context for what it's doing.

Last, you need to download GloVe before running the code. You can find the .Rdata file on google drive [here](https://drive.google.com/file/d/13huoIUVwwvOMr-pRAAI81hMzBnhL93rF/view). Once you've downloaded this file, place it in the same folder as the code.

Your computer should have extra space on it: downloading GloVe, which we use for creating the dictionaries, will take up ~ 3GB. Please note that the code takes quite a while to run.

The code provided here will produce scores according with methods described in Wynn et al., 2022. Work is ongoing to extensively validate this approach.

Feel free to reach out to the authors with any questions. We can be contacted at r.vangenugten@northeastern.edu and jordwynn@uvic.ca
