# gliberapay

Work with Liberapay in Gleam!

[![Package Version](https://img.shields.io/hexpm/v/gliberapay)](https://hex.pm/packages/gliberapay)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/gliberapay/)

```sh
gleam add gliberapay
```
```gleam
import gliberapay
import httpc

pub fn main() {
  // Download a CSV of Liberapay patrons for a recipient
  let req = gliberapay.download_patrons_csv_request("gleam")
  let assert Ok(resp) = httpc.send(req)

  // Parse the CSV
  let assert Ok(patrons) = gliberapay.parse_patrons_csv(resp.body)
  patrons
}
```
This returns data like this:
```gleam
[
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
]
```
  

Further documentation can be found at <https://hexdocs.pm/gliberapay>.
