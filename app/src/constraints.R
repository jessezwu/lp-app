library(magrittr)
library(Matrix)
library(foreach)

#' Utility function converting data frame constraints for CLP
#'
#' @param con_coefs Coefficients/weights for raw constraints, each row is a
#' record, and column is an action
#' @param vars Data.frame with variables and values for each problem record
#' @param cons Data.frame representing a list of constraints, expects columns
#' for row variable, row value, column, lower and upper bounds, and type
#' @return list with constraint matrix, and row lower and upper bounds
get_constraints <- function(con_coefs, vars, cons) {
  if(nrow(cons) == 0) return(NULL)
  nr <- nrow(con_coefs)
  nc <- ncol(con_coefs)
  vec_coefs <- as.vector(t(con_coefs))
  con_mat <- NULL
  rlb <- c()
  rub <- c()
  for(r in 1:nrow(cons)) {
    var <- cons[[r, 'variable']]
    val <- cons[[r, 'value']]
    col <- cons[[r, 'column']]
    # compute indices corresponding to filtered data
    idx_row <- if(val == 'All') {
      1:nr
    } else {
      which(vars[, var] == val)
    }
    idx_col <- if(col == 'All') {
      rep(1:nc, length(idx_row))
    } else {
      rep(which(colnames(con_coefs) == col), length(idx_row))
    }
    # recycle rows if necessary
    if(length(idx_row) < length(idx_col)) {
      idx_row <- rep_len(idx_row, length(idx_col))
    }
    # get filtered coefficient values
    # do this by using the complement to force unused coefficients to zero
    coefs <- Matrix(TRUE, nrow = nr, ncol = nc)
    coefs[idx_row, idx_col] <- FALSE
    row_coefs <- vec_coefs
    row_coefs[as.vector(t(coefs)) %>% which] <- 0
    # bounds
    lb <- if(is.na(cons[[r, 'lower']])) {-Inf} else {cons[[r, 'lower']]}
    ub <- if(is.na(cons[[r, 'upper']])) {Inf} else {cons[[r, 'upper']]}
    if(cons[r, 'type'] == 'mean') {
       lb <- lb * length(idx_row)
       ub <- ub * length(idx_row)
    }
    # append
    rlb <- c(rlb, lb)
    rub <- c(rub, ub)
    if(is.null(con_mat)) {
      con_mat <- row_coefs
    } else {
      con_mat <- rbind(con_mat, row_coefs)
    }
  }
  list(con_mat = con_mat, rlb = rlb, rub = rub)
}
