#---
# Author: Ruben van Genugten
# Title: "Automated Scoring of Schematic Content using Natural Language Processing"
# Code for use in Wynn et al. (2022)
# Updated on 11/27/24 to improve readability and usability
#---

# Data Setup:
# Input file: 'transcriptions_all.csv' with the following columns:
# - Subject: Numeric identifier for the subject
# - Trial: Numeric identifier for the trial
# - Cue: The cue word or phrase
# - Transcript: The text transcript to be analyzed


# Overview of the Code:
# - Load required libraries and GloVe data
# - Read in data to score
# - Perform basic data cleaning, including removal of stopwords
# - Define function to calculate similarities between words using GloVe embeddings
# - Use similarity function to identify similar words for each cue (e.g., 'sand' for 'bbeach')
# - Process narratives. For each word in a narrative, identify whether it belongs to the schema based on similarity

# User Checks:
# 1. Rename cues if necessary. GloVe works with individual words, so replace multi-word cues (e.g., "thanksgiving dinner") with single words (e.g., "thanksgiving").
# 2. After running the code, check the word lists used (written out in 'schema_dictionaries.csv') to ensure words align with the intended meaning.
#    - Sometimes, you will need to change your cue word ('stream' -> 'river' or 'forest') to ensure you are capturing the anticipated meaning (e.g., stream may create a list of netflix related words instead)


#### ---- Set Working Directory ---- ####

# Set working directory to the location of this script
currentPath <- dirname(rstudioapi::getActiveDocumentContext()$path)
setwd(currentPath)

#### ---- Load in Packages ---- ####

# Install and load 'pacman' package if not already installed
if (!require("pacman")) {
  install.packages("pacman")
  library('pacman')
}

# Load necessary packages using 'pacman'
pacman::p_load(
  openxlsx, dplyr, ggplot2, ggpubr, stringr, glue, qdap, #hablar,
  textstem, text2vec, qdapDictionaries, tm, wordcloud, lexicon,
  textclean, tidyverse, tidytext, caret
)

# Note: Conflicts may occur between packages (e.g., 'dplyr' and others).
# If unexpected errors arise, check for conflicting functions.

#### ---- Read in data ---- ####

# Read the transcriptions data (ensure the file is in the working directory)
# that is, place your data in the same folder as your code, or specify the full path
story <- read.csv('transcriptions_all.csv')

#### ----- Load GloVe Embedding Matrix ----- ####

# Load GloVe data (this may take a while). 
# glove.Rdata should be in the same folder as the code, or specify the full path/location
load('glove.Rdata')

#### ---- Define Additional Stopwords to Remove  ---- ####

# Stop-words are words that don't carry much meaning, or words that we don't want to count
# Removing these reduces the noise in our analyses.

# Custom stopwords to exclude from analysis
myStopwords <- c(
  "like", "just", "can", "people", "around", "yeah", "see", "uh", "really", "um",
  "kind", "one", "lot", "it's", "i'm", "nice", "there's", "get", "time", "also",
  "know", "hear", "smell", "touch"
)

# Include cue words to prevent them from being counted as details
cueNames <- unique(as.character(story$Cue))
cueNames <- c(cueNames, tolower(cueNames))  # Include lowercase versions

# Combine with stopwords from various sources
# tm stopwords, snowball & SMART stopwords are already used by tidytext
quanteda_stopwords1 <- stopwords::stopwords(language = 'en', source = 'nltk')
quanteda_stopwords2 <- stopwords::stopwords(language = 'en', source = 'stopwords-iso')

# Load additional stopwords from 'lexicon' package
data(sw_loughran_mcdonald_long)
lexicon_stopwords1 <- sw_loughran_mcdonald_long

# Merge all stopwords into one vector and remove duplicates
myStopwords <- unique(c(
  myStopwords, quanteda_stopwords1, quanteda_stopwords2,
  lexicon_stopwords1, cueNames
))
  
myStopwordsTibble <- tibble(word = myStopwords)

#### ----- Basic Data Cleaning ----- ####

# Cast all words to lowercase and strip additional whitespace (e.g. two spaces in between words),
# Lemmatize, which involves turning words into their base form (e.g. 'cars' -> 'car')
# We are using the tidy text format (https://www.tidytextmining.com/) for further analysis
# This format involves one-token-per-row, where a token is a unit of text like a word
# This involves modifying the data format. Let's start:

# Add an index column to keep track of each narrative
story$index <- 1:nrow(story)

# Convert the story data frame to a tibble and rename 'Transcript' to 'text'
story_tibble <- tibble(story)
story_tibble<- dplyr::rename(story_tibble,
                             text = Transcript)

story_tibble <- story_tibble %>%
  mutate(
    Trial = as.integer(Trial),
    index = as.integer(index),
    Cue = as.factor(Cue),
    Subject = as.factor(Subject),
    text = as.character(text)
  )

