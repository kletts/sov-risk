
source("sov-risk2.R")

url <- "https://au.investing.com/rates-bonds/world-government-bonds"
html <- rvest::read_html(url)
data <- rvest::html_table(html) 
data <- purrr::map_dfr(data, read_yield) |> 
    mutate(ExtractDt = Sys.Date(), 
           MaturityDt = YieldAt + Term, 
           TermMonths = Term / months(1),
           Term = as.character(Term)) 

hist <- arrow::read_parquet("sov-bond-yields.parquet") 
data <- hist |> bind_rows(data)
arrow::write_parquet(data, "sov-bond-yields.parquet")

