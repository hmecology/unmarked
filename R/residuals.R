# Method for all fit types, exported
setMethod("residuals", "unmarkedFit", function(object, ...){
  residuals_internal(object)
})

# Internal method for specific fit types, not exported
setGeneric("residuals_internal", function(object){
  standardGeneric("residuals_internal")
})

setMethod("residuals_internal", "unmarkedFit", function(object) {
    y <- getY(object)
    e <- fitted(object)
    r <- y - e
    return(r)
})

setMethod("residuals_internal", "unmarkedFitOccuMulti", function(object) {
  res_list <- list()
  ylist <- getY(object)
  fitlist <- fitted(object)

  for (i in seq_along(ylist)){
    res_list[[i]] <- ylist[[i]] - fitlist[[i]]
  }
  names(res_list) <- names(ylist)
  res_list
})

setMethod("residuals_internal", "unmarkedFitOccuTTD", function(object) {
  tmax <- object@data@surveyLength
  yraw <- object@data@y
  y <- ifelse(yraw<tmax,1,0)
  e <- fitted(object)
  y - e
})