# Split the text into one-word-per-row format (tokenize)
tidy_story <- story_tibble %>%
  unnest_tokens(word, text)

# Remove stopwords and then lemmatize words (reduce to base form; running -> run)
tidy_story_clean <- tidy_story %>% 
  anti_join(get_stopwords()) %>% 
  anti_join(myStopwordsTibble) %>%
  mutate(word_lemma = textstem::lemmatize_words(word)) # Automatically lowercases words

head(tidy_story_clean) # inspect the data

#### ----- Define functions for similarity of words ----- ####

# Function to find the top N most similar words to a given word using GloVe embeddings
find_similar_words <- function(word, embedding_matrix, n = 5) {
  similarities <- sim2(
    embedding_matrix,
    embedding_matrix[word, , drop = FALSE],
    method = "cosine"
  )
  similarities[, 1] %>%
    sort(decreasing = TRUE) %>%
    head(n)
}

# Function to compute the schema score for a narrative based on a cue
get_schema_score <- function(cue, narrative, numWords){
  mostSimilarWords <- cue_topSimilarities[[as.character(cue)]]
  mostSimilarWords <- names(mostSimilarWords)
  mostSimilarWords <- mostSimilarWords[1:numWords] 
  words_inNarrative <- mostSimilarWords[mostSimilarWords %in% as.character(narrative$word)]
  narrativeDf_onlyTopXWords <- narrative[narrative$word %in% words_inNarrative,]
  totalWords_withTopX <- nrow(narrativeDf_onlyTopXWords)
  
  return(list(totalWords_withTopX, narrativeDf_onlyTopXWords))
}

# Function to compute the mismatch schema score using other cues
get_schema_mismatch_score <- function(cue, narrative, numWords){
  mismatchCues <- allCues[allCues != as.character(cue)]
  detailCounts <-c()
  for(myCue in mismatchCues){
    detailCounts <- c(detailCounts, get_schema_score(myCue, narrative, numWords)[[1]])
  }
  mean_misMatchDetails <- mean(detailCounts)
  return(mean_misMatchDetails)
}

#### ----- Compute Similar Words for Each Cue ----- ####

# This is a preparatory step. For each cue, find a list of 50000 most similar words
# We do this so that we can later access the stored similar words.
# If we want to use the 10,000 most similar words, our functions allow you to pare down later.
# But this prep allows us to not re-compute a time-consuming step every time.

# Retrieve all unique cues
allCues <- unique(as.character(tidy_story_clean$Cue))

# Initialize a list to store top similar words for each cue
cue_topSimilarities <- list()
numSimilarWords <- 50000  # Number of similar words to retrieve

# Find similar words for each cue
for (cue in allCues) {
  cue_topSimilarities[[cue]] <- find_similar_words(
    cue,
    embedding_matrix,
    numSimilarWords
  )
}

# Optionally save the computed similarities to avoid rerunning
# save(cue_topSimilarities, file = 'cue_topSimilarities.RData')

# Optionally load the computed similarities
# load('cue_topSimilarities.RData')

# Save the word lists so that we can examine them for sanity checking.
cue_dictionaryWords <- lapply(cue_topSimilarities, names)
cue_dictionaryWords_df <- as.data.frame(cue_dictionaryWords)
write.csv(cue_dictionaryWords_df, 'schema_dictionaries.csv', row.names = FALSE)


#### ----- Annotate All Narratives ----- ####

# Prepare a data frame to store the results.
# Take the existing dataframe and add columns to fill in.
story_scores <- story
story_scores$nonStopword_wordCount <- NULL
story_scores$SchemaWordsCount <- NULL
story_scores$SchemaWordsIdentified <- NULL
story_scores$SchemaMismatchCount <- NULL

# how big are we going to make our word lists/dictionaries?
num_similar_words_to_use <- 10000

# Process each narrative to compute schema scores.
for(i in unique(tidy_story_clean$index)) {
  thisStory <- tidy_story_clean[tidy_story_clean$index == i,]
  whichCue <- as.character(thisStory$Cue[1])

  schema_out <- get_schema_score(whichCue, thisStory, num_similar_words_to_use)
  story_scores[story_scores$index==i, "nonStopword_wordCount"] <- nrow(thisStory) ## get total number of words (excluding stop words) in narrative
  story_scores[story_scores$index==i, "SchemaWordsCount"] <- schema_out[[1]]
  story_scores[story_scores$index==i, "SchemaWordsIdentified"] <- schema_out[[2]]$word %>% paste(collapse = " ")
  story_scores[story_scores$index==i, "SchemaMismatchCount"] <- get_schema_mismatch_score(whichCue, thisStory, num_similar_words_to_use)
}

# Write the annotated narratives to a CSV file
write.csv(story_scores, 'narratives_scores.csv')


