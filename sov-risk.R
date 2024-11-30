
library(tidyverse)
library(rvest)
library(lubridate) 

convert_maturity <- function(x) { 
    ifelse(grepl("month", x), parse_number(x, na = c("", "NA", "n.a."))/12, parse_number(x, na = c("", "NA", "n.a."))) } 

capwords <- function(s, strict = FALSE) { 
    s <- gsub("-", " ", s)
    cap <- function(s) paste(toupper(substring(s, 1, 1)),
                             {s <- substring(s, 2); if(strict) tolower(s) else s},
                             sep = "", collapse = " " )
    sapply(strsplit(s, split = " "), cap, USE.NAMES = !is.null(names(s)))
}

ratings.snp <- c("AAA", "AA+", "AA", "AA-", "A+", "A",  "A-", "BBB+",  "BBB", "BBB-", "BB+", "BB", "BB-", 
                 "B+", "B", "B-", "CCC+", "CCC", "CCC-", "CC", "C", "SD")
ratings.fitch <- c("AAA", "AA+", "AA", "AA-", "A+", "A",  "A-", "BBB+",  "BBB", "BBB-", "BB+", "BB", "BB-", 
                   "B+", "B", "B-", "CCC+", "CCC", "CCC-", "CC", "C", "RD")
ratings.moodys <- c( "Aaa", "Aa1" , "Aa2", "Aa3", "A1", "A2", "A3", "Baa1", "Baa2", "Baa3", "Ba1", "Ba2", "Ba3", 
                     "B1", "B2", "B3", "Caa1", "Caa2", "Caa3", "Ca", "C", "D")
ratings.dbrs <- c("AAA", "AA (high)", "AA", "AA (low)", "A (high)", "A",  "A  (low)", "BBB (high)",
                  "BBB", "BBB (low)", "BB (high)", "BB", "BB  (low)", 
                  "B (high)", "B", "B  (low)", "CCC (high)", "CCC", "CCC (low)", "CC", "C", "D")


read_ratings <- function()  {  
    src <- "http://www.worldgovernmentbonds.com/world-credit-ratings/"
    html <- read_html(src)
    html_table(html)[[1]] %>%  
        set_names(c("Flag", "Country", "S&P", "Moodys", "Fitch", "DBRS")) %>% 
        select(-Flag) %>% 
        mutate(`S&P` = factor(`S&P`, levels=ratings.snp, ordered = TRUE), 
               Moodys = factor(Moodys, levels=ratings.moodys, ordered=TRUE), 
               Fitch = factor(Fitch, levels=ratings.fitch, ordered=TRUE), 
               AsatDt = Sys.Date())  } 

lastupdate <- function(x) { 
  x <- as.Date(paste(x, year(Sys.Date())), format="%d %b %Y")
  if (max(x) > Sys.Date()) { 
    x <- x - years(1) } 
  return(x) }

read_sovbonds <- function(
        cntry=c("new-zealand", "australia", "united-states", "india", "united-kingdom", "japan")) { 
    src <- file.path("http://www.worldgovernmentbonds.com/country", cntry)
    html <- read_html(src)
    html_table(html)[[1]] %>% 
        set_names(c("Empty1", "ResidualMaturityYrs", "YieldLast", "YieldChg1MBP", "YieldChg6MBP", "YieldChg12MBP",
                    "Empty2", "ZCPriceLast", "ZCPricePChg1M", "ZCPricePChg6M", "ZCPricePChg12M", "CapitalGrowth", "LastChange")) %>% 
        slice(-1) %>% 
        select(!starts_with("Empty")) %>% 
        mutate(
            AsatDt= Sys.Date(), 
            ResidualMaturityYrs =convert_maturity(ResidualMaturityYrs),
            across(starts_with("Yield"), ~parse_number(.x, na = c("", "NA", "n.a."))), 
            across(starts_with("ZCPrice"), ~parse_number(.x, na = c("", "NA", "n.a."))), 
            LastChange = lastupdate(LastChange), 
            Issuer=capwords(cntry)) %>% 
        drop_na(ResidualMaturityYrs) } 

date_chg <- function(x, lastchg) { 
    case_when(x == "YieldLast" ~ lastchg, 
              x == "YieldPrev" ~ lastchg + days(-1), 
              x == "YieldChg1MBP" ~ lastchg %m+% months(-1), 
              x == "YieldChg6MBP" ~ lastchg %m+% months(-6), 
              x == "YieldChg12MBP" ~ lastchg %m+% months(-12))    
    }

latest_sovbonds <- function()  {  
    c("new-zealand", "australia", "united-states", "indonesia", "singapore", "malaysia", 
      "italy", "canada", "india", "united-kingdom", "japan", "germany", "france", "sweden", "norway", 
      "finland", "denmark", "greece", "switzerland", "mexico", "chile",  "thailand", 
      "brazil", "turkey", "spain", "russia", "poland", "portugal", "ireland", "netherlands") |> 
        map_dfr(read_sovbonds)  |> 
        select(AsatDt, Issuer, LastChange, ResidualMaturityYrs, starts_with("Yield")) |> 
        mutate(across(c(YieldChg1MBP, YieldChg6MBP, YieldChg12MBP), 
                      \(x) YieldLast - x/100)) |> 
        pivot_longer(cols=starts_with("Yield"), 
                     names_to = "PrevDate", 
                     values_to="Yield") |> 
        mutate(PrevDate = date_chg(PrevDate, LastChange)) }
