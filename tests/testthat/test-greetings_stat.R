test_that("check input type", {
  # Input cases that should result in a error
  expect_error(greetings_stat(to = NULL))
  expect_error(greetings_stat(to = NA))
  expect_error(greetings_stat(to = NaN))
  expect_error(greetings_stat(to = 42))
  expect_error(greetings_stat(to = TRUE))
  expect_error(greetings_stat(to = Livio))
  expect_error(greetings_stat(to = starwars))
})

test_that("output is correct", {
  # This here is needed to catch the print statement
  capture_output({
    # Check if the examples result in the expected output
    expect_equal(greetings_stat(), "Welcome STAT!")
    expect_equal(greetings_stat(to = "Livio"), "Welcome Livio!")
    expect_equal(
      greetings_stat(to = starwars$name[1]),
      "Welcome Luke Skywalker!"
    )
  })
})
