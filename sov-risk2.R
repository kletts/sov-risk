
library(rvest)
library(dplyr)
library(stringr)
library(lubridate)
library(purrr)

#investing: 
extract_asat <- function(x) { 
    date <- dplyr::if_else(str_detect(x, "\\/"),  
                    as.Date(paste(x, lubridate::year(Sys.Date()), sep="/"), format="%d/%m/%Y"), 
                    Sys.Date()) 
    date <- dplyr::if_else(date>Sys.Date(), date - lubridate::years(1), date) 
    return(date) } 

extract_term <- function(x) { 
    termregex <- "Overnight|\\d{1,2}M|\\d{1,2}Y|\\d{1}W"
    term <-  stringr::str_extract(x, termregex)  
    if_else(term=="Overnight", lubridate::period("1d"), lubridate::period(tolower(term))) } 

extract_country <- function(x) { 
    termregex <- "Overnight|\\d{1,2}M|\\d{1,2}Y|\\d{1}W"
    return(stringr::str_squish(stringr::str_remove(x, termregex))) }

read_yield <- function(x) { 
    if ("Yield" %in% names(x)) { 
        dplyr::mutate(x[names(x)!=""],  
               YieldAt = extract_asat(Time),
               Term = extract_term(Name), 
               Country = extract_country(Name)) |> 
        dplyr::select(YieldAt, Country, Term, Yield) } 
    else { 
        NULL } 
    }
