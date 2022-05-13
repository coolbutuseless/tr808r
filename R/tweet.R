


#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#' Convert a single pattern to a text representation
#'
#' @param pat single pattern
#'
#' @return text representation.  Also copies to clipboard if \code{clipr}
#'         package is installed.
#'
#' @noRd
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
pattern_to_text <- function(pat) {
  # pat <- pattern$pattern[[1]]
  txt <- rep('_', nrow(pat))
  txt[pat$active] <- 'x'
  mat <- matrix(txt, nrow=11, ncol=16, byrow = TRUE)
  mat <- mat[11:1,]

  # Add instrument names as first column
  mat <- cbind(
    c('BD ', 'SD ', 'LT ', 'MT ', 'HT ', 'RS ', 'CP ', 'CB ', 'CY ', 'OH ', 'CH '),
    mat
  )

  res <- paste(apply(mat, 1, paste, collapse = ""), collapse = "\n")

  res <- paste("#RStats {tr808r}", res, sep = "\n")

  if (requireNamespace('clipr', quietly = TRUE)) {
    message("Pattern copied to clipboard in text format")
    clipr::write_clip(res)
  }

  res
}


#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#' Check if a snippet of text appears to be a text repreentation of a pattern
#'
#' @param txt single string
#'
#' @return TRUE if this is parseable as a valid pattern
#'
#' @noRd
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
is_text_pattern <- function(txt) {

  res <- is.character(txt) && length(txt) == 1 && !is.na(txt)
  if (!res) {
    return(FALSE)
  }

  matches <- gregexpr("[x_]{16}", txt)

  return(length(matches[[1]]) == 11)
}


#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#' Convert a text representation into a \code{tr808_state} object with a single pattern
#'
#' The returned object can be loaded into the drum machine using
#' \code{tr808(state = ...)}
#'
#' @param txt Single string must contain 11 strings of length 16 characters consisting of
#'        only \code{_} and \code{x}.  All other characters will be ignored.
#' @param bpm bpm. default: 96
#'
#' @return \code{tr808_state} object
#'
#' @export
#'
#'
#' @examples
#' text_to_tr808_state(
#' '#RStats #tr808r
#'  BD xx____xx__x_____
#'  SD ____x_______x___
#'  LT ________________
#'  MT xx______________
#'  HT ______xx__x__x__
#'  RS ________________
#'  CP xx_xx_xx_______x
#'  CB xx__x_xx_x_x_xx_
#'  CY ________________
#'  OH ________________
#'  CH x_xxx_xxx_xxx_xx'
#')
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
text_to_tr808_state <- function(txt, bpm = 96) {

  stopifnot(is.character(txt), length(txt) == 1, !is.na(txt))

  matches <- gregexpr("[x_]{16}", txt)

  if (length(matches[[1]]) != 11) {
    stop("Expected 11 sequences of [x|_]")
  }

  strings <- regmatches(txt, matches)[[1]]

  mat <- do.call(rbind, rev(strsplit(strings, "")))

  res <- as.vector(t(mat))

  blank_pattern <- expand.grid(x=1:16, y=1:11, active = FALSE)

  first_pattern <- blank_pattern
  first_pattern$active <- res == 'x'

  pattern <- rep(list(blank_pattern), NPAT)
  pattern[[1]] <- first_pattern

  pattern_set <- logical(NPAT)
  pattern_set[[1]] <- TRUE

  list(
    pattern_set = pattern_set,
    pattern     = pattern,
    bpm         = bpm
  )

}


if (FALSE) {
  text <- '#RStats {tr808r}
BD xx____xx__x_____
SD ____x_______x___
LT ________________
MT xx______________
HT ______xx__x__x__
RS ________________
CP xx_xx_xx_______x
CB xx__x_xx_x_x_xx_
CY ________________
OH ________________
CH x_xxx_xxx_xxx_xx'
}
