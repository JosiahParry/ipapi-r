# Utility functions
# chunk the strings
chunk_strings <- function(x, n) {
  split(x, ceiling(seq_along(x) / n))
}


# Process response from bulk API endpoint
.process_resp <- function(resp) {
  resp_body <- yyjsonr::read_json_str(httr2::resp_body_string(resp))
  # pull out inner data frame columns
  isp_df <- do.call(vctrs::vec_rbind, resp_body$isp)
  loc_df <- do.call(rbind.data.frame, resp_body$location)
  risk_df <- do.call(vctrs::vec_rbind, resp_body$risk)
  vctrs::vec_cbind(ip = resp_body$ip, isp_df, loc_df, risk_df)
}

.process_resp_single <- function(resp) {
  resp_body <- yyjsonr::read_json_str(httr2::resp_body_string(resp))
  vctrs::vec_cbind(
    ip = resp_body$ip,
    as.data.frame(resp_body$isp),
    as.data.frame(resp_body$location),
    as.data.frame(resp_body$risk)
  )
}


ip_ptype <- function() {
  res <- data.frame(
    ip = character(0),
    isp = character(0),
    asn = character(0),
    org = character(0),
    country = character(0),
    country_code = character(0),
    city = character(0),
    state = character(0),
    zipcode = character(0),
    latitude = numeric(0),
    longitude = numeric(0),
    timezone = character(0),
    localtime = character(0),
    is_mobile = logical(0),
    is_vpn = logical(0),
    is_tor = logical(0),
    is_proxy = logical(0),
    is_datacenter = logical(0),
    risk_score = integer(0)
  )
  structure(res, class = c("tbl", "data.frame"))
}

#' Get information about IP Addresses
#'
#' Return detailed information from a vector of IP addresses.
#'
#' @param ips a character vector of IP addresses. Must not contain NA values.
#' @references See [API Reference](https://ipquery.gitbook.io/ipquery-docs)
#'
#' @returns
#' A data.frame with columns
#' - `ip`: character
#' - `isp`: character
#' - `asn`: character
#' - `org`: character
#' - `country`: character
#' - `country_code`: character
#' - `city`: character
#' - `state`: character
#' - `zipcode`: character
#' - `latitude`: numeric
#' - `longitude`: numeric
#' - `timezone`: character
#' - `localtime`: character
#' - `is_mobile`: logical
#' - `is_vpn`: logical
#' - `is_tor`: logical
#' - `is_proxy`: logical
#' - `is_datacenter`: logical
#' - `risk_score`: integer
#' @export
#' @examples
#'
#' # Only run this example when internet is present
#' if (rlang::is_installed("curl")) {
#'   if (curl::has_internet()) {
#'     query_ips("1.1.1.1")
#'   }
#' }
query_ips <- function(ips) {
  # ensure is a character
  if (!inherits(ips, "character")) {
    rlang::abort("`ips` must be a character vector without missing values")
  }

  # ensure no NA values are present
  if (anyNA(ips)) {
    rlang::abort("`ips` must not have `NA` values")
  }

  n <- length(ips)

  # return prototype if length is 0
  if (n == 0) {
    rlang::warn("No IP addresses provided")
    return(ip_ptype())
  }

  if (n == 1) {
    resp <- httr2::request("https://api.ipquery.io/") |>
      httr2::req_url_path_append(ips) |>
      httr2::req_perform()

    httr2::resp_check_status(resp)

    return(.process_resp_single(resp))
  }

  ips_chunked <- chunk_strings(ips, 1000)

  # create API requests
  all_reqs <- lapply(ips_chunked, function(.ips) {
    httr2::request("https://api.ipquery.io/") |>
      httr2::req_url_path_append(paste(.ips, collapse = ","))
  })

  # perform in parallel
  all_resps <- httr2::req_perform_parallel(all_reqs, on_error = "continue")

  # extract successful respsonses
  successful_resps <- httr2::resps_successes(all_resps)

  # combine to final data frame
  res <- httr2::resps_data(successful_resps, .process_resp)

  # extract failures
  failures <- httr2::resps_failures(all_resps)

  if (length(failures) > 0) {
    rlang::warn("Errors encountered. Responses stored in `attr(x, \"errors\")`")
    attr(res, "errors") <- failures
  }

  # return results
  structure(res, class = c("tbl", "data.frame"))
}

#' Query host IP Address
#'
#' Returns information about the IP address of the host machine.
#'
#' @return A character string
#' @export\
#' @examples
#' if (rlang::is_installed("curl")) {
#'   if (curl::has_internet()) {
#'     query_own_ip()
#'   }
#' }
query_own_ip <- function() {
  httr2::request("https://api.ipquery.io/") |>
    httr2::req_perform() |>
    httr2::resp_body_string()
}
