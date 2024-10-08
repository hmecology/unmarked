context("fitLists")

skip_on_cran()

y <- matrix(rep(0:1,10)[1:10],5,2)
siteCovs <- data.frame(x = c(0,2,3,4,1))
obsCovs <- data.frame(o1 = 1:10, o2 = exp(-5:4)/10)
umf <- unmarkedFrameOccu(y = y, siteCovs = siteCovs, obsCovs = obsCovs)
fm <- occu(~ o1 + o2 ~ x, data = umf)
fm2 <- occu(~1~x, data=umf)

test_that("fitList operations work",{

  fl <- fitList(fm=fm, fm2=fm2)
  expect_is(fl, "unmarkedFitList")

  out <- capture.output(expect_warning(summary(fl)))
  expect_equal(out[c(2,20)], rep("Call:", 2))

  cf <- coef(fl)
  expect_equal(dim(cf), c(2,5))
  expect_equivalent(cf[,1], c(8.590737, 10.887214), tol=1e-4)
  expect_true(all(is.na(cf[2,4:5])))

  se <- SE(fl)
  expect_equal(dim(se), c(2,5))
  expect_true(all(is.na(se[2,4:5])))
  expect_equivalent(se[1,1], SE(fm)[1])

  pr <- predict(fl, type='state')
  expect_is(pr, "data.frame")
  expect_equal(dim(pr), c(5,4))

  # Raster predict
  r <- data.frame(x=rep(1:10, 10), y=rep(1:10, each=10), z=rnorm(100))
  if(requireNamespace("raster")){
    r <- raster::rasterFromXYZ(r)
    names(r) <- "x"
    pr <- predict(fl, type="state", newdata=r)
    expect_is(pr, "RasterStack")
  }

  mt <- modSel(fl)
  out <- capture.output(mt)
  expect_equal(out[1], "    nPars   AIC delta AICwt cumltvWt")

  se <- SE(mt)
  expect_equal(dim(se), c(2,5))
  
  fl <- expect_message(fitList(fm, fm2, autoNames='formula'))
  expect_equal(names(fl@fits), c("~o1+o2~x", "~1~x"))
  fl <- expect_message(fitList(fits=list(fm, fm2), autoNames='formula'))
  expect_equal(names(fl@fits), c("~o1+o2~x", "~1~x"))
})
