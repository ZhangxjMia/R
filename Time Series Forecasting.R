---
title: "BUAN6357_Project_Zhang"
author: "Xiaojia Zhang"
date: "11/17/2020"
output:
  pdf_document:
    latex_engine: xelatex
---

```{r setup, include=FALSE}
knitr::opts_chunk$set(echo = TRUE)
```

# Data Information
1. Property sales data for the 2007 – 2019 period for Australian Capital Territory.
2. Column name, data type, and description:
  + Date Sold (Date time): date on which this property was sold.
  + Postcode (Integer): 4-digit postcode of the suburb where the property was sold.
  + Price (Integer): price for which the property was sold.
  + Property Type (String): house or unit
  + Bedrooms (Integer): number of bedrooms

# Hypothesis Statement
* Null Hypothese(H0): the price of property will not change in the future 2 years.
* Alternative Hypothesis(Ha): the price of property will increase in the future 2 years.


```{r}
library(pacman)
pacman::p_load(fpp2, fpp3, patchwork, purrr, feasts, forecast, ggplot2, tsibble, dplyr, lubridate, ggfortify)
options(scipen = 999)
options(digits=2)
set.seed(123)
```

# Data Preparation
```{r}
# Load raw data and quarterly data
sales <- read.csv("property_sales.csv")
mydata <- read.csv("property_quarterly_sales.csv")
```

* The datatype for ‘datesold’ column is factor, I will convert it to datetime later.
* Number of bedrooms might be 0. Taking studio of unit into account.
```{r}
# Structure of the data frames
str(sales)
summary(sales)
str(mydata)
summary(mydata)
```


```{r}
# Check missing values -> no missing value
miss_value <- length(which(is.na(sales)))
miss_value
```

```{r}
# Detect outliers and remove them
outliers <- boxplot.stats(sales$price)$out
sales_df <- sales[-c(which(sales$price %in% outliers)),]
```

# Explortory Data Analysis (EDA)
* The mean value and range of House are higher than Unit.
```{r}
# Boxplot of Price and each PropertyType (House & Unit)
ggplot(sales_df, aes(propertyType, price)) +
  geom_boxplot(aes(fill = propertyType), outlier.color = 'red', 
               outlier.shape = 20, outlier.size = 3) +
  theme(legend.position = 'right') 
```

* It looks like more people would like to buy house rather than buying unit, even though the price of house is usually much higher than the price of unit.
```{r}
# Property Sold Distribution for each PropertyType (House & Unit)
ggplot(data = sales_df, mapping = aes(x = price, colour = propertyType)) + 
  geom_freqpoly(binwidth = 500)
```
```{r}
# Convert datesold(factor) to date format
sales$datesold <- as.character(sales$datesold)
sales$datesold <- mdy_hm(as.character(sales$datesold))
str(sales$datesold)
```

* January doesn’t have many property sales relates to other 11 months. November has the best sales which is over 3000.
* From 2007 to 2017, number of property sales increases slowly. In 2018, it starts to decrease. The most interesting part is that number of sales decrease rapidly in 2019.
```{r}
# Property sales distribution for years
ggplot(sales) + aes(x = format(datesold, "%Y")) + 
  geom_bar(fill = '#00cfcc') +
  xlab("Year")
# Property sales distribution for months
ggplot(sales) + aes(x = format(datesold, "%m")) + 
  geom_bar(fill = '#e898ac') +
  xlab("Month")
```

* We can infer from the graph itself that the data points follows an overall upward trend with some outliers in terms of sudden lower values. 
```{r}
# Monthly property price trend for House & Unit
myhouse <- mydata[which(mydata$type == "house"),]
plot(ts(myhouse[,"MA"], start = c(2007, 6), end = c(2018, 12),
        frequency = 12), main = "Property Price for House & Unit",
        xlab = 'Year', ylab = 'Price', col = '#e898ac', 
        ylim = c(300000,750000), lwd = 2.5)
myunit <- mydata[which(mydata$type == "unit"),]
lines(ts(myunit[,"MA"], start = c(2007, 6), end = c(2018, 12),
        frequency = 12), col = '#00cfcc', , lwd = 2.5)
legend("topleft", c("House","Unit"),col=c("#e898ac","#00cfcc"), lty=1:1, cex=0.8, box.lty=0)
grid()
```


