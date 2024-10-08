\name{unmarkedFit-class}
\Rdversion{1.1}
\docType{class}
\alias{unmarkedFit}
\alias{unmarkedFit-class}
\alias{getData}
\alias{getData,unmarkedFit-method}
\alias{hist,unmarkedFitDS-method}
\alias{names,unmarkedFit-method}
\alias{plot,unmarkedFit,missing-method}
\alias{profile,unmarkedFit-method}
\alias{update,unmarkedFit-method}
\alias{plot,profile,missing-method}
\alias{sampleSize}
\alias{sampleSize,unmarkedFit-method}
\alias{summary,unmarkedFit-method}
\alias{smoothed}
\alias{smoothed,unmarkedFitColExt-method}
\alias{projected}
\alias{projected,unmarkedFitColExt-method}
\alias{logLik}
\alias{logLik,unmarkedFit-method}
\alias{LRT}
\alias{LRT,unmarkedFit,unmarkedFit-method}
\alias{getY,unmarkedFit-method}

\title{Class "unmarkedFit" }
\description{Contains fitted model information which can be manipulated or
extracted using the methods described below.
}
\section{Methods}{
  \describe{
    \item{[}{\code{signature(x = "unmarkedFit", i = "ANY", j = "ANY",
		drop = "ANY")}: extract one of names(obj), eg 'state' or 'det' }
    \item{backTransform}{\code{signature(obj = "unmarkedFit")}: back-transform
		parameters to original scale when no covariate effects are modeled }
    \item{coef}{\code{signature(object = "unmarkedFit")}: returns parameter
		estimates. type can be one of names(obj), eg 'state' or 'det'.
        If altNames=TRUE estimate names are more specific. }
    \item{confint}{\code{signature(object = "unmarkedFit")}: Returns confidence
		intervals. Must specify type and method (either "normal" or "profile") }
    \item{getData}{\code{signature(object = "unmarkedFit")}: extracts data }
    \item{getFP}{\code{signature(object = "unmarkedFit")}: calculates and extracts
  	expected false positive detection probabilities }
    \item{getB}{\code{signature(object = "unmarkedFit")}: calculates and extracts
  	expected probabilities a true positive detection was classified as certain }
    \item{linearComb}{\code{signature(obj = "unmarkedFit",
		coefficients = "matrixOrVector")}: Returns estimate and SE on original
		scale when covariates are present }
    \item{names}{\code{signature(x = "unmarkedFit")}: Names of parameter levels }
    \item{parboot}{\code{signature(object = "unmarkedFit")}: Parametric
		bootstrapping method to assess goodness-of-fit }
    \item{plot}{\code{signature(x = "unmarkedFit", y = "missing")}: Plots
		expected vs. observed values }
    \item{profile}{\code{signature(fitted = "unmarkedFit")}: used by confint
		method='profile' }
    \item{sampleSize}{\code{signature(object = "unmarkedFit")}: returns number
		of sites in sample }
    \item{SE}{\code{signature(obj = "unmarkedFit")}: returns standard errors }
    \item{summary}{\code{signature(object = "unmarkedFit")}: results with more
		details }
    \item{update}{\code{signature(object = "unmarkedFit")}: refit model with
		changes to one or more arguments }
    \item{vcov}{\code{signature(object = "unmarkedFit")}: returns
      variance-covariance matrix }
    \item{smoothed}{\code{signature(object="unmarkedFitColExt")}:
      Returns the smoothed trajectory from a colonization-extinction
      model fit.  Takes additional logical argument mean which specifies
    whether or not to return the average over sites.}
    \item{projected}{\code{signature(object="unmarkedFitColExt")}:
      Returns the projected trajectory from a colonization-extinction
      model fit.  Takes additional logical argument mean which specifies
    whether or not to return the average over sites.}
    \item{logLik}{\code{signature(object="unmarkedFit")}:
        Returns the log-likelihood.}
    \item{LRT}{\code{signature(m1="unmarkedFit", m2="unmarkedFit")}:
        Returns the chi-squared statistic, degrees-of-freedom, and p-value from
        a Likelihood Ratio Test.}
	 }
}
\note{ This is a superclass with child classes for each fit type }
\examples{
showClass("unmarkedFit")

# Format removal data for multinomPois
data(ovendata)
ovenFrame <- unmarkedFrameMPois(y = ovendata.list$data,
	siteCovs = as.data.frame(scale(ovendata.list$covariates[,-1])),
	type = "removal")

# Fit a couple of models
(fm1 <- multinomPois(~ 1 ~ ufc + trba, ovenFrame))
summary(fm1)

# Apply a bunch of methods to the fitted model

# Look at the different parameter types
names(fm1)
fm1['state']
fm1['det']

# Coefficients from abundance part of the model
coef(fm1, type='state')

# Variance-covariance matrix
vcov(fm1, type='state')

# Confidence intervals using profiled likelihood
confint(fm1, type='state', method='profile')

# Expected values
fitted(fm1)

# Original data
getData(fm1)

# Detection probabilities
getP(fm1)

# log-likelihood
logLik(fm1)

# Back-transform detection probability to original scale
# backTransform only works on models with no covariates or
#     in conjunction with linearComb (next example)
backTransform(fm1, type ='det')

# Predicted abundance at specified covariate values
(lc <- linearComb(fm1, c(Int = 1, ufc = 0, trba = 0), type='state'))
backTransform(lc)

# Assess goodness-of-fit
parboot(fm1)
plot(fm1)

# Predict abundance at specified covariate values.
newdat <- data.frame(ufc = 0, trba = seq(-1, 1, length=10))
predict(fm1, type='state', newdata=newdat)

# Fit a new model without covariates
(fmNull <- update(fm1, formula = ~1 ~1))

}
\keyword{classes}
