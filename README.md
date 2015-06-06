# openhousing
OpenOakland's Open Housing 


# Getting Started


## Install R (Mac OS X)

1. Install R from rstudio.com: http://cran.rstudio.com/bin/macosx/R-3.2.0.pkg.

Verify that R is installed:

```
Eugene-Koontzs-Mac-Pro:~ ekoontz$ which R
/usr/bin/R
Eugene-Koontzs-Mac-Pro:~ ekoontz$ R

R version 3.2.0 (2015-04-16) -- "Full of Ingredients"
Copyright (C) 2015 The R Foundation for Statistical Computing
Platform: x86_64-apple-darwin13.4.0 (64-bit)
```

## Install R libraries

From the R prompt (run ```R``` as shown above):

```
> chooseCRANmirror()
CRAN mirror

  1: 0-Cloud                        2: Algeria
...

```

Find a mirror close to you - I chose:

```85: USA (CA 1)```.

```
> chooseCRANmirror()
install.packages(c("XML"))
install.packages(c("RCurl"))
install.packages(c("stringr"))
install.packages(c("ggplot2"))
install.packages(c("maptools"))
install.packages(c("rgeos"))
install.packages(c("ggmap"))
```

## Load the OaklandDemoZipTract.r

```
setwd('~/openhousing/')
source('data/OaklandDemoZipTract.r')
```


