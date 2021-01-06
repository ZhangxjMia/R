# R
> R-related notes, mini projects, exercises, etc.

### Code Example
```R
myhouse %>%
  as_tsibble() %>%
  model(ARIMA(value ~ pdq(d=1), stepwise = F, approximation = F)) %>%
  report()
```
