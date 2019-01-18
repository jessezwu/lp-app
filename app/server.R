library(doMC, quietly=TRUE)
library(DT, warn.conflicts=FALSE)
library(shiny, warn.conflicts=FALSE)
library(shinydashboard, warn.conflicts=FALSE, verbose=FALSE)

options(warn=-1)

shinyServer(function(input, output, clientData, session) {
  ##############################################################################
  # Setup
  ##############################################################################
  num_cores <- detectCores()
  registerDoMC(num_cores)

  ################################################################################
  # Data tab
  ################################################################################

  data_objective <- reactive({
    file <- input$file_objective
    if(is.null(file)) return(NULL)
    tryCatch({
      read_csv(file$datapath)
    }, error = raise_error)
  })

  # flavour text
  output$ui_sample <- renderUI({
    req(data_objective())
    div(align = 'center', p('only a sample of rows are displayed'))
  })

  # show sample
  output$dt_objective <- renderDataTable({
    req(dt <- data_objective())
    dt %>%
      head(n = 10) %>%
      datatable(rownames=FALSE, options=list(dom='t'))
  })

  ################################################################################
  # Constraints
  ################################################################################

  data_constraints <- reactive({
    file <- input$file_constraints
    if(is.null(file)) return(NULL)
    tryCatch({
      read_csv(file$datapath)
    }, error = raise_error)
  })

  data_variables <- reactive({
    file <- input$file_variables
    if(is.null(file)) return(NULL)
    tryCatch({
      read_csv(file$datapath)
    }, error = raise_error)
  })

  # filter row variable
  output$ui_sel_con_var <- renderUI({
    if(is.null(data_variables())) return()
    selectizeInput('sel_con_var', 'Row Filter (Variable)',
      choices = c('All', colnames(data_variables())))
  })
  # filter row values
  output$ui_sel_con_val <- renderUI({
    if(is.null(data_variables())) return()
    req(var <- input$sel_con_var)
    choices <- if(var == 'All') {
      'All'
    } else {
      c('All', data_variables() %>% pull(var) %>% unique %>% sort)
    }
    selectizeInput('sel_con_val', 'Row Filter (Value)', choices = choices)
  })
  # filter column
  output$ui_sel_con_col <- renderUI({
    if(is.null(data_constraints())) return()
    selectizeInput('sel_con_col', 'Column Filter',
      choices = c('All', colnames(data_constraints())))
  })

  # reactive value to store list of constraints
  val_constraints <- reactiveVal(data.frame())

  output$dt_constraints <- renderDataTable({
    val_constraints() %>%
      datatable(rownames=FALSE, options=list(dom='tp'))
  })

  # add a constraint
  observeEvent(input$button_add_con, {
    var <- if(is.null(input$sel_con_var)) 'All' else input$sel_con_var
    val <- if(is.null(input$sel_con_val)) 'All' else input$sel_con_val
    col <- if(is.null(input$sel_con_col)) 'All' else input$sel_con_col
    row <- data.frame(
      variable = var,
      value    = val,
      column   = col,
      lower    = max(-Inf, input$num_con_low),
      upper    = min(Inf, input$num_con_up),
      type     = input$sel_con_type
    )
    val_constraints(rbind(val_constraints(), row))
  })

  # only show delete button if the table has rows, and some are selected
  output$ui_button_con_delete <- renderUI({
    if(nrow(val_constraints()) == 0) return()
    if(is.null(input$dt_constraints_rows_selected)) return()
    actionButton(width = '50%', 'button_del_con', 'Delete Selected')
  })

  # delete some selected constraints
  observeEvent(input$button_del_con, {
    req(rows <- input$dt_constraints_rows_selected)
    str(rows)
    val_constraints(val_constraints()[-rows,])
  })
  # delete all
  observeEvent(input$button_del_all, {
    val_constraints(data.frame())
  })

  ################################################################################
  # Optimise 
  ################################################################################

  observeEvent(input$button_run, {
    tryCatch({
      if(is.null(data_objective())) stop('No Data Available!', call. = FALSE)
      obj_mat <- data_objective() %>% as.matrix()
      # generic constraints
      initial_constraints <- gen_one_hot_constraint(obj_mat)
      con_mat <- initial_constraints[['mat']]
      clb <- rep(0, ncol(con_mat))
      cub <- rep(1, ncol(con_mat))
      rlb <- initial_constraints[['rlb']]
      rub <- initial_constraints[['rub']]
      dir <- -1
      # user specified constraints
      user <- val_constraints()
      if(nrow(user) > 0) {
        con_coefs <- data_constraints()
        vars <- data_variables()
        cons <- get_constraints(con_coefs, vars, user)
        con_mat <- rbind(con_mat, cons$con_mat)
        rlb <- c(rlb, cons$rlb)
        rub <- c(rub, cons$rub)
      }
      saveRDS(list(obj_mat = obj_mat, con_mat = con_mat, dir = dir, clb = clb, cub = cub, rlb = rlb, rub = rub), 'args.RDS')

      # TODO: progress bar, split into chunks etc
      res <- solve_lp(obj_mat, con_mat, dir = dir, clb = clb, cub = cub, rlb = rlb, rub = rub)

      val_results(res)
    }, error = function(e) raise_error(e))
  })

  val_results <- reactiveVal(NULL)

  # convert from raw outputs back into original format
  val_results_cleaned <- reactive({
    req(res <- val_results())
    dt <- data_objective()
    res %>%
      extract2('col_prim') %>%
      select_best_option(ncol(dt)) %>%
      {mutate(dt, choice = .)}
  })

  # sample of results
  output$dt_results <- renderDataTable({
    req(res <- val_results_cleaned())
    res %>%
      head(1000) %>%
      datatable(rownames=FALSE, options=list(dom='tp'))
  })

  # show download option if optimiser has been run
  output$ui_dl_results <- renderUI({
    req(res <- val_results_cleaned())
    downloadButton('dl_results', 'Download Output')
  })
  output$dl_results <- downloadHandler(
      filename = function() {
        'optimiser_results.csv'
      },
      content = function(file) {
        write_csv(val_results_cleaned(), file)
      }
    )

})
