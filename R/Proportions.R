# -------------------------------------------------------------------------------------------------
#' phe_proportion
#'
#' Calculates proportions with confidence limits using Wilson Score method [1,2].
#'
#' @param data a data.frame containing the data to calculate proportions for; unquoted string; no default
#' @param x field name from data containing the observed numbers of cases in the sample meeting the required condition
#'          (the numerator for the proportion); unquoted string; no default
#' @param n field name from data containing the number of cases in the sample (the denominator for the proportion);
#'          unquoted string; no default
#' @param percentage whether the output should be returned as a percentage; logical; default FALSE
#'
#' @inheritParams phe_dsr
#'
#' @return When type = "full", returns the original data.frame with the following appended:
#'         proportion, lower confidence limit, upper confidence limit, confidence level, statistic and method
#'
#' @importFrom rlang sym quo_name
#'
#' @section Notes: Wilson Score method [1,2] is applied using the \code{\link{wilson_lower}}
#'  and \code{\link{wilson_upper}} functions.
#'
#' @examples
#' df <- data.frame(area = c("Area1","Area2","Area3"),
#'                  numerator = c(65,82,100),
#'                  denominator = c(100,100,100))
#'
#' phe_proportion(df, numerator, denominator)
#' phe_proportion(df, numerator, denominator, confidence=99.8)
#' phe_proportion(df, numerator, denominator, type="full")
#'
#' @import dplyr
#'
#' @export
#'
#' @references
#' [1] Wilson EB. Probable inference, the law of succession, and statistical
#'  inference. J Am Stat Assoc; 1927; 22. Pg 209 to 212. \cr
#' [2] Newcombe RG, Altman DG. Proportions and their differences. In Altman
#'  DG et al. (eds). Statistics with confidence (2nd edn). London: BMJ Books;
#'  2000. Pg 46 to 48.
#'
#' @family PHEindicatormethods package functions
# -------------------------------------------------------------------------------------------------

# create phe_proportion function using Wilson's method
phe_proportion <- function(data, x, n, type="standard", confidence=0.95, percentage=FALSE) {

    # check required arguments present
  if (missing(data)|missing(x)|missing(n)) {
    stop("function phe_dsr requires at least 3 arguments: data, x, n")
  }

  # apply quotes
  x <- enquo(x)
  n <- enquo(n)


  # validate arguments
  if (any(pull(data, !!x) < 0)) {
        stop("numerators must be greater than or equal to zero")
    } else if (any(pull(data, !!n) <= 0)) {
        stop("denominators must be greater than zero")
    } else if (any(pull(data, !!x) > pull(data, !!n))) {
        stop("numerators must be less than or equal to denominator for a proportion statistic")
    } else if ((confidence<0.9)|(confidence >1 & confidence <90)|(confidence > 100)) {
        stop("confidence level must be between 90 and 100 or between 0.9 and 1")
    } else if (!(type %in% c("value", "lower", "upper", "standard", "full"))) {
      stop("type must be one of value, lower, upper, standard or full")
    }

  # scale confidence level
  if (confidence >= 90) {
    confidence <- confidence/100
  }

  # set multiplier
  multiplier <- 1
  if (percentage == TRUE) {
    multiplier <- 100
  }

  # calculate proportion and CIs
  phe_proportion <- data %>%
                    mutate(value = (!!x)/(!!n) * multiplier,
                           lowercl = wilson_lower((!!x),(!!n),confidence) * multiplier,
                           uppercl = wilson_upper((!!x),(!!n),confidence) * multiplier,
                           confidence = paste(confidence*100,"%",sep=""),
                           statistic = if_else(percentage == TRUE,"percentage","proportion"),
                           method = "Wilson")

  if (type == "lower") {
    phe_proportion <- phe_proportion %>%
      select(-value, -uppercl, -confidence, -statistic, -method)
  } else if (type == "upper") {
    phe_proportion <- phe_proportion %>%
      select(-value, -lowercl, -confidence, -statistic, -method)
  } else if (type == "value") {
    phe_proportion<- phe_proportion %>%
      select(-lowercl, -uppercl, -confidence, -statistic, -method)
  } else if (type == "standard") {
    phe_proportion <- phe_proportion %>%
      select( -confidence, -statistic, -method)
  }

return(phe_proportion)
}
