
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

# ----- CDS ---- 

read_cds <- function(path, cntry) { 
    url <- glue::glue("https://au.investing.com/rates-bonds/{path}-cds-5-years-usd-historical-data")
    html <- rvest::read_html(url)
    data <- rvest::html_table(html) 
    data[[1]] |>
        dplyr::mutate(Country = cntry, 
                      Date = as.Date(Date, "%d/%m/%Y"), 
                      Term = "5Y") |> 
        dplyr::select(Country, Date, Term, Price) } 

hist <- arrow::read_parquet("sov-cds-rates.parquet") 
data <- imap_dfr(list( 
    "AUS"="australia", 
    "USA"="united-states"), 
    \(x,y) read_cds(x,y))  
hist |> 
    dplyr::anti_join(data, 
              by=c("Date", "Country")) |> 
    dplyr::bind_rows(data) |> 
    arrange(Country, Date) |> 
    arrow::write_parquet("sov-cds-rates.parquet")


