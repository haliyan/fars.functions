
test_that("make_filename returns a correctly formatted character string",{
 expect_type(make_filename("2014"), type = "character")
  expect_match(make_filename("2014"),
               "^(accident_).+(csv.bz2)$")
  expect_equal(nchar(make_filename("2014")), 21)
})

test_that("make_filename issues warning if it can't make a filename",{
  expect_warning(make_filename("twenty-fourteen"),
               "NAs introduced by coercion")
  expect_warning(make_filename("@#$!_"),
               "NAs introduced by coercion")
})

test_that("fars_read returns the correct tibble", {
  expect_equal(nrow(fars_read("accident_2013.csv.bz2")), 30202)
  expect_equal(ncol(fars_read("accident_2013.csv.bz2")), 50)
})

test_that("fars_read throws error if file doesn't exist",{
  expect_error(fars_read("nonexistent_file"),
               "file 'nonexistent_file' does not exist")
})

test_that("fars_read_years returns the correct list", {
  expect_type(fars_read_years(c("2013","2014")),
              type = "list")
  expect_equal(length(fars_read_years(c("2013","2015"))), 2)
  expect_equal(length(fars_read_years(c("2013","2014","2015"))), 3)
})

test_that("fars_read_years issues warnings if it can't find files", {
  expect_warning(fars_read_years(c("2015","2025")),
                 "invalid year: 2025")
  expect_warning(fars_read_years(list("2014","1776")),
                 "invalid year: 1776")
})

test_that("fars_summarize_years returns the correct list",{
  expect_type(fars_summarize_years(c("2014","2015")),
              type = "list")
  expect_equal(nrow(fars_summarize_years(c("2014","2015"))), 12)
  expect_equal(ncol(fars_summarize_years(c("2014","2015"))), 3)
  expect_equal(ncol(fars_summarize_years(c("2013","2014","2015"))), 4)
})

test_that("fars_summarize_years issues warning if it can't find files",{
  expect_warning(fars_summarize_years(c("2013","1800")),
                 "invalid year: 1800")
  expect_warning(fars_summarize_years(list("2040","2014")),
                 "invalid year: 2040")
})

test_that("fars_map_state correctly maps a state's accident data",{
  expect_null(fars_map_state(1,2015))
})

test_that("fars_map_state throws error if arguments not supplied",{
  expect_error(fars_map_state(1,2033),
               "file 'accident_2033.csv.bz2' does not exist")
  expect_error(fars_map_state(1),
               'argument "year" is missing, with no default')
})

test_that("fars_map_state throws errors for states that can't be mapped",{
  expect_error(fars_map_state(100,2015),
               "invalid STATE number: 100")
  expect_error(fars_map_state(3, 2013),
               "invalid STATE number: 3")
  expect_error(fars_map_state(2,2015),
               "nothing to draw: all regions out of bounds")
})
