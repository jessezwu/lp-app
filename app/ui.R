library(DT, warn.conflicts = FALSE)
library(shiny, warn.conflicts = FALSE)
library(shinydashboard, warn.conflicts = FALSE, verbose = FALSE)
library(shinyjs, warn.conflicts = FALSE)

# Define the UI layout
shinyUI(dashboardPage(skin = 'black',
  dashboardHeader(title = 'Optimisation'),
  dashboardSidebar(width = 300, fluidPage(
    useShinyjs(),
    sidebarMenu(id = 'menu',
      menuItem('Guide',
        tabName = 'nav_info',
        icon = icon('info')
      ),
      menuItem('Data',
        tabName = 'nav_data',
        icon = icon('table')
      ),
      menuItem('Constraints',
        tabName = 'nav_con',
        icon = icon('arrows-alt')
      ),
      menuItem('Optimiser',
        tabName = 'nav_optim',
        icon = icon('calculator')
      )
    )
  )),
  # Main panel
  dashboardBody(fluidPage(tabItems(
    tabItem(tabName = 'nav_info',
      box(width = 12, title = 'Instructions',
        tags$ol(
          tags$li('Upload a csv dataset with the objective to optimise'),
          tags$li('Optionally upload datasets corresponding to constraint
                  weights and filtering variables'),
          tags$li('Configure optimisation parameters and run!')
        )
      ),
      box(width = 12,
        strong('Inputs'),
        tags$ul(
          tags$li('
            A dataset defining objective values - what you are trying to
            maximise.
          '),
          tags$ul(
            tags$li('Rows should be individual records to be optimised.'),
            tags$li('Columns should correspond to potential actions to be
                    applied to each row.'),
            tags$li("
              A value for a combination of row 'i' and column 'j' should then
              indicate the predicted value for record 'i' given action 'j'.
            ")
          ),
          tags$li('
            (Optional) Additional constraints can be imposed using a separate file.
          '),
          tags$ul(
            tags$li('
              This must represent the same records and actions from the
              original objective dataset, and assumes that row order is the
              same.
            '),
            tags$li('
              The values for each row and column combination should represent a
              weight or coefficient to be applied to each action.
            ')
          ),
          tags$li('
            (Optional) A further third dataset can be used to selectively apply
            constraints to particular rows.
          '),
          tags$ul(
            tags$li('
              Each column here indicates a feature that can be used to create
              constraints that are restricted or filtered to a set of rows.
            ')
          )
        ),
        strong('Outputs'),
        tags$ul(
          tags$li('A choice of action for each row.'),
          tags$li('
            Warnings will be given if the problem is unsolvable, e.g. when
            constraints are too extreme or contradictory.
          ')
        ),
        strong('Example'),
        tags$ul(
          tags$li('
            Take a marketing example where records are potential customers and
            you want to maximise profit. We have two actions, do nothing or
            send some marketing material. The objective dataset should have an
            expected or predicted profit value for each customer (row) and
            under each action (two columns).
          '),
          tags$li('
            You might want to enforce a maximum limit on the number of people
            to be targeted by marketing. Since this only cares about total
            numbers, the constraint weights will just a be a matrix of 1s. You
            could then set a constraint like: only up to 100 people can be sent
            marketing material.
          '),
          tags$li('
            If you want a constraint on conversion instead of total numbers,
            the constraint weights should then be conversion probability given
            a record and action. You can also define other variables, using the
            third dataset, to selectively apply your conversion constraint to
            particular records. So the optimiser might run under the condition
            that 18 year olds must have at least an average conversion of 80%.
          ')
        )
      )
    ),
    tabItem(tabName='nav_data',
      box(width = 12, title = 'Data Selection',
        fileInput('file_objective', 'CSV of Objective Values',
          multiple = FALSE,
          accept = c('text/csv', 'text/comma-separated-values', '.csv')
        ),
        dataTableOutput('dt_objective'),
        uiOutput('ui_sample')
      )
    ),
    tabItem(tabName='nav_con',
      box(width = 6, title = 'Constraint Weights',
        checkboxInput(
          'check_constraints_constant',
          'Set all constraint weights to 1',
          value = TRUE
        ),
        conditionalPanel('!input.check_constraints_constant',
          fileInput('file_constraints', 'CSV of Constraint Weights',
            multiple = FALSE,
            accept   = c('text/csv', 'text/comma-separated-values', '.csv')
          )
        )
      ),
      box(width = 6, title = 'Filtering Variables',
        checkboxInput(
          'check_constraints_filter',
          'Use variables for row filters',
          value = FALSE
        ),
        conditionalPanel('input.check_constraints_filter',
          fileInput('file_variables', 'CSV of Constraint Variables',
            multiple = FALSE,
            accept   = c('text/csv', 'text/comma-separated-values', '.csv')
          )
        )
      ),
      box(width = 12, title = 'Constraint Specification',
        # select a variable and value combination to apply to (or all)
        fluidRow(
          column(width = 4, uiOutput('ui_sel_con_col')),
          column(width = 4, uiOutput('ui_sel_con_var')),
          column(width = 4, uiOutput('ui_sel_con_val'))
        ),
        # bounds on values, these will be scaled by number of rows
        fluidRow(
          column(width = 4,
            numericInput('num_con_low', 'Lower Bound', value = -Inf)
          ),
          column(width = 4,
            numericInput('num_con_up', 'Upper Bound', value = Inf)
          ),
          column(width = 4,
            selectizeInput('sel_con_type', 'Bound Type',
              choices = c('sum', 'mean'))
          )
        ),
        fluidRow(
          column(width = 4, offset = 4,
            actionButton(width = '100%', 'button_add_con', 'Add')
          )
        )
      ),
      box(width = 12,
        title = span(
          'Constraints',
          actionButton('button_del_all', 'Clear All', class='btn-xs')
        ),
        div(align = 'center',
          dataTableOutput('dt_constraints'),
          uiOutput('ui_button_con_delete')
        )
      )),
    tabItem(tabName='nav_optim',
      box(width = 12, title = 'Optimiser Options',
        div(align = 'center',
          actionButton(width = '50%', 'button_run', 'Run Optimiser')
        )
        # TODO: maximum number of rows to optimise at once, sampling before running whole thing
      ),
      box(width = 12, title = 'Sample',
        dataTableOutput('dt_results'),
        uiOutput('ui_dl_results')
      )
    )
  )))
))
