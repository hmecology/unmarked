# Method for all fit types, exported
setMethod("fitted", "unmarkedFit", function(object, ...){
  fitted_internal(object)
})


# Internal method for specific fit type, not exported
setGeneric("fitted_internal", function(object){
  standardGeneric("fitted_internal")
})


setMethod("fitted_internal", "unmarkedFit", function(object){
  state <- predict(object, type = "state", level=NULL, na.rm=FALSE)$Predicted
  p <- getP(object, na.rm = FALSE) # P(detection | presence)
  fitted <- state * p  # true for models with E[Y] = p * E[X]
  fitted
})


setMethod("fitted_internal", "unmarkedFitColExt", function(object)
{
    data <- object@data
    M <- numSites(data)
    nY <- data@numPrimary
    J <- obsNum(data)/nY

    psiP <- predict(object, type = "psi", level = NULL, na.rm=FALSE)$Predicted
    detP <- predict(object, type = "det", level = NULL, na.rm=FALSE)$Predicted
    colP <- predict(object, type = "col", level = NULL, na.rm=FALSE)$Predicted
    extP <- predict(object, type = "ext", level = NULL, na.rm=FALSE)$Predicted

    detP <- array(detP, c(J, nY, M))
    colP <- matrix(colP, M, nY, byrow = TRUE)
    extP <- matrix(extP, M, nY, byrow = TRUE)

    ## create transition matrices (phi^T)
    phis <- array(NA,c(2,2,nY-1,M)) #array of phis for each
    for(i in 1:M) {
        for(t in 1:(nY-1)) {
            phis[,,t,i] <- matrix(c(1-colP[i,t], colP[i,t], extP[i,t],
                1-extP[i,t]))
            }
        }

    ## first compute latent probs
    x <- array(NA, c(2, nY, M))
    x[1,1,] <- 1-psiP
    x[2,1,] <- psiP
    for(i in 1:M) {
        for(t in 2:nY) {
            x[,t,i] <- (phis[,,t-1,i] %*% x[,t-1,i])
            }
        }

    ## then compute obs probs
    fitted <- array(NA, c(J, nY, M))
    for(i in 1:M) {
        for(t in 1:nY) {
            for(j in 1:J) {
                fitted[j,t,i] <- (x[,t,i] %*%
                    matrix(c(1, 1 - detP[j,t,i], 0, detP[j,t,i]), 2, 2))[2]
                }
            }
        }

    return(matrix(fitted, M, J*nY, byrow = TRUE))
})


setMethod("fitted_internal", "unmarkedFitDS", function(object){
    data <- object@data
    db <- data@dist.breaks
    w <- diff(db)
    M <- numSites(data)
    J <- length(w)
    lambda <- predict(object, type = "state", level = NULL, na.rm=FALSE)$Predicted
    # TODO: use getUA function here
    if(identical(object@output, "density")) {
        a <- matrix(NA, M, J)
        switch(data@survey,
            line = {
                tlength <- data@tlength
                A <- tlength * max(db) * 2
                },
            point = {
                A <- pi * max(db)^2
                })
        switch(data@unitsIn,
            m = A <- A / 1e6,
            km = A <- A)
        switch(object@unitsOut,
            m = A <- A * 1e6,
            ha = A <- A * 100,
            kmsq = A <- A)
        lambda <- lambda * A
        }
    cp <- getP(object, na.rm = FALSE)
    fitted <- lambda * cp
    fitted
})


# This covers unmarkedFitGDS too
setMethod("fitted_internal", "unmarkedFitGMM", function(object){
  # E[y_itj] = M_i * phi_it * cp_itj
  M <- numSites(object@data)
  T <- object@data@numPrimary
  J <- ncol(object@data@y) / T

  lambda <- predict(object, type = "lambda", level = NULL, na.rm=FALSE)$Predicted
  if(identical(object@mixture, "ZIP")) {
    psi <- plogis(coef(object, type="psi"))
    lambda <- (1-psi)*lambda
  }

  if(T==1){
    phi <- 1
  } else {
    phi <- predict(object, type = "phi", level = NULL, na.rm=FALSE)$Predicted
  }
  phi.mat <- matrix(phi, nrow=M, ncol=T, byrow=TRUE)
  phi.ijt <- as.numeric(apply(phi.mat, 2, rep, times=J))
  cp <- getP(object, na.rm = FALSE)

  fitted <- lambda * phi.ijt * as.numeric(cp) # recycle
  fitted <- matrix(fitted, M, J*T)
  fitted
})


