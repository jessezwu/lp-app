# Optimisation app

Solve linear programming optimisation problems using a graphical interface.

## Install

This app is built in and requires [R](https://www.r-project.org/).

coin-Clp must also be installed separately, see the [web
instructions](https://projects.coin-or.org/Clp).

Note that Clp is available for Debian, Ubuntu, and via Homebrew for
[OSX](https://github.com/coin-or-tools/homebrew-coinor).

Once Clp is installed, several packages are required in R:

```{r}
packages <- c(
  'magrittr',
  'dplyr',
  'readr',
  'ggplot2',
  'plotly',
  'DT',
  'shiny',
  'shinydashboard',
  'clpAPI' # depends on coin-Clp
)
install.packages(packages)
```

## Running

```{bash}
Rscript run_app.R
```

### Requirements

A prescored dataset, rows should be individual records to be optimised, columns
should correspond to potential actions to be applied to each row.

A value for a combination of row 'i' and column 'j' should then indicate the
predicted value for record 'i' given action 'j'.

Additional constraints can be imposed using a separate file - this must
represent the same records and actions from the original objective dataset,
assuming row order is the same. The values for each row and column combination
is a weight for the constraints to be applied to teach option.

An additional dataset can be used to selectively apply constraints to
particular rows. Each column here indicates a feature that can be used to
create constraints across rows.

* E.g. if a record was a customer, a feature could be age, and you might want to
enforce a maximum number of people under 25 to be targeted by marketing.
Since we only care about total numbers, the constraint input will just a be a
matrix of 1's.
* E.g. if instead of total numbers, a constraint was on something like
conversion, the constraint input should then be conversion probability given a
record and action. Then the constraint could be something like 18-20 year olds
must have a conversion of 80% on average. The objective metric will be
sacrificed in order to satisfy this.

### Outputs

A choice of action for each row.

Warnings will be given if the problem is unsolvable, e.g. if constraints are
too extreme or contradictory.

## Limitations

* Only one type of constraint is supported at a time using the interface.
    * E.g. this means you can't easily enforce a maximum number of marketing
      actions by channel as well as conversion rates on those targeted.
* Optimisations at a completely global level are infeasible for large datasets.
    * Unless you can wait for hours or days the recommendation is to split data
      into separate chunks and optimise locally as a compromise.
