context("gpcount fitting function")
skip_on_cran()

test_that("unmarkedFrameGPC subset works",{
    y <- matrix(1:27, 3)
    sc <- data.frame(x1 = 1:3)
    ysc <- list(x2 = matrix(1:9, 3))
    oc <- list(x3 = matrix(1:27, 3))

    umf1 <- unmarkedFrameGPC(
        y = y,
        siteCovs = sc,
        yearlySiteCovs = ysc,
        obsCovs = oc,
        numPrimary = 3)

    dat <- as(umf1, "data.frame")

    umf1.site1 <- umf1[1,]
    expect_equal(umf1.site1@y, y[1,, drop=FALSE])
    expect_equal(umf1.site1@siteCovs, sc[1,, drop=FALSE])
    expect_equivalent(unlist(umf1.site1@obsCovs), oc$x3[1,])
    expect_equivalent(unlist(umf1.site1@yearlySiteCovs),
        ysc$x2[1,, drop=FALSE])
    expect_equal(umf1.site1@numPrimary, 3)

    umf1.sites1and3 <- umf1[c(1,3),]

    expect_is(umf1.site1, "unmarkedFrameGPC")

    umf1.sites1and1 <- umf1[c(1,1),]
    expect_equivalent(umf1.sites1and1[1,], umf1[1,])
    expect_equivalent(umf1.sites1and1[2,], umf1[1,])

    umf1.obs1and2 <- umf1[,c(1,2)]

    expect_equivalent(dim(getY(umf1.obs1and2)), c(3,6))
    expect_equivalent(dim(siteCovs(umf1.obs1and2)), c(3,1))
    expect_equivalent(dim(obsCovs(umf1.obs1and2)), c(18,1))

    umf1.sites1and2.obs1and2 <- umf1[c(1,2),c(1,2)]
    expect_equal(class(umf1.sites1and2.obs1and2)[1], "unmarkedFrameGPC")
    expect_equivalent(dim(getY(umf1.sites1and2.obs1and2)), c(2,6))
    expect_equivalent(dim(siteCovs(umf1.sites1and2.obs1and2)), c(2,1))
    expect_equivalent(dim(obsCovs(umf1.sites1and2.obs1and2)), c(12,1))

    # THis doesn't work
    umf1.sites1and1.obs1and1 <- umf1[c(1,1),c(1,1)]
})

test_that("gpcount function works", {
  set.seed(123)
  y <- matrix(c(0,0,0, 1,0,1, 2,2,2,
                3,2,3, 2,2,2, 1,1,1,
                NA,0,0, 0,0,0, 0,0,0,
                3,3,3, 3,1,3, 2,2,1,
                0,0,0, 0,0,0, 0,0,0), 5, 9, byrow=TRUE)
  siteCovs <- data.frame(x = c(0,2,-1,4,-1))
  obsCovs <- list(o1 = matrix(seq(-3, 3, length=length(y)), 5, 9))
  obsCovs$o1[5,4:6] <- NA
  yrSiteCovs <- list(yr=matrix(c('1','2','2'), 5, 3, byrow=TRUE))
  yrSiteCovs$yr[4,2] <- NA

  expect_warning(umf <- unmarkedFrameGPC(y = y, siteCovs = siteCovs, obsCovs = obsCovs,
        yearlySiteCovs = yrSiteCovs, numPrimary=3))

  expect_warning(fm <- gpcount(~x, ~yr, ~o1, data = umf, K=23))
  expect_equal(fm@sitesRemoved, integer(0))
  expect_equivalent(coef(fm),
        c(1.14754541, 0.44499137, -1.52079283, -0.08881542,
          2.52037155, -0.10950615), tol = 1e-5)

  # Check methods
  gp <- getP(fm)
  expect_equal(dim(gp), dim(y))
  expect_true(all(is.na(gp[5,4:6])))
  expect_equal(as.vector(gp[1:2, 1:2]), c(0.9452,0.9445,0.9413,0.9404), tol=1e-4)

  expect_warning(pr <- predict(fm, 'lambda'))
  expect_equal(dim(pr), c(nrow(y), 4))

  nd <- data.frame(x=c(0,1))
  pr <- predict(fm, 'lambda', newdata=nd)
  expect_equal(dim(pr), c(2,4))
  expect_equal(pr[1,1], c(3.15045), tol=1e-4)

  ft <- fitted(fm)
  expect_equal(dim(ft), dim(umf@y))
  expect_equal(round(ft,4)[1:2,1:2],
    structure(c(0.5341, 1.2995, 0.5318, 1.2939), dim = c(2L, 2L)))
  expect_true(all(is.na(ft[5,4:6]))) # missing obs covs
  expect_true(all(is.na(ft[4,4:6]))) # missing ysc cov for site 4 yr 2

  sc2 <- siteCovs
  sc2$x[1] <- NA
  umf2 <- umf
  umf2@siteCovs <- sc2
  expect_warning(fm2 <- gpcount(~x, ~yr, ~o1, data = umf2, K=10))
  ft2 <- fitted(fm2)
  expect_equal(dim(ft2), dim(umf2@y))
  expect_true(all(is.na(ft2[1,]))) # missing site cov

  res <- residuals(fm)
  expect_equal(dim(res), dim(y))

  r <- ranef(fm)
  expect_equal(dim(r@post), c(nrow(y), 24, 1))
  expect_equal(bup(r), c(7.31, 12.63, 1.30, 14.90, 2.04), tol=1e-3)

  expect_warning(s <- simulate(fm, 2))
  expect_equal(length(s), 2)
  expect_equal(dim(s[[1]]), dim(y))

  expect_warning(pb <- parboot(fm, nsim=1))
  expect_equal(pb@t.star[1], 24.06449, tol=1e-4)
  expect_is(pb, "parboot")

  npb <- expect_warning(nonparboot(fm, B=2))
  expect_equal(length(npb@bootstrapSamples), 2)
  expect_equal(npb@bootstrapSamples[[1]]@AIC, 36.08938, tol=1e-4)
  v <- vcov(npb, method='nonparboot')
  expect_equal(nrow(v), length(coef(npb)))

  # Check error when random effect in formula
  expect_error(gpcount(~(1|dummy),~1,~1,umf))

})

