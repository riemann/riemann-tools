# test-asn

This is a copy of the asn-writer example from [MaxMind's `mmdbwriter` repository](https://github.com/maxmind/mmdbwriter), with some tooling to build the `test-asn.mmdb` file from the `GeoLite2-ASN-Blocks-IPv4.csv` and `GeoLite2-ASN-Blocks-IPv6.csv` files.

## Usage

Adjsut the `.cvs` files, then (re)generate `test-asn.mmdb` with:

```sh
go get
go build
./test-asn
```

## Note

The `mmdbwriter` code does not allow to use private neworks nor networks reserved for documentation.
The test ASN database therefore contains (obviously incorrect) information about *real* networks.
It goes without saying, but I will still say it: do not use this database for anything else than testing the riemann-tools.
