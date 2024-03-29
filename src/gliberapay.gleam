import gleam/dict
import gleam/float
import gleam/http
import gleam/http/request.{type Request}
import gleam/http/response.{type Response}
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/set
import gleam/string
import gsv

const patron_csv_headers = [
  "pledge_date", "patron_id", "patron_username", "patron_public_name",
  "donation_currency", "weekly_amount", "patron_avatar_url",
]

pub type Patron {
  Patron(
    pledge_date: Date,
    patron_id: Int,
    patron_username: String,
    /// The name the patron has chosen to display publicly.
    ///
    /// If the patron has not set a public name then this will be `None` and you
    /// may want to use `patron_username` instead.
    ///
    patron_public_name: Option(String),
    donation_currency: String,
    /// The amount the patron has pledged to donate per week.
    ///
    /// If the patron has set their amount to be private then this will be `None`.
    ///
    weekly_amount: Option(Float),
    patron_avatar_url: String,
  )
}

pub type Error {
  InvalidCsvSyntax(String)
  MissingCsvHeaderRow
  MissingCsvHeaders(missing: List(String))
  InvalidValue(detail: String)
}

pub type Date {
  Date(year: Int, month: Int, day: Int)
}

/// Construct a HTTP request to download the public Liberapay patrons CSV for
/// the given recipient.
///
/// Once you have a response for the request you can parse the body with the
/// `parse_patrons_csv` function.
///
pub fn download_patron_csv(recipient recipient: String) -> Request(String) {
  request.new()
  |> request.set_host("liberapay.com")
  |> request.set_path("/" <> recipient <> "/patrons/public.csv")
}

/// Parse a Liberapay patrons CSV, as can be downloaded from the Liberapay, e.g.
/// <https://liberapay.com/gleam/patrons/public.csv>
///
/// If you want to download this in Gleam see the `download_patron_csv` function.
///
pub fn parse_patrons_csv(csv: String) -> Result(List(Patron), Error) {
  csv
  |> gsv.to_lists_or_error
  |> result.map_error(InvalidCsvSyntax)
  |> result.try(extract_csv_patrons)
}

fn extract_csv_patrons(csv: List(List(String))) -> Result(List(Patron), Error) {
  use #(headers, rows) <- result.try(pop_headers(csv))
  let rows =
    list.map(rows, fn(row) {
      list.zip(headers, row)
      |> dict.from_list
    })

  use row <- list.try_map(rows)
  let get = fn(k) {
    case dict.get(row, k) {
      Ok(v) -> Ok(v)
      _ -> Error(InvalidValue("missing value for " <> k))
    }
  }
  use date <- result.try(get("pledge_date"))
  use id <- result.try(get("patron_id"))
  use username <- result.try(get("patron_username"))
  use name <- result.try(get("patron_public_name"))
  use currency <- result.try(get("donation_currency"))
  use amount <- result.try(get("weekly_amount"))
  use avatar <- result.try(get("patron_avatar_url"))
  use date <- result.try(parse_date(date))
  use id <- result.try(parse_int(id))
  use amount <- result.try(parse_amount(amount))

  Ok(Patron(
    pledge_date: date,
    patron_id: id,
    patron_username: username,
    patron_public_name: optional_string(name),
    donation_currency: currency,
    weekly_amount: amount,
    patron_avatar_url: avatar,
  ))
}

fn optional_string(s: String) -> Option(String) {
  case s {
    "" -> None
    _ -> Some(s)
  }
}

fn parse_int(int: String) -> Result(Int, Error) {
  case int.parse(int) {
    Ok(i) -> Ok(i)
    _ -> Error(InvalidValue("invalid int: " <> int))
  }
}

fn parse_amount(amount: String) -> Result(Option(Float), Error) {
  case amount {
    "" | "private" -> Ok(None)
    _ ->
      case float.parse(amount) {
        Ok(f) -> Ok(Some(f))
        _ -> Error(InvalidValue("invalid float: " <> amount))
      }
  }
}

fn parse_date(date: String) -> Result(Date, Error) {
  use numbers <- result.try(
    string.split(date, "-")
    |> list.try_map(int.parse)
    |> result.map_error(fn(_) { InvalidValue("invalid date: " <> date) }),
  )
  case numbers {
    [year, month, day] -> Ok(Date(year, month, day))
    _ -> Error(InvalidValue("invalid date: " <> date))
  }
}

fn pop_headers(
  csv: List(List(String)),
) -> Result(#(List(String), List(List(String))), Error) {
  use #(headers, rest) <- result.try(case csv {
    [first, ..rest] -> Ok(#(first, rest))
    [] -> Error(MissingCsvHeaderRow)
  })

  let headers_set = set.from_list(headers)
  let missing =
    list.filter(patron_csv_headers, fn(h) { !set.contains(headers_set, h) })

  case missing {
    [] -> Ok(#(headers, rest))
    _ -> Error(MissingCsvHeaders(missing))
  }
}
