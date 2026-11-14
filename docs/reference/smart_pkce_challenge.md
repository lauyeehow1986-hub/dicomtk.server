# Generate an RFC 7636 S256 PKCE Verifier and Challenge Pair

Generate an RFC 7636 S256 PKCE Verifier and Challenge Pair

## Usage

``` r
smart_pkce_challenge(verifier = NULL)
```

## Arguments

- verifier:

  Optional PKCE `code_verifier` (43-128 URL-safe characters). If `NULL`,
  a high-entropy 64-character verifier is generated.

## Value

A list with `code_verifier`, `code_challenge`, and
`code_challenge_method = "S256"`.

## Examples

``` r
pkce <- smart_pkce_challenge()
pkce$code_challenge_method
#> [1] "S256"
```
