# R
> R-related notes, mini projects, exercises, etc.

## Time Series Forecasting
> Academic project during Advance Business Analytics course from Aug.2020 to Dec.2020. It mainly utilized ARIMA modeling to predict future house price as well as Stationary Check (Unit Root Test) and Diagnostic Measures (Ljung-Box Test).

### Code Example
```R
myhouse %>%
  as_tsibble() %>%
  model(ARIMA(value ~ pdq(d=1), stepwise = F, approximation = F)) %>%
  report()
```

## Data Exploration of Universities
> Academic project during Business Analytics course from Jan.2020 to May.2020. Since this is the first technical class after I shifted my major to Information Technology & Management (ITM), this project is fundamental and simple to understand Exploratory Data Analysis (EDA) for a starter.
