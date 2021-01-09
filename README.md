# R
> R-related notes, mini projects, exercises, etc.

## Time Series Forecasting
> Academic project during Advance Business Analytics courses from Aug.2020 to Dec.2020. It mainly utilized ARIMA modeling to predict future house price as well as Stationary Check (Unit Root Test) and Diagnostic Measures (Ljung-Box Test).

### Code Example
```R
myhouse %>%
  as_tsibble() %>%
  model(ARIMA(value ~ pdq(d=1), stepwise = F, approximation = F)) %>%
  report()
```

## University Exploration
