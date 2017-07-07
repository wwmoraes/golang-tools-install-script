#!/bin/bash
set -e

../goinstall.sh --64

source ~/.bashrc

mkdir -p $GOPATH/src/hello
pushd $GOPATH/src/hello
cat >hello.go <<EOF
package main

import "fmt"

func main() {
    fmt.Printf("hello, world\n")
}
EOF
go build
hello
popd
