
library(arrow)
source("sov-risk.R")

hist <- arrow::read_parquet("sov-bond-yields.parquet")
if (max(hist$AsatDt) < Sys.Date() -1) { 
    data <- latest_sovbonds() 
    ratings <- read_ratings() 
    data <- data |> 
        left_join(ratings, 
                  by=c("Issuer"="Country", "AsatDt"="AsatDt")) |> 
        mutate(across(c(`S&P`, Moodys, Fitch, DBRS), as.character)) 
    hist <- bind_rows(hist, data)
    arrow::write_parquet(hist, "sov-bond-yields.parquet")
    } 


