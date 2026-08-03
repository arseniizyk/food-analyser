//nolint:all // no need to lint healthcheck
package main

import (
	"fmt"
	"net"
	"net/http"
	"os"
)

func main() {
	port := os.Getenv("HTTP_PORT")

	url := "http://" + net.JoinHostPort("localhost", port) + "/api/v1/health"

	resp, err := http.Get(url)
	if err != nil {
		os.Exit(1)
	}
	defer func() {
		_ = resp.Body.Close()
	}()

	if resp.StatusCode != http.StatusOK {
		os.Exit(1)
	}

	fmt.Println("healthcheck OK")
}
