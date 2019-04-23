#' Author: TK
#' Date: 4-17
#' Purpose: troubleshoot/diagnose c8 coding issue

# WD
setwd("/cloud/project/ner/C8_final_txts")

# Libs
library(pbapply)
library(stringr)
library(tm)
library(openNLP)
library(openNLPmodels.en)

# Custom Functions
txtClean <- function(x) {
  x <- x[-1] 
  x <- paste(x,collapse = " ")
  x <- str_replace_all(x, "[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\\.[a-zA-Z0-9-.]+", "")
  x <- str_replace_all(x, "Doc No.", "")
  x <- str_replace_all(x, "UNCLASSIFIED U.S. Department of State Case No.", "")
  x <- removeNumbers(x)
  x <- as.String(x)
  return(x)
}

# Get data & Organize
tmp           <- list.files(pattern = '.txt', full.names = T)
emails        <- pblapply(tmp, readLines)
names(emails) <- gsub('.txt', '', list.files(pattern = '.txt'))

# Examine 1
emails[[1]]

# Examine cleaning in action
txtClean(emails[[1]])[[1]]

# Apply cleaning to all emails; review one email in the list
allEmails <- pblapply(emails,txtClean)
allEmails[[2]][[1]][1]

# POS Tagging
persons            <- Maxent_Entity_Annotator(kind='person')
locations          <- Maxent_Entity_Annotator(kind='location')
organizations      <- Maxent_Entity_Annotator(kind='organization')
sentTokenAnnotator <- Maxent_Sent_Token_Annotator(language='en')
wordTokenAnnotator <- Maxent_Word_Token_Annotator(language='en')
posTagAnnotator    <- Maxent_POS_Tag_Annotator(language='en')

# Annotate each document in  a loop
annotationsData <- list()
for (i in 1:length(allEmails)){
  print(paste('starting annotations on doc', i))
  annotations <- annotate(allEmails[[i]], list(sentTokenAnnotator, 
                                               wordTokenAnnotator, 
                                               posTagAnnotator, 
                                               persons, 
                                               locations, 
                                               organizations))
  annDF           <- as.data.frame(annotations)[,2:5]
  annDF$features  <- unlist(as.character(annDF$features))
  
  
  annotationsData[[tmp[i]]] <- annDF
  print(paste('finished annotations on doc', i))
}

# Annotations have character indices 
# Now obtain terms by index from each document using a NESTED loop 
allData<- list()
for (i in 1:length(allEmails)){
  x <- allEmails[[i]]       # get an individual document
  y <- annotationsData[[i]] # get an individual doc's annotation information
  print(paste('starting document:',i, 'of', length(allEmails)))
  
  # for each row in the annotation information, extract the term by index
  POSls <- list()
  for(j in 1:nrow(y)){
    annoChars <- ((substr(x,y[j,2],y[j,3]))) #substring position
    
    # Organize information in data frame
    z <- data.frame(doc_id = i,
                    type     = y[j,1],
                    start    = y[j,2],
                    end      = y[j,3],
                    features = y[j,4],
                    text     = as.character(annoChars))
    POSls[[j]] <- z
    #print(paste('getting POS:', j))
  }
  
  # Bind each documents annotations & terms from loop into a single DF
  docPOS       <- do.call(rbind, POSls)
  
  # So each document will have an individual DF of terms, and annotations as a list element
  allData[[i]] <- docPOS
}


# Now to subset for each document
people       <- pblapply(allData, subset, grepl("*person", features))
locaction    <- pblapply(allData, subset, grepl("*location", features))
organization <- pblapply(allData, subset, grepl("*organization", features))

### Or if you prefer to work with flat objects make it a data frame w/all info
POSdf <- do.call(rbind, allData)

# Subsetting example w/2 conditions; people found in email 1
subset(POSdf, POSdf$doc_id ==1 & grepl("*person", POSdf$features) == T)


# End