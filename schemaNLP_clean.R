#---
# Author: Ruben van Genugten
# Title: "Automated Scoring of Schematic Content using Natural Language Processing"
# Code for use in Wynn et al. (2022) (https://www.sciencedirect.com/science/article/abs/pii/S1053810022000344)
# date: "1/28/2021"
#---


# Data setup when using code.
# input transcriptions_all.csv file with:
# four columns: Subject, Trial,	Cue, Transcript
# Subject is a number, trial is a number, cue is word, and transcript is the text.


# overview of code:
# load in libraries and GloVe data
# read in data to score
# basic data cleaning, including removal of stopwords (i.e. common words such as 'the')
# define functions to extract similarities between words, using GloVe
# for each word, identify whether it belongs 

# Checks to do by user: 
# 1:
# Rename cues if necessary. Glove works with individual words
# so, for example, replace the cue "thanksgiving dinner" with "thanksgiving"
# 2:
# After the code runs, check the word lists it used (written out in 'schema_dictionaries.csv')
# Sometimes many words will come from an alternative meaning of your cue word.
# for example,  'stream' may capture netflix related terms instead
# of the intended forest related terms. So, re-run with 'forest' as the new cue word in the input spreadsheet.


#### ---- Set Working Directory ---- ####

# set working directory to wherever this file is located
currentPath <- dirname(rstudioapi::getActiveDocumentContext()$path)
setwd(currentPath)

#### ---- Load in Packages ---- ####

if (!require("pacman")) {install.packages("pacman"); library('pacman')} 

p_load("openxlsx", "dplyr",
       "ggplot2", "ggpubr",
       "hablar",
       "stringr",
       "glue", "qdap",
       "textstem", 
       "text2vec",
       "qdapDictionaries", "tm",
       "wordcloud", "lexicon",
       "textclean",
       "tidyverse", "tidytext",
       "caret",
       "text2vec"
       ) 

# one thing to note: sometimes dplyr and other packages have conflicting
# functions. So, if we're getting unexpected error messages, that's the
# first place to look


#### ---- Read in data ---- ####

# must provide your folder location here (or just place it in the same folder as your code):

story <- read.csv('trascriptions_all.csv')

#### ----- Read in Glove matrix----- ####

# reading in glove data takes a while

load('glove.Rdata')


#### ---- Define non-tidytext stopwords to remove ---- ####

myStopwords = c("like" ,
                "just" ,
                "can",
                "people",
                "around",
                "yeah",
                "see",
                "uh",
                "really",
                "um",
                "kind",
                "one",
                "lot",
                "it\'s",
                "i\'m",
                "nice",
                "there's",
                "get",
                "time",
                "also",
                "know",
                "see",
                "hear",
                "smell",
                "touch"
)

cueNames <- story$Cue %>% unique() %>% as.character() # get all cue names, remove so they dont get counted as details
cueNames <- c(cueNames, cueNames %>% str_to_lower) # cast all cues to lowercase as well to remove those

# tm stopwords, snowball & SMART stopwords are already used by tidytext
quanteda_stopwords1 <- stopwords::stopwords(language = 'en', source = 'nltk')
quanteda_stopwords2 <- stopwords::stopwords(language = 'en', source = 'stopwords-iso')

data(sw_loughran_mcdonald_long)
lexicon_stopwords1 <- sw_loughran_mcdonald_long

myStopwords <- c(myStopwords, quanteda_stopwords1, quanteda_stopwords2, lexicon_stopwords1, cueNames)
myStopwordsTibble <- tibble(word = myStopwords)

#### ----- Basic data cleaning ----- ####

# remove stop-words (i.e. words that don't carry much meaning, or words that we don't want to count),
# all words to lowercase, strip additional whitespace (e.g. two spaces in between words),
# and lemmatizing (i.e. turn word into base form, e.g. 'cars' -> 'car')

# from https://www.tidytextmining.com/ --
# Tidy text format is a table with one-token-per-row. 
# A token is a meaningful unit of text, such as a word, 
# that we are interested in using for analysis, and tokenization 
# is the process of splitting text into tokens. This one-token-per-row structure
# is in contrast to the ways text is often stored in current analyses,
# perhaps as strings or in a document-term matrix.
# For tidy text mining, the token that is stored in each row is most often a single word, 
# but can also be an n-gram, sentence, or paragraph. 

# from our original dataframe, create a one-token-per-row dataframe
story$index <- 1:nrow(story)

story_tibble <- tibble(story)
story_tibble<- dplyr::rename(story_tibble,
                             text = Transcript)

story_tibble <- story_tibble %>% 
  convert(int(Trial, index),
          fct(Cue,Subject),
          chr(text))

tidy_story <- story_tibble %>%
  unnest_tokens(word, text)

