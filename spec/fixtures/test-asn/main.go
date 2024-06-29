// asn-writer is an example of how to create an ASN MaxMind DB file from the
// GeoLite2 ASN CSVs. You must have the CSVs in the current working directory.
package main

import (
	"encoding/csv"
	"io"
	"log"
	"net"
	"os"
	"strconv"

	"github.com/maxmind/mmdbwriter"
	"github.com/maxmind/mmdbwriter/mmdbtype"
)

func main() {
	writer, err := mmdbwriter.New(
		mmdbwriter.Options{
			DatabaseType: "GeoLite2-ASN",
			RecordSize:   24,
		},
	)
	if err != nil {
		log.Fatal(err)
	}

	for _, file := range []string{"GeoLite2-ASN-Blocks-IPv4.csv", "GeoLite2-ASN-Blocks-IPv6.csv"} {
		fh, err := os.Open(file)
		if err != nil {
			log.Fatal(err)
		}

		r := csv.NewReader(fh)

		// first line
		r.Read()

		for {
			row, err := r.Read()
			if err == io.EOF {
				break
			}
			if err != nil {
				log.Fatal(err)
			}

			if len(row) != 3 {
				log.Fatalf("unexpected CSV rows: %v", row)
			}

			_, network, err := net.ParseCIDR(row[0])
			if err != nil {
				log.Fatal(err)
			}

			asn, err := strconv.Atoi(row[1])
			if err != nil {
				log.Fatal(err)
			}

			record := mmdbtype.Map{}

			if asn != 0 {
				record["autonomous_system_number"] = mmdbtype.Uint32(asn)
			}

			if row[2] != "" {
				record["autonomous_system_organization"] = mmdbtype.String(row[2])
			}

			err = writer.Insert(network, record)
			if err != nil {
				log.Fatal(err)
			}
		}
	}

	fh, err := os.Create("test-asn.mmdb")
	if err != nil {
		log.Fatal(err)
	}

	_, err = writer.WriteTo(fh)
	if err != nil {
		log.Fatal(err)
	}
}
