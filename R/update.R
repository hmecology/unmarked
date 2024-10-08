setMethod("update", "unmarkedFit", function(object, ..., evaluate=TRUE){
  inputs <- list(...)
  nm <- names(inputs)
  if(any(nm == "")) stop("All provided arguments to update should be named", call.=FALSE)
  # Re-create the original call with as many original args as possible
  cl <- rebuild_call(object)

  for (i in names(inputs)){
    cl[[i]] <- NA # Need to create blank entry first to fill in
    if(i == "data"){
      # Insert the quoted object name instead of the entire umf object
      # This prevents the @call slot from being filled with data
      cl[[i]] <- substitute(INP, list(INP = quote(inputs$data)))
    } else {
      cl[[i]] <- inputs[[i]]
    }
  }

  if(!evaluate) return(cl)

  eval(cl)
})

# This method starts with a fitted model's saved call, and inserts
# as much saved information from the object into the call as possible.
# This avoids situations where the original call referenced e.g. a 
# vector of formulas saved in the global environment, which would not be
# available if updating the model later in a different environment.
# In general we're just inserting everything from fit-specific slots
# in the unmarkedFit object that is also an input argument.
setGeneric("rebuild_call", function(object) standardGeneric("rebuild_call"))

# This method is not actually used directly by any fitting function, instead
# it's a base piece of the call for most of them.
# Note that data is saved as quoted code instead of directly as an object
# This prevents the entire contents of the unmarkedFrame from being
# inserted directly into the call which clogs up the console
setMethod("rebuild_call", "unmarkedFit", function(object){ 
  cl <- object@call
  cl[["data"]] <- quote(object@data)
  cl
})

setMethod("rebuild_call", "unmarkedFitColExt", function(object){ 
  cl <- methods::callNextMethod(object) # calls base class method above
  cl[["psiformula"]] <- object@psiformula
  cl[["gammaformula"]] <- object@gamformula
  cl[["epsilonformula"]] <- object@epsformula
  cl[["pformula"]] <- object@detformula
  cl
})

# Covers MMO and PCO
setMethod("rebuild_call", "unmarkedFitDailMadsen", function(object){ 
  cl <- methods::callNextMethod(object)
  cl[["lambdaformula"]] <- object@formlist$lambdaformula
  cl[["gammaformula"]] <- object@formlist$gammaformula
  cl[["omegaformula"]] <- object@formlist$omegaformula
  cl[["pformula"]] <- object@formlist$pformula
  cl[["iotaformula"]] <- object@formlist$iotaformula
  cl[["mixture"]] <- object@mixture
  cl[["dynamics"]] <- object@dynamics
  cl[["immigration"]] <- object@immigration
  cl[["fix"]] <- object@fix
  if(methods::.hasSlot(object, "K")){
    cl[["K"]] <- object@K
  }
  cl
})

setMethod("rebuild_call", "unmarkedFitDS", function(object){ 
  cl <- methods::callNextMethod(object)
  cl[["formula"]] <- object@formula
  cl[["keyfun"]] <- object@keyfun
  cl[["unitsOut"]] <- object@unitsOut
  cl[["output"]] <- object@output
  cl
})

setMethod("rebuild_call", "unmarkedFitDSO", function(object){ 
  cl <- methods::callNextMethod(object) # Calls DailMadsen method
  cl[["keyfun"]] <- object@keyfun
  cl[["unitsOut"]] <- object@unitsOut
  cl[["output"]] <- object@output
  cl
})

# Also covers unmarkedFitGPC
setMethod("rebuild_call", "unmarkedFitGMM", function(object){ 
  cl <- methods::callNextMethod(object)
  cl[["lambdaformula"]] <- object@formlist$lambdaformula
  cl[["phiformula"]] <- object@formlist$phiformula
  cl[["pformula"]] <- object@formlist$pformula
  cl[["mixture"]] <- object@mixture
  if(methods::.hasSlot(object, "K")){
    cl[["K"]] <- object@K
  }
  cl
})

setMethod("rebuild_call", "unmarkedFitGDS", function(object){ 
  cl <- methods::callNextMethod(object) # calls GMM method
  cl[["keyfun"]] <- object@keyfun
  cl[["unitsOut"]] <- object@unitsOut
  cl[["output"]] <- object@output
  cl
})

setMethod("rebuild_call", "unmarkedFitMPois", function(object){ 
  cl <- methods::callNextMethod(object)
  cl[["formula"]] <- object@formula
  cl
})

setMethod("rebuild_call", "unmarkedFitNmixTTD", function(object){ 
  cl <- methods::callNextMethod(object)
  cl[["stateformula"]] <- object@stateformula
  cl[["detformula"]] <- object@detformula
  cl[["K"]] <- object@K
  cl
})

setMethod("rebuild_call", "unmarkedFitOccu", function(object){ 
  cl <- methods::callNextMethod(object)
  cl[["formula"]] <- object@formula
  if(is.null(object@TMB)){
    cl[["knownOcc"]] <- quote(object@knownOcc)
  }
  cl
})

setMethod("rebuild_call", "unmarkedFitOccuFP", function(object){ 
  cl <- methods::callNextMethod(object)
  cl[["detformula"]] <- object@detformula
  cl[["FPformula"]] <- object@FPformula
  cl[["Bformula"]] <- object@Bformula
  cl[["stateformula"]] <- object@stateformula
  cl
})

setMethod("rebuild_call", "unmarkedFitOccuMS", function(object){ 
  cl <- methods::callNextMethod(object)
  cl[["detformulas"]] <- quote(object@detformulas)
  cl[["psiformulas"]] <- quote(object@psiformulas)
  if(!all(is.na(object@phiformulas))){
    cl[["phiformulas"]] <- quote(object@phiformulas)
  }
  cl[["parameterization"]] <- object@parameterization
  cl
})

setMethod("rebuild_call", "unmarkedFitOccuMulti", function(object){ 
  cl <- methods::callNextMethod(object)
  cl[["stateformulas"]] <- quote(object@stateformulas)
  cl[["detformulas"]] <- quote(object@detformulas)
  cl
})

setMethod("rebuild_call", "unmarkedFitPCount", function(object){ 
  cl <- methods::callNextMethod(object)
  cl[["formula"]] <- object@formula
  cl[["mixture"]] <- object@mixture
  if(methods::.hasSlot(object, "K")){
    cl[["K"]] <- object@K
  }
  cl
})

setMethod("rebuild_call", "unmarkedFitOccuPEN", function(object){ 
  cl <- methods::callNextMethod(object)
  cl[["formula"]] <- object@formula
  cl[["knownOcc"]] <- quote(object@knownOcc)
  cl[["pen.type"]] <- object@pen.type
  cl[["lambda"]] <- object@lambda
  cl
})

setMethod("rebuild_call", "unmarkedFitOccuRN", function(object){ 
  cl <- methods::callNextMethod(object)
  cl[["formula"]] <- object@formula
  # For backwards compatibility
  if(methods::.hasSlot(object, "K")){
    cl[["K"]] <- object@K
  }
  cl
})

setMethod("rebuild_call", "unmarkedFitOccuTTD", function(object){ 
  cl <- methods::callNextMethod(object)
  cl[["psiformula"]] <- object@psiformula
  cl[["gammaformula"]] <- object@gamformula
  cl[["epsilonformula"]] <- object@epsformula
  cl[["detformula"]] <- object@detformula
  cl
})