tidy_story_clean <- tidy_story %>% 
  anti_join(get_stopwords()) %>% 
  anti_join(myStopwordsTibble) %>%
  mutate(word_lemma = textstem::lemmatize_words(word)) #automatically lower cases 


#### ----- Define functions for similarity of words ----- ####

# Purpose of each function:
#
# basis function for similarity: 
#
# find_similar_words
#     - find n words that are most similar to the seed word
#     - adapted from: https://blogs.rstudio.com/ai/posts/2017-12-22-word-embeddings-with-keras/

# applying this functions to get schema scores: 
# 
# get_schema_score
#     - for a narrative, and its corresponding cue, get schema score. return score and words identified.
# get_schema_mismatch_score
#     - for a narrative, take other cues, get schema scores based on if we were using different cues.

find_similar_words <- function(word, embedding_matrix, n = 5) {
  similarities <- embedding_matrix[word, , drop = FALSE] %>%
    sim2(embedding_matrix, y = ., method = "cosine")
  similarities[,1] %>% sort(decreasing = TRUE) %>% head(n)
}

get_schema_score <- function(cue, narrative, numWords){
  mostSimilarWords <- cue_topSimilarities[[as.character(cue)]]
  mostSimilarWords <- names(mostSimilarWords)
  mostSimilarWords <- mostSimilarWords[1:numWords] 
  words_inNarrative <- mostSimilarWords[mostSimilarWords %in% as.character(narrative$word)]
  narrativeDf_onlyTopXWords <- narrative[narrative$word %in% words_inNarrative,]
  totalWords_withTopX <- nrow(narrativeDf_onlyTopXWords)
  
  return(list(totalWords_withTopX, narrativeDf_onlyTopXWords))
}

get_schema_mismatch_score <- function(cue, narrative, numWords){
  mismatchCues <- allCues[allCues != as.character(cue)]
  detailCounts <-c()
  for(myCue in mismatchCues){
    detailCounts <- c(detailCounts, get_schema_score(myCue, narrative, numWords)[[1]])
  }
  mean_misMatchDetails <- mean(detailCounts)
  return(mean_misMatchDetails)
}


## set up, for each cue, a list of 50000 most similar ##

# We do this so that we can later access the stored similar words.
# We  do this so that getting  similar words doesn't have to be done
# multiple times, since it takes a while, and we can just
# access the stored similar words

allCues <- as.character(unique(tidy_story_clean$Cue))
cue_topSimilarities <- list()

numSimilarWords <- 50000
for(cue in allCues){
  cue_topSimilarities[[cue]] <- find_similar_words(cue, embedding_matrix, numSimilarWords)
}

# the above takes a while to run. So you can save it once you've run it, by uncommenting:
#save.image('glove_plus_cue_similarities.Rdata')

# then, to avoid having to rerun everything again in the future, just uncomment and run:
#load('glove_plus_cue_similarities.Rdata'
)

# save out the word lists used for calculating schema scores,
# so that it is easy to look through for a sanity check.
# for example, we want to be able to look at the dictionaries to ensure
# that words like 'stream' refer to 'forest' rather than 'netflix'

cue_dictionaryWords <- list()
for(cue in allCues){
  cue_dictionaryWords[[cue]] <- cue_topSimilarities[[cue]] %>% names
}
cue_dictionaryWords_df <- cue_dictionaryWords %>% as.data.frame()
write.csv(cue_dictionaryWords_df, 'schema_dictionaries.csv')

#### ----- Annotate all narratives ----- ####

# set up dataframe to fill in

story_scores <- story

story_scores$NumTopWordsCount <- NULL
story_scores$Top10000WordsCount <- NULL
story_scores$Top10000Words_detailWords <- NULL
story_scores$Top10000Words_mismatchCount <- NULL
story_scores$nonStopword_wordCount <- NULL

# for each response:
# get story.
# get total number of words (excluding stop words) in narrative
# get total number of 

for(i in tidy_story_clean$index %>% unique()) {
  thisStory <- tidy_story_clean[tidy_story_clean$index == i,]
  whichCue <- thisStory$Cue[1] %>% as.character()

  schema_out <- get_schema_score(whichCue, thisStory, 10000)
  story_scores[story_scores$index==i, "nonStopword_wordCount"] <- nrow(thisStory)
  story_scores[story_scores$index==i, "Top10000WordsCount"] <- schema_out[[1]]
  story_scores[story_scores$index==i, "Top10000Words_detailWords"] <- schema_out[[2]]$word %>% paste(collapse = " ")
  story_scores[story_scores$index==i, "Top10000Words_mismatchCount"] <- get_schema_mismatch_score(whichCue, thisStory, 10000)

}

write.csv(story_scores, 'narratives_scores.csv')


