library(magrittr)
library(clpAPI)
library(Matrix)

#' Generate constraints to ensure choices for a record sum to 1
#'
#' @param obj_mat Objective coefficients where columns represent choices
#' @description Use constraints to guide CLP towards selecting
#' @return list with constraint matrix, and row lower and upper bounds
gen_one_hot_constraint <- function(obj_mat) {
  nr <- nrow(obj_mat)
  nc <- ncol(obj_mat)
  # this is faster than `rep(0:(nr - 1), nc) %>% sort`
  idx_row <- matrix(rep(1:nr, nc), ncol = nc) %>% t() %>% as.vector
  idx_col <- 1:(nr * nc)
  mat <- sparseMatrix(i = idx_row, j = idx_col, x = 1)
  list(mat = mat, rlb = rep(1, nr), rub = rep(1, nr))
}

#' Construct CLP problem object and solve
#'
#' @param obj_mat matrix of objective coefficients
#' @param con_mat sparseMatrix for constraints
#' @param dir direction of objective (-1 to maximise, 1 to minimise)
#' @param clb column lower bounds for constraints
#' @param cub column upper bounds for constraints
#' @param rlb row lower bounds for constraints
#' @param rub row upper bounds for constraints
#' @description Solve a linear programming problem given all necessary
#' components - objective, constraints
#' @return list including status, and objective/column/row values
solve_lp <- function(obj_mat, con_mat, dir = -1,
                     clb = NULL, cub = NULL, rlb = NULL, rub = NULL) {
  # dimensions
  nc <- ncol(con_mat)
  nr <- nrow(con_mat)
  # constraint row and column indices
  ia <- con_mat@i
  ja <- con_mat@p
  # constraint coefficients are nonzero entries
  ra <- con_mat@x
  # objective coefficients
  obj <- as.vector(t(obj_mat))

  # construct problem object
  prob <- initProbCLP()
  setObjDirCLP(prob, dir)
  loadProblemCLP(prob, nc, nr, ia, ja, ra, clb, cub, obj, rlb, rub)
  # solve
  solveInitialCLP(prob)

  results <- list(
    status   = getSolStatusCLP(prob),
    obj_val  = getObjValCLP(prob),
    col_prim = getColPrimCLP(prob),
    col_dual = getColDualCLP(prob),
    row_prim = getRowPrimCLP(prob),
    row_dual = getRowDualCLP(prob),
    ncol     = nc,
    nrow     = nr
  )
  delProbCLP(prob)
  results
}

# Convert column primal values back to original choices
select_best_option <- function(col_prim, n_options) {
  matrix(col_prim, ncol = n_options, byrow = TRUE) %>%
    apply(1, which.max)
}
