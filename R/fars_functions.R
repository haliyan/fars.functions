#' Read in FARS File
#'
#' This is a function which checks whether a FARS file with a certain
#' file name exists.
#' An error will be thrown if a file by the user-supplied file name does
#' not exist.
#' If said file does exist, it will be read into R and transformed into
#' a tibble.
#'
#' @param filename A character string giving the name of the FARS file.
#'
#' @return This function returns a tibble of the data contained in the
#'    file named \code{filename} and prints the first 10 rows of the
#'    tibble.
#'
#' @examples
#' \dontrun{fars_read("accident_2014.csv.bz2")}
#' \dontrun{fars_read("accident_2013.csv.bz2")}
#'
#' @importFrom tibble as.tibble
#' @importFrom readr read_csv
#'
#' @export
fars_read <- function(filename) {
  filepath<-system.file("extdata",filename,package="fars.functions")
  if(!file.exists(filepath))
    stop("file '", filename, "' does not exist")
  data <- suppressMessages({
    readr::read_csv(filepath,progress = FALSE)
  })
  tibble::as_tibble(data)
}

#' File Naming Function
#'
#' This function makes a FARS file name for a given year. It converts the
#' string supplied by the user to an integer, then generates a file name
#' for that year with the correct format.
#' An error will be thrown if the supplied string cannot be coerced to
#' an integer without introducing NA's.
#'
#' @param year A character string giving the year for which a file name
#'    should be generated.
#'
#' @return A character string giving a file name formatted
#'    \code{accident_X.csv.bz2} where X is the string supplied to
#'    \code{year}.
#'
#' @examples
#' \dontrun{make_filename("2010")}
#' \dontrun{make_filename("2021")}
#'
#' @export
make_filename <- function(year) {
  year <- as.integer(year)
  sprintf("accident_%d.csv.bz2", year)
}

#' Read in files by year
#'
#' This function takes a list of years and creates file names for each of
#' them using the \code{make_filename} function.
#' It then reads in these files using the \code{fars_read} function and
#' creates a list of tibbles which contain the months in each of the
#' years.
#' If the file name created from a year inputted does not correspond
#' to an existing file containing data for said year, an error is thrown.
#'
#' @param years A list or vector of years.
#'
#' @return A list of tibbles, each with two columns: one containing the
#'    months, and the other containing the year.
#'    The number of rows for each month represents the number of
#'    accidents in the month.
#'    This list is also printed.
#'
#' @examples
#' \dontrun{fars_read_years(c(2014,2015))}
#' \dontrun{fars_read_years(c(2013,2014))}
#'
#' @importFrom magrittr %>%
#' @importFrom dplyr mutate
#' @importFrom dplyr select
#'
#' @export
fars_read_years <- function(years) {
  lapply(years, function(year) {
    file <- make_filename(year)
    tryCatch({
      dat <- fars_read(file)
      dplyr::mutate(dat, year = year) %>%
        dplyr::select(MONTH, year)
    }, error = function(e) {
      warning("invalid year: ", year)
      return(NULL)
    })
  })
}

#' Summarize yearly FARS data
#'
#' This function passes a list of years to the \code{fars_read_years}
#' function. It then counts the number of rows for each month in the
#' data frame returned by \code{fars_read_years} to obtain the number of
#' accidents that occurred in each month for the years supplied to the
#' \code{years} argument.
#' It then returns a tibble containing this information.
#'
#' @param years A list or vector of years.
#'
#' @return A tibble containing the number of accidents in each month
#'    for each of the years specified in the list of years supplied to
#'    the \code{years} argument.
#'
#' @examples
#' \dontrun{fars_summarize_years(c(2013,2014,2015))}
#' \dontrun{fars_summarize_years(c(2013,2014))}
#'
#' @importFrom magrittr %>%
#' @importFrom dplyr bind_rows
#' @importFrom dplyr group_by
#' @importFrom dplyr summarize
#' @importFrom dplyr n
#' @importFrom tidyr spread
#'
#' @export
fars_summarize_years <- function(years) {
  dat_list <- fars_read_years(years)
  dplyr::bind_rows(dat_list) %>%
    dplyr::group_by(year, MONTH) %>%
    dplyr::summarize(n = dplyr::n()) %>%
    tidyr::spread(year, n)
}

#' Map FARS data by State
#'
#' This function creates a map of accidents for a state, specified by its
#' state number.
#' If there are no accidents to plot for that state, a message saying so
#' will be printed.
#' If a state does not exist which corresponds to the number inputted,
#' an error will be thrown.
#' An error will also be thrown if the state is out of bounds for
#' plotting. This happens for the states of Alaska and Hawaii which are
#' not part of the contiguous United States.
#'
#' @param state.num A numeric object or character string representing
#'    the number of the state for which accidents should be mapped.
#' @param year A numeric object or character string representing the year
#'    for which the state's accidents should be mapped.
#'
#' @return Null. Displays a state map with accident locations plotted on
#'    it by their longitude and latitude in the file browser tab. Nothing
#'    is displayed if no accidents to show.
#'
#' @examples
#' \dontrun{fars_map_state(48,2015)}
#' \dontrun{fars_map_state("13","2014")}
#'
#' @importFrom dplyr filter
#' @importFrom maps map
#' @importFrom graphics points
#'
#' @export
fars_map_state <- function(state.num, year) {
  filename <- make_filename(year)
  data <- fars_read(filename)
  state.num <- as.integer(state.num)

  if(!(state.num %in% unique(data$STATE)))
    stop("invalid STATE number: ", state.num)
  data.sub <- dplyr::filter(data, STATE == state.num)
  if(nrow(data.sub) == 0L) {
    message("no accidents to plot")
    return(invisible(NULL))
  }
  is.na(data.sub$LONGITUD) <- data.sub$LONGITUD > 900
  is.na(data.sub$LATITUDE) <- data.sub$LATITUDE > 90
  with(data.sub, {
    maps::map("state", ylim = range(LATITUDE, na.rm = TRUE),
              xlim = range(LONGITUD, na.rm = TRUE))
    graphics::points(LONGITUD, LATITUDE, pch = 46)
  })
}