setMethod("fitted_internal", "unmarkedFitNmixTTD", function(object){
  stop("fitted is not implemented for nmixTTD at this time", call.=FALSE)
})


# Doesn't use default method because of knownOcc
setMethod("fitted_internal", "unmarkedFitOccu", function(object){
    state <- predict(object, type = "state", level=NULL, na.rm=FALSE)$Predicted
    state[object@knownOcc] <- 1
    p <- getP(object, na.rm = FALSE) # P(detection | presence)
    fitted <- state * p  # true for models with E[Y] = p * E[X]
    fitted
})


setMethod("fitted_internal", "unmarkedFitOccuFP", function(object){
  stop("fitted is not implemented for occuFP at this time", call.=FALSE)
})


setMethod("fitted_internal", "unmarkedFitOccuMulti", function(object){
  S <- length(object@data@ylist)
  J <- ncol(object@data@ylist[[1]])
  pmat <- getP(object)

  fitted_list <- list()
  for (i in 1:S){
    marg_occ <- predict(object,'state',level=NULL,species=i)$Predicted
    occmat <- t(tcrossprod(rep(1,J),marg_occ))
    fitted_list[[i]] <- pmat[[i]] * occmat
  }
  names(fitted_list) <- names(object@data@ylist)
  fitted_list
})


setMethod("fitted_internal", "unmarkedFitOccuMS", function(object){
  data <- object@data
  T <- data@numPrimary
  J <- obsNum(data) / T
  N <- numSites(data)
  S <- data@numStates

  if(T>1){
    stop('Not implemented for dynamic models')
  }

  guide <- matrix(NA,nrow=S,ncol=S)
  guide <- lower.tri(guide,diag=TRUE)
  guide[,1] <- FALSE
  guide <- which(guide,arr.ind=TRUE)

  #Get predictions
  pr <- predict(object, 'psi', level=NULL)
  pr <- sapply(pr,function(x) x$Predicted)
  pr <- pr[rep(1:nrow(pr),each=J),]

  pr_det <- predict(object, 'det', level=NULL)
  pr_det <- sapply(pr_det,function(x) x$Predicted)

  fitvals <- rep(NA, nrow(pr_det))
  if(object@parameterization == 'multinomial'){
    pr <- cbind(1-rowSums(pr),pr)

    for (i in 1:nrow(pr_det)){
      occ <- pr[i,]
      sdp <- matrix(0,nrow=S,ncol=S)
      sdp[guide] <- pr_det[i,]
      sdp[,1] <- 1 - rowSums(sdp)
      fitvals[i] <- occ %*% sdp %*% 0:(S-1)
    }

  } else if(object@parameterization == 'condbinom'){
    stop('Conditional binomial parameterization not supported yet')
  }
  fit_out <- matrix(fitvals,N,J,byrow=T)

  fit_out
})


setMethod("fitted_internal", "unmarkedFitOccuRN", function(object){
  M <- numSites(object@data)
  J <- obsNum(object@data)
  lam <- predict(object, type = "state", level = NULL, na.rm=FALSE)$Predicted
  lam <- rep(lam, each = J)
  r <- predict(object, type = "det", level = NULL, na.rm=FALSE)$Predicted
  fitted <- 1 - exp(-lam*r) ## analytical integration.
  matrix(fitted, M, J, byrow = TRUE)
})


