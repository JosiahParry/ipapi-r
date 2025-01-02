# ipapi-r

[![R-CMD-check](https://github.com/JosiahParry/ipapi-r/actions/workflows/R-CMD-check.yaml/badge.svghttps://github.com/JosiahParry/ipapi-r/actions/workflows/R-CMD-check.yaml/badge.svghttps://github.com/JosiahParry/ipapi-r/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/JosiahParry/ipapi-r/actions/workflows/R-CMD-check.yaml)

An R package to query IP addresses using the ipquery.io API.

## Installation

Install the package from GitHub using:

``` r
remotes::install_github("josiahparry/ipapi-r")
```

## Usage

First, load the package.

``` r
library(ipapi)
```

### Query a Specific IP Address

The `query_ips()` function retrieves information about IP addresses,
including its ISP, location, and risk data.

``` r
query_ips(c("8.8.8.8", "1.1.1.1"))
```

    # A data frame: 2 × 19
      ip      asn    org    isp    country country_code city  state zipcode latitude
    * <chr>   <list> <list> <list> <chr>   <chr>        <chr> <chr> <chr>      <dbl>
    1 8.8.8.8 <chr>  <chr>  <chr>  United… US           Moun… Cali… 94043       37.4
    2 1.1.1.1 <chr>  <chr>  <chr>  Austra… AU           Sydn… New … 1001       -33.9
    # ℹ 9 more variables: longitude <dbl>, timezone <chr>, localtime <chr>,
    #   is_mobile <list>, is_vpn <list>, is_tor <list>, is_proxy <list>,
    #   is_datacenter <list>, risk_score <list>

### Fetch Your Own Public IP Address

The `query_own_ip()` function retrieves the public IP address of the
current machine.

``` r
query_own_ip()
```

    [1] "203.0.113.45"
