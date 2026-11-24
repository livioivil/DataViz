# Unit 13: SMS activity starter script
# Read the student handout for predictions and deliverables.
library(ggplot2)
source("data/text_helpers.R")
sms <- load_text_docs("data/sms_messages_240.csv")

# --- A1 ---
# Prediction:
table(sms$category)
summary(sms$raw_tokens)
# Add the within-label summaries, plot and four contextual readings.
# Interpretation and limitation:

# --- A2 ---
# Prediction:
sms_words <- word_tokens(sms$text)
sms_clean <- word_tokens(sms$text, stop_words = course_stopwords)
# Compare term_counts(), numeric tokens, and an original message.
# Interpretation and limitation:

# --- A3 ---
# Prediction:
sms_clean <- word_tokens(sms$text, stop_words = course_stopwords)
C_sms_all <- make_dtm(sms_clean, sms$document_id, min_df = 2)
# Inspect dimensions, row sums, a chosen cell and a small heatmap.
# Interpretation and limitation:

lab <- prepare_text(sms)

# --- A4 ---
# Prediction:
R_sms <- lab$representation
id <- rownames(R_sms$C)[1]
# Choose a term and verify its TF-IDF from the definition.
# Interpretation and limitation:

# --- A5 ---
# Prediction:
is_spam <- lab$docs$category == "spam"
# Use colMeans(), choose twenty terms, then top_bars() and draw_cloud().
# Interpretation and limitation:

# --- A6 ---
# Prediction:
sms_bigrams <- lapply(sms$text, sentence_ngrams)
sms_edges <- bigram_edges(sms_bigrams, min_count = 2, top_n = 40)
# Draw the network, propose paths, check n-grams and inspect source messages.
# Interpretation and limitation:

# --- A7 ---
# Prediction:
C2 <- make_dtm(sms_clean, sms$document_id, min_df = 2)
C5 <- make_dtm(sms_clean, sms$document_id, min_df = 5)
# Compare terms, empty rows and IDs; inspect one affected original.
# Interpretation and limitation:
