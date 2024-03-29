import gleam/http
import gleam/http/request
import gleam/option.{None, Some}
import gleam/string
import gleam/uri
import gleeunit
import gleeunit/should
import gliberapay.{Date, Patron}

pub fn main() {
  gleeunit.main()
}

pub fn csv_parsing_test() {
  "
pledge_date,patron_id,patron_username,patron_public_name,donation_currency,weekly_amount,patron_avatar_url
2024-03-12,1847734,erikareads,erikareads,USD,private,https://seccdn.libravatar.org/avatar/3beb6ba272afe47c05f19288b480cbcb?s=160&d=404
2024-03-15,1847917,~1847917,,CHF,4.80,https://seccdn.libravatar.org/avatar/0837ca2eb9199aa134c4b2fc9ce382a2?s=160&d=404
"
  |> string.trim
  |> gliberapay.parse_patrons_csv
  |> should.be_ok
  |> should.equal([
    Patron(
      pledge_date: Date(2024, 3, 12),
      patron_id: 1_847_734,
      patron_username: "erikareads",
      patron_public_name: Some("erikareads"),
      donation_currency: "USD",
      weekly_amount: None,
      patron_avatar_url: "https://seccdn.libravatar.org/avatar/3beb6ba272afe47c05f19288b480cbcb?s=160&d=404",
    ),
    Patron(
      pledge_date: Date(2024, 3, 15),
      patron_id: 1_847_917,
      patron_username: "~1847917",
      patron_public_name: None,
      donation_currency: "CHF",
      weekly_amount: Some(4.8),
      patron_avatar_url: "https://seccdn.libravatar.org/avatar/0837ca2eb9199aa134c4b2fc9ce382a2?s=160&d=404",
    ),
  ])
}

pub fn csv_parsing_not_a_csv_test() {
  ","
  |> gliberapay.parse_patrons_csv
  |> should.be_error
  |> should.equal(gliberapay.InvalidCsvSyntax(
    "[line 1 column 1] of csv: Unexpected start to csv content: ,",
  ))
}

pub fn csv_parsing_wrong_headers_test() {
  "one,two"
  |> gliberapay.parse_patrons_csv
  |> should.be_error
  |> should.equal(
    gliberapay.MissingCsvHeaders([
      "pledge_date", "patron_id", "patron_username", "patron_public_name",
      "donation_currency", "weekly_amount", "patron_avatar_url",
    ]),
  )
}

pub fn csv_parsing_some_missing_headers_test() {
  "
pledge_date,patron_id,patron_username,patron_public_name,donation_currency
2024-03-12,1847734,erikareads,erikareads,USD
2024-03-15,1847917,~1847917,,CHF
"
  |> string.trim
  |> gliberapay.parse_patrons_csv
  |> should.be_error
  |> should.equal(
    gliberapay.MissingCsvHeaders(["weekly_amount", "patron_avatar_url"]),
  )
}

pub fn csv_parsing_invalid_date_test() {
  "
pledge_date,patron_id,patron_username,patron_public_name,donation_currency,weekly_amount,patron_avatar_url
2024-,1847734,erikareads,erikareads,USD,private,https://seccdn.libravatar.org/avatar/3beb6ba272afe47c05f19288b480cbcb?s=160&d=404
2024-03-15,1847917,~1847917,,CHF,4.80,https://seccdn.libravatar.org/avatar/0837ca2eb9199aa134c4b2fc9ce382a2?s=160&d=404
"
  |> string.trim
  |> gliberapay.parse_patrons_csv
  |> should.be_error
  |> should.equal(gliberapay.InvalidValue("invalid date: 2024-"))
}

pub fn download_patron_csv_test() {
  let request = gliberapay.download_patron_csv("gleam")

  request.method
  |> should.equal(http.Get)

  request
  |> request.to_uri
  |> uri.to_string
  |> should.equal("https://liberapay.com/gleam/patrons/public.csv")
}
