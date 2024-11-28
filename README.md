# SchemaNLP: Automated Scoring of Schematic Content using Natural Language Processing.

Remembering past events and imagining future events often requires individuals to draw upon schematic knowledge, or knowledge about what typically happens in situations. To enable researchers to study schemas, we developed a measure of typical content in narratives. This script automates the scoring of schematic content in narratives by:

-    Using GloVe embeddings to create dictionaries of words related to specific cues.
-    Counting how many words in each narrative match the relevant dictionary.

A dictionary is simply a list of relevant words. To illustrate this with an example, a dictionary for the cue 'beach' would contain words like 'sand' and 'waves'. We used this measure in a recent study ([Wynn et al., 2022](https://www.sciencedirect.com/science/article/pii/S1053810022000344?casa_token=x0LIK_gDaRsAAAAA:6LItAH6udi70-SEGwkJ3i3QAlHiqvzMIz9cPwRVPGzZch0Wgb-Ucf49ktBYPjMs4mdY9lSv-mQ)), and are continuing to develop and validate this approach.




Below, we provide some information on how to use this code.

**Prerequisites**

Before running the script, ensure you have:
- R and RStudio installed on your computer.
- GloVe embeddings downloaded (glove.Rdata). You can find the .Rdata file on google drive [here](https://drive.google.com/file/d/13huoIUVwwvOMr-pRAAI81hMzBnhL93rF/view)
- Enough space on your computer for the 3GB download of GloVe

**Data Preparation**

Your input data should be a CSV file named transcriptions_all.csv, containing the following columns:

- Subject: Numeric identifier for the subject.
- Trial: Numeric identifier for the trial.
- Cue: The cue word or phrase (e.g., "beach").
- Transcript: The text narrative to be analyzed.


Note: Ensure that the cue words are single words compatible with GloVe embeddings. If your cues are multi-word phrases (e.g., "thanksgiving dinner"), simplify them to single words (e.g., "thanksgiving").

  
**Setting Up the Environment**

- Move GloVe Embeddings: Place the glove.Rdata file you downloaded in the same folder as the code script.
- Move Your Data: Place transcriptions_all.csv in the same folder as the code script. Alternatively, update the code to point to its location.


**Running the Script**

- Double Check to Ensure All Files Are in the Right Place: The code, transcriptions_all.csv, and glove.Rdata should be in the same folder.
- Open the Script in Rstudio.
- Review the Script: Before running, read through the comments. You should be able to use it without making code changes, but feel free to of course.
- Run the Script: Execute the script in RStudio. This may take some time, especially loading GloVe embeddings and computing similarities. 

**Interpreting the Output**

Output Files:
- schema_dictionaries.csv: Contains the lists of words similar to each cue.
- narratives_scores.csv: DataFrame with your schema scores for each narrative!
    - Key columns:
      - nonStopword_wordCount: Total number of words in the narrative after removing stopwords. Stopwords are common or filler words (e.g., 'the', 'and', etc.)
      - SchemaWordsCount: Number of words matching the schema dictionary.
      - SchemaWordsIdentified: The actual words identified as schema-related.
      - SchemaMismatchCount: Baseline score using other cues for comparison. (e.g., using all non-beach dictionarires for calculating schema scores for a beach narrative)


Understanding Schema Scores:
- Schema Words Count: Higher counts indicate that the narrative contains more words related to the cue.
- Mismatch Count: Provides a baseline to compare against, representing chance levels of schema word occurrence.

**Customization and Tips** 

- Adjusting Number of Similar Words: You can change num_similar_words_to_use to include more or fewer words in the schema dictionaries.
- Reviewing Cue Words: After inspecting schema_dictionaries.csv, you may find that certain cue words don't produce the expected related words. 
- Consider Changing the Cue: If a cue word doesn't capture the intended meaning (e.g., "stream" leading to "Netflix" related words), replace it with a more appropriate word (e.g., "river" or "forest").
- Updating Stopwords: Add any irrelevant but frequent words to myStopwords to exclude them from analysis.


**Troubleshooting**

- Slow Performance: The script may take a long time to run.  This is normal.
- Cue Words Not Found: If a cue word is not in the GloVe vocabulary: Choose an alternative word with a similar meaning. Verify that the cue word is correctly spelled and in lowercase.
- Error in Working with Data: Ensure that the data types are correct in your input .csv file. For example, ensure that participant is a de-identififed number rather than a de-identified string (e.g, 32 vs '32c4sx').

The code provided here will produce scores according with methods described in Wynn et al., 2022. Work is ongoing to extensively validate this approach.

Feel free to reach out to the authors with any questions. We can be contacted at r.vangenugten@northeastern.edu and jordwynn@uvic.ca