# Decomposition
```{r}
myhouse <- ts(myhouse[,"MA"], start = c(2007, 6), end = c(2018, 12),
   frequency = 12)

myhouse %>%
  decompose %>%
  autoplot(ts.colour = '#00cfcc')
```

# ACF & PACF without 1st Differencing
* Without the 1st diff, the ACF decreases slowly which means the data is not stationary.
```{r}
myhouse %>% 
  as_tsibble() %>%
  gg_tsdisplay(value, plot_type = "partial")
```

# ACF & PACF with 1st Differencing
* With 1st diff, there is no lag across the dash line in the ACF and PACF plots which is a good sign. From these plots, I can say that 𝑝 = 1 and 𝑞 = 1.
```{r}
myhouse %>% 
  diff() %>% 
  as_tsibble() %>%
  gg_tsdisplay(value, plot_type = "partial")
```


# Stationary Check - Unit Root Test
Null Hypothesis in KPSS Test: the series is stationary.

* P-value = 0.1 > 5% (assume the significant level is 5%) which we accept the null hypothesis, thus we can conclude that the series is stationary.
* Number of diffs = 1, which means 1st diff is required for the data to be stationary.
```{r}
myhouse %>%
  as_tsibble() %>%
  mutate(diff_value = difference(value)) %>%
  features(diff_value, unitroot_kpss)

myhouse %>%
  as_tsibble() %>%
  features(value, unitroot_ndiffs)
```


# ARIMA Modeling
I build the ARIMA(0, 1, 0) model and apply it to myhouse. The AICc is 2979. I also force the model to run all the combinations, but still get ARIMA(0, 1, 0) and same AICc. Force the model runs all the combination, but still get ARIMA(0,1,0).
```{r}
#force run all combinations
myhouse %>%
  as_tsibble() %>%
  model(ARIMA(value ~ pdq(d=1), stepwise = F, approximation = F)) %>%
  report()

fit <- myhouse %>%
  as_tsibble() %>%
  model(arima = ARIMA(value ~ pdq(0, 1, 0))) %>%
  report()
```

# Diagnostic Measures - Ljung-Box Test
Null Hypothesis in Ljung-Box Test: No serial correlation for future data.

* P-value = 0.944 > 5% which is too large to reject null hypothesis (No serial correlation for future data), so there is no pattern in the residuals. In addition, the plots support the result:
  + There is no lag across the dash line in ACF
  + The residuals are normally distributed
```{r}
gg_tsresiduals(fit)

#check for autocorrelation: Ljung-box Test
#Null Hypothesis: No serial correlation upto 8 lags
#lag = sqrt(length(data)), dof = (p+q)
augment(fit) %>%
  features(.resid, ljung_box, lag = 8, dof = 0)
```

# Forecasting
This plot shows the 80% and 95% confidence level of the prediction. If I focus on the lower bound of the confidence level, the trend of house price would be decrease until January 2020 and increase after January 2020. If I focus on upper bound, it will have upward trend since 2019.
```{r}
fit %>%
  forecast(h = 24) %>%
  print()

fit %>%
  forecast(h = 24) %>%
  autoplot(myhouse)
```

# Conclusions
From the plots in Exploratory Data Analysis, the property sales increase from 2007 to 2017. In the meanwhile, the price of property increases. However, the price starts to decrease may be due to the rapid decreasing in property sales. After applying the ARIMA model to forecast the house prices in future 2 years, I got the prediction plot in 24 periods (2 years).
With the result of forecasting, I’m be able to provide insightful business/individual decisions. For homebuyers, I would suggest that buying houses before January. 2020, and selling houses after January 2020. Because homebuyers can buy the houses at a relatively lower prices, and sell their houses at a relatively higher prices. For real estate companies or agents, they could use the upper bound and lower bound as a reference for price range. However, it should still take the house market into account.