setMethod("fitted_internal", "unmarkedFitOccuTTD", function(object){
  N <- nrow(object@data@y)
  T <- object@data@numPrimary
  J <- ncol(object@data@y)/T

  #Get predicted values
  psi <- predict(object, 'psi', na.rm=FALSE)$Predicted
  psi <- cbind(1-psi, psi)
  est_p <- getP(object)
  est_p <- as.numeric(t(est_p))
  est_p <- cbind(1-est_p, est_p)

  if(T>1){
    p_col <- predict(object, 'col', na.rm=FALSE)$Predicted
    p_ext <- predict(object, 'ext', na.rm=FALSE)$Predicted
    rem_seq <- seq(T, length(p_col), T)
    p_col <- p_col[-rem_seq]
    p_ext <- p_ext[-rem_seq]
    phi <- cbind(1-p_col, p_col, p_ext, 1-p_ext)
  }

  ## first compute latent probs
  state <- array(NA, c(2, T, N))
  state[1:2,1,] <- t(psi)

  if(T>1){
    phi_ind <- 1
    for(n in 1:N) {
      for(t in 2:T) {
        phi_mat <- matrix(phi[phi_ind,], nrow=2, byrow=TRUE)
        state[,t,n] <- phi_mat %*% state[,t-1,n]
        phi_ind <- phi_ind + 1
      }
    }
  }

  ## then compute obs probs
  obs <- array(NA, c(J, T, N))
  p_ind <- 1
  for(n in 1:N) {
    for(t in 1:T) {
      for(j in 1:J) {
        pmat <- matrix(c(1,0, est_p[p_ind,]), nrow=2, byrow=TRUE)
        obs[j,t,n] <- (state[,t,n] %*% pmat)[2] #prob y=1
        p_ind <- p_ind + 1
      }
    }
  }

  matrix(obs, N, J*T, byrow=TRUE)
})


setMethod("fitted_internal", "unmarkedFitPCount", function(object){
    data <- object@data
    M <- numSites(data)
    J <- obsNum(data)
    state <- predict(object, type = "state", level = NULL, na.rm=FALSE)$Predicted
    p <- getP(object, na.rm = FALSE)
    mix <- object@mixture
    switch(mix,
           P = {
               fitted <- as.numeric(state) * p
           },
           NB = {
               ## I don't think this sum is necessary. Could do:
               ## fitted <- as.numeric(state) * p
               K <- object@K
               k <- 0:K
               k.ijk <- rep(k, M*J)
               state.ijk <- state[rep(1:M, each = J*(K+1))]
               alpha <- exp(coef(object['alpha']))
               prob.ijk <- dnbinom(k.ijk, mu = state.ijk, size = alpha)
               all <- cbind(rep(as.vector(t(p)), each = K + 1), k.ijk,
                            prob.ijk)
               prod.ijk <- rowProds(all)
               fitted <- colSums(matrix(prod.ijk, K + 1, M*J))
               fitted <- matrix(fitted, M, J, byrow = TRUE)
           },
           ZIP = {
               psi <- plogis(coef(object['psi']))
               lambda <- as.numeric(state)
               E.N <- (1-psi)*lambda
#               fitted <- (1-psi)*lambda
#               fitted <- matrix(fitted, M, J, byrow=TRUE) # BUG
               fitted <- E.N * p
           })
    return(fitted)
})


