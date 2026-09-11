# Test to ensure that the 3rd edition of testthat is activated
test_that("I can use the 3rd edition", {
  local_edition(3)
  expect_true(TRUE)
})
