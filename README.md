# SchemaNLP
Automated Scoring of Schematic Content using Natural Language Processing.

Remembering past events and imagining future events requires individuals to draw on their knowledge of what typically happens in a situation (i.e., schemas). To enable researchers to study schemas, we developed a measure of typical content in narratives. We used GloVe to create large dictionaries of relevant content (e.g., containing words like “sand” and “waves” for the memory cue ‘beach’) and counted overlapping narrative and dictionary words. We used this measure in a recent study ([Wynn et al., 2022](https://www.sciencedirect.com/science/article/pii/S1053810022000344?casa_token=x0LIK_gDaRsAAAAA:6LItAH6udi70-SEGwkJ3i3QAlHiqvzMIz9cPwRVPGzZch0Wgb-Ucf49ktBYPjMs4mdY9lSv-mQ)) with a more comprehensive validation currently underway.
  
  
Practicalities:
  
  
Data setup when using code:  
 -- .csv file with:  
   -- four columns entitled Subject, Trial,	Cue, Transcript  
   -- Subject is a number, trial is a number, cue is word (e.g. 'beach'), and transcript is the text.  
 
You will need to edit the code to point to your csv file. Your scores will be written out in the same folder as your code.
Even if you do not edit the code, please read through the comments in the code before use, since they provide some helpful context for what it's doing.

Last, you need to download GloVe before running the code. You can find the .Rdata file on google drive [here](https://drive.google.com/drive/u/0/folders/1kkXZo6iN0yGqKZ8SgVy11jIImv8s1gpd). Once you've downloaded this file, place it in the same folder as the code.

Your computer should have extra space on it: downloading GloVe, which we use for creating the dictionaries, will take up ~ 3GB. Please note that the code takes quite a while to run, so just have it run overnight.

The code provided here will produce scores according with methods described in Wynn et al., 2022. Additional code used for validation of the measure in the paper will be uploaded soon. Glove.Rdata will also be added to github soon, so that manual download from the google drive link above is no longer necessary.

Feel free to reach out to the authors with any questions. We can be contacted at ruben_vangenugten@g.harvard.edu and jordwynn@uvic.ca