setMethod("fitted_internal", "unmarkedFitDailMadsen", function(object){
    dynamics <- object@dynamics
    mixture <- object@mixture
    #To partially handle old saved model objects
    fix <- tryCatch(object@fix, error=function(e) "none")
    immigration <- tryCatch(object@immigration, error=function(e) FALSE)
    data <- getData(object)
    D <- getDesign(data, object@formula, na.rm = FALSE)
    delta <- D$delta #FIXME this isn't returned propertly when na.rm=F

    M <- numSites(data)
    T <- data@numPrimary
    J <- ncol(data@y) / T

    lambda <- predict(object, type = "lambda", level = NULL, na.rm=FALSE)$Predicted
    if(identical(mixture, "ZIP")) {
        psi <- plogis(coef(object, type="psi"))
        lambda <- (1-psi)*lambda
    }
    if (fix == 'omega'){
      omega <- matrix(1, M, T-1)
    } else if(!identical(dynamics, "trend")) {
        omega <- predict(object, type = "omega", level = NULL, na.rm=FALSE)$Predicted
        omega <- matrix(omega, M, T-1, byrow=TRUE)
    }
    if(fix == "gamma"){
        gamma <- matrix(0, M, T-1)
    } else if(!identical(dynamics, "notrend")){
        gamma <- predict(object, type = "gamma", level = NULL, na.rm=FALSE)$Predicted
        gamma <- matrix(gamma, M, T-1, byrow=TRUE)
    } else {
        if(identical(dynamics, "notrend"))
            gamma <- (1-omega)*lambda
        }
    if(immigration){
        iota <- predict(object, type = "iota", level = NULL, na.rm=FALSE)$Predicted
        iota <- matrix(iota, M, T-1, byrow=TRUE)
    } else {
        iota <- matrix(0, M, T-1)
    }

    N <- matrix(NA, M, T)
    for(i in 1:M) {
        N[i, 1] <- lambda[i]
        if(delta[i, 1] > 1) {
            for(d in 2:delta[i ,1]) {
                if(identical(dynamics, "autoreg"))
                    N[i, 1] <- N[i, 1] * (omega[i,1] + gamma[i, 1]) + iota[i, 1]
            else if(identical(dynamics, "trend"))
                N[i,1] <- N[i,1] * gamma[i,1] + iota[i, 1]
            else if(identical(dynamics, "ricker"))
                N[i,1] <- N[i,1] * exp(gamma[i,1]*(1-N[i,1]/omega[i,1])) +
                    iota[i, 1]
            else if(identical(dynamics, "gompertz"))
                N[i,1] <- N[i,1] * exp(gamma[i,1]*(1-log(N[i,1]+1)/
                  log(omega[i,1]+1))) + iota[i, 1]
            else
                N[i,1] <- N[i,1] * omega[i,1] + gamma[i,1]
                }
            }
        for(t in 2:T) {
            if(identical(dynamics, "autoreg"))
                N[i, t] <- N[i, t-1] * (omega[i, t-1] + gamma[i, t-1]) +
                    iota[i, t-1]
            else if(identical(dynamics, "trend"))
                N[i,t] <- N[i,t-1] * gamma[i,t-1] + iota[i, t-1]
            else if(identical(dynamics, "ricker"))
                N[i,t] <- N[i,t-1]*exp(gamma[i,t-1]*(1-N[i,t-1]/omega[i,t-1]))+
                    iota[i, t-1]
            else if(identical(dynamics, "gompertz"))
                N[i,t] <- N[i,t-1] * exp(gamma[i,t-1]*(1-log(N[i,t-1]+1)/
                  log(omega[i,t-1]+1))) + iota[i, t-1]
            else
                N[i,t] <- N[i,t-1] * omega[i,t-1] + gamma[i,t-1]
            if(delta[i, t] > 1) {
                for(d in 2:delta[i, t]) {
                    if(identical(dynamics, "autoreg"))
                        N[i, t] <- N[i, t] * (omega[i, t-1] + gamma[i, t-1]) +
                            iota[i, t-1]
                    else if(identical(dynamics, "trend"))
                        N[i, t] <- N[i, t] * gamma[i, t-1] + iota[i, t-1]
                    else if(identical(dynamics, "ricker"))
                        N[i, t] <- N[i, t] * exp(gamma[i, t-1] * (1 - N[i,t] /
                            omega[i,t-1]))+ iota[i, t-1]
                    else if(identical(dynamics, "gompertz"))
                        N[i, t] <- N[i, t] * exp(gamma[i, t-1] * (1 -
                            log(N[i, t]+1) / log(omega[i, t-1] + 1))) +
                            iota[i, t-1]
                    else
                        N[i,t] <- N[i,t] * omega[i, t-1] + gamma[i, t-1]
                    }
                }
            }
        }
    N <- N[,rep(1:T, each=J)]


    p <- getP(object, na.rm = FALSE)
    N * p
})

