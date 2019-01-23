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
          tags$li('Upload a dataset with the objective to optimise'),
          tags$ul(
            tags$li('
              This should be a csv where rows are records of interest, and
              columns are potential actions to take on those records.  Each
              entry for a row and column combination should represent the value
              obtained by taking that action for that record.
            ')
          ),
          tags$li('Optionally upload a dataset corresponding to constraints'),
          tags$ul(
            tags$li('
              This should have the same structure as the objective dataset, but
              instead of entries corresponding to value of an option, these
              should represent weights for each option that must be taken into
              account as limitations.
            ')
          ),
          tags$li('Configure optimisation parameters and run!')
        )
      )
    ),
    tabItem(tabName='nav_data',
      box(width = 12, title = 'Data Selection',
        fileInput('file_objective', 'CSV of Objective Weights',
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
          'Set all constraint weights to 1'
        ),
        conditionalPanel("!input.check_constraints_constant",
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
        conditionalPanel("input.check_constraints_filter",
          fileInput('file_variables', 'CSV of Constraint Variables',
            multiple = FALSE,
            accept   = c('text/csv', 'text/comma-separated-values', '.csv')
          )
        )
      ),
      box(width = 12, title = 'Constraint Specification',
        # select a variable and value combination to apply to (or all)
        fluidRow(
          column(width = 4, uiOutput('ui_sel_con_var')),
          column(width = 4, uiOutput('ui_sel_con_val')),
          column(width = 4, uiOutput('ui_sel_con_col'))
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
