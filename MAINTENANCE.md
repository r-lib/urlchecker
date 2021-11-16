## Current state

Generally urlchecker is stable.
The one ongoing thing that needs to be done periodically is to update the code in inst/tools/urltools.R to include the latest code in R (e.g. svn cat -r 80050 https://svn.r-project.org/R/trunk/src/library/tools/R/urltools.R > urltools.R).
If the code updates call new functions not defined in urltools.R you may have to backport their definitions, you can put them in `utils.R`

## Known outstanding issues

It might be worth someone tracking down https://github.com/r-lib/urlchecker/issues/15 and seeing if we can tweak our code to handle this case.

## Future directions

Handle .bib URLs (https://github.com/r-lib/urlchecker/issues/13)
