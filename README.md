# text_mining
This repo contains data from Ted Kwartler's "Text Mining in Practice With R" book.

## Code Changes
In December 2017, the `tm` package was changed.  Specifically, `readTabular` was removed.  For more specifics click [here](https://cran.r-project.org/web/packages/tm/news.html)

An example on page 43 of the book no longer works as written but the code below corrects the issue. 

- If using `DataframeSource` the *first* column **MUST** be named `doc_id` followed by a `text` column.  Any other columns are considered metadata associated row-wise.

This makes it easier instead of manually declaring metadata through a `readerControl`.  

### Page 43 Example

```
#DEPRECATED: 
#tweets<-data.frame(ID=seq(1:nrow(text.df)),text=text.df$text)
tweets<-data.frame(doc_id=seq(1:nrow(text.df)),text=text.df$text)

#DEPRECATED: 
#meta.data.reader <- readTabular(mapping=list(content="text", id="ID"))
#corpus <- VCorpus(DataframeSource(tweets), readerControl=list(reader=meta.data.reader))

corpus <- VCorpus(DataframeSource(tweets))
corpus<-clean.corpus(corpus)
corpus[[103]][1]
corpus[[103]][2]

```
