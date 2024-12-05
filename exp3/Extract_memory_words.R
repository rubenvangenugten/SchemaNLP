# ---------------------------------------------------------------
# Script: Extract Words and Word Counts per Cue from Transcripts
# Description:
# This script processes narrative transcripts to extract, for each cue,
# all the words that occur in the associated transcripts (after stopwords
# are removed), along with the counts for each of those words.
# ---------------------------------------------------------------

#### ---- Load Required Packages ---- ####

# Install and load 'pacman' package if not already installed
if (!require("pacman")) {
  install.packages("pacman")
  library(pacman)
}

# Load necessary packages using 'pacman'
pacman::p_load(
  dplyr,        # Data manipulation
  stringr,      # String operations
  tidyverse,    # Data science packages
  tidytext,     # Text mining
  textstem,     # Text stemming and lemmatization
  stopwords     # Stopwords lists
)

#### ---- Set Working Directory (Optional) ---- ####

# Optionally set the working directory to the location of this script

currentPath <- dirname(rstudioapi::getActiveDocumentContext()$path)
setwd(currentPath)

#### ---- Read in Data ---- ####

# Read the transcriptions data (ensure the file is in the working directory)
# Replace 'transcriptions_all.csv' with the path to your CSV file if needed

# Data Setup:
# Input file: 'transcriptions_all.csv' with the following columns:
# - Subject: Numeric identifier for the subject
# - Trial: Numeric identifier for the trial
# - Cue: The cue word or phrase
# - Transcript: The text transcript to be analyzed

story <- read.csv('SchemaNLP_git/transcriptions_all.csv', stringsAsFactors = FALSE)

# Check the first few rows of the data
head(story)

#### ---- Define Stopwords ---- ####

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

#### ---- Tokenize and Clean Data ---- ####

# Add an index column to keep track of each narrative
story$index <- 1:nrow(story)

# Convert the story data frame to a tibble and rename 'Transcript' to 'text' if needed
# If your transcript column has a different name, adjust accordingly

story_tibble <- story %>%
  as_tibble() %>%
  rename(text = Transcript) %>%  # Ensure the transcript column is named 'text'
  mutate(
    text = as.character(text),
    Cue = as.factor(Cue),
    Subject = as.factor(Subject),
    Trial = as.integer(Trial),
    index = as.integer(index)
  )

# Check the structure of the tibble
glimpse(story_tibble)

# Tokenize the text into one-word-per-row format
tidy_story <- story_tibble %>%
  unnest_tokens(word, text)

# Remove stopwords and lemmatize words
tidy_story_clean <- tidy_story %>%
  anti_join(get_stopwords()) %>%          # Remove standard stopwords
  anti_join(myStopwordsTibble, by = "word") %>%  # Remove custom stopwords
  mutate(word = textstem::lemmatize_words(word))  # Lemmatize words

# Check the first few rows of the cleaned data
head(tidy_story_clean)

#### ---- Extract Words and Counts per Cue ---- ####

# Group the data by Cue and word, then count the occurrences
cue_word_counts <- tidy_story_clean %>%
  group_by(Cue, word) %>%
  summarise(count = n(), .groups = 'drop') %>%
  arrange(Cue, desc(count))

# View the first few rows of the result
head(cue_word_counts)

# Filter words that appear more than 5 times for each cue
frequent_words <- cue_word_counts %>%
  filter(count > 1)

#### ---- Save the Results ---- ####

# Write the counts to a CSV file
write.csv(cue_word_counts, 'cue_word_counts.csv', row.names = FALSE)

# Print message when done
cat("Word counts per cue have been saved to 'cue_word_counts.csv'\n")


#### ---- Calculate Overall Proportion of Words Occurring Only Once ---- ####

# Total number of word tokens in the entire dataset
total_tokens <- nrow(tidy_story_clean)

# Compute word counts across the entire dataset
word_counts <- tidy_story_clean %>%
  group_by(word) %>%
  summarise(count = n(), .groups = 'drop')

# Identify words that occur only once
words_occurring_once <- word_counts %>%
  filter(count == 1)

# Number of tokens that are words occurring only once
tokens_occurring_once <- tidy_story_clean %>%
  filter(word %in% words_occurring_once$word) %>%
  nrow()

# Calculate the proportion of tokens that are words occurring only once
proportion_tokens_occurring_once <- tokens_occurring_once / total_tokens

# Display the result
cat("Overall Proportion of Tokens Accounted for by Words Occurring Only Once:", proportion_tokens_occurring_once, "\n\n")

#### ---- Calculate Proportion of Words Occurring Only Once Per Cue ---- ####

# Compute word counts per cue
cue_word_counts <- tidy_story_clean %>%
  group_by(Cue, word) %>%
  summarise(count = n(), .groups = 'drop')

# Calculate total tokens and tokens of words occurring only once per cue
proportions_per_cue <- cue_word_counts %>%
  group_by(Cue) %>%
  summarise(
    total_tokens = sum(count),
    tokens_occurring_once = sum(count == 1),
    proportion_occurring_once = tokens_occurring_once / total_tokens
  )

# Display the results per cue
print(proportions_per_cue)

# Optionally, write the results to a CSV file
# write.csv(proportions_per_cue, 'proportions_per_cue.csv', row.names = FALSE)


