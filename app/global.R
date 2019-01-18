library(magrittr)
library(dplyr, warn.conflicts = FALSE)
library(readr)
library(ggplot2)
library(plotly, warn.conflicts = FALSE)
library(shiny, warn.conflicts=FALSE)
library(shinydashboard, warn.conflicts=FALSE)

source('src/clp.R')
source('src/constraints.R')

# Generic error message
raise_error <- function(e) {
  showModal(modalDialog(
    title = 'Error',
    p(sprintf('Message: %s', e$message)),
    p(if(!is.null(e$call)) sprintf('Call: %s', as.character(e$call)) else ''),
    easyClose = TRUE
  ))
}