test_that("gpcount R and C++ engines give same results",{

  y <- matrix(c(0,0,0, 1,0,1, 2,2,2,
                3,2,3, 2,2,2, 1,1,1,
                NA,0,0, 0,0,0, 0,0,0,
                3,3,3, 3,1,3, 2,2,1,
                0,0,0, 0,0,0, 0,0,0), 5, 9, byrow=TRUE)
  siteCovs <- data.frame(x = c(0,2,-1,4,-1))
  obsCovs <- list(o1 = matrix(seq(-3, 3, length=length(y)), 5, 9))
  yrSiteCovs <- list(yr=matrix(c('1','2','2'), 5, 3, byrow=TRUE))


  expect_warning(umf <- unmarkedFrameGPC(y = y, siteCovs = siteCovs, obsCovs = obsCovs,
        yearlySiteCovs = yrSiteCovs, numPrimary=3))

  fm <- gpcount(~x, ~yr, ~o1, data = umf, K=23, control=list(maxit=1))
  fmR <- gpcount(~x, ~yr, ~o1, data = umf, K=23, engine="R", control=list(maxit=1))
  expect_equal(coef(fm), coef(fmR))
})

test_that("gpcount ZIP mixture works", {
  
  set.seed(123)
  M <- 100
  J <- 5
  T <- 3
  lam <- 3
  psi <- 0.3
  p <- 0.5
  phi <- 0.7

  y <- array(NA, c(M, J, T))

  N <- unmarked:::rzip(M, lambda=lam, psi=psi)

  for (i in 1:M){
    for (t in 1:T){
      n <- rbinom(1, N[i], phi)
      for (j in 1:J){
         y[i,j,t] <- rbinom(1, n, p)
      }
    }
  }

  ywide <- cbind(y[,,1], y[,,2], y[,,3])
  umf <- unmarkedFrameGPC(y=ywide, numPrimary=T)
  
  # check R and C engines match
  fitC <- gpcount(~1, ~1, ~1, umf, mixture="ZIP", K=10, engine="C",
                se=FALSE, control=list(maxit=1))
  fitR <- gpcount(~1, ~1, ~1, umf, mixture="ZIP", K=10, engine="R",
                se=FALSE, control=list(maxit=1))
  expect_equal(coef(fitC), coef(fitR))
  
  # Properly fit model
  fit <- gpcount(~1, ~1, ~1, umf, mixture="ZIP", K=10)
  expect_equivalent(coef(fit), c(1.02437, 0.85104, -0.019588, -1.16139), tol=1e-4)

  # Check methods
  ft <- fitted(fit)
  r <- ranef(fit)
  b <- bup(r)
  #plot(N, b)
  #abline(a=0, b=1)
  s <- simulate(fit)
})
