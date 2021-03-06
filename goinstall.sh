#!/bin/bash
set -e

print_help() {
    echo "Usage: bash goinstall.sh OPTIONS"
    echo -e "\nOPTIONS:"
    echo -e "  --32\t\tInstall 32-bit version"
    echo -e "  --64\t\tInstall 64-bit version"
    echo -e "  --arm\t\tInstall armv6 version"
    echo -e "  --darwin\tInstall darwin version"
    echo -e "  --force\tForce install"
    echo -e "  --remove\tTo remove currently installed version"
}

find_latest() {
    #Download Latest Go
    GOURLREGEX="https://dl.google.com/go/go[0-9\.]+\.$1-$2.tar.gz"
    echo "Finding latest stable version of Go for $1 $2..."
    url="$(wget -qO- https://golang.org/dl/ | grep -E \"\/dl\/go[0-9\.]+\.$1-$2\.tar\.gz\" | head -n 1 )"
    VERSION="$(echo $url | sed -E 's/.*go([0-9\.]+)\..*/\1/' )"
}

# Use the current shell to set paths
case "${SHELL##*/}" in
    "bash")
        shell_profile="bashrc";;
    "zsh")
        shell_profile="zshrc";;
    *|"")
        shell_profile="profile";;
esac

if [ "$1" == "--32" ]; then
    OS=linux
    PLATFORM=386
elif [ "$1" == "--64" ]; then
    OS=linux
    PLATFORM=amd64
elif [ "$1" == "--arm" ]; then
    OS=linux
    PLATFORM=arm6l
elif [ "$1" == "--darwin" ]; then
    OS=darwin
    PLATFORM=amd64
elif [ "$1" == "--remove" ]; then
    rm -rf "$HOME/.go/"
    sed -i '/# GoLang/d' "$HOME/.${shell_profile}"
    sed -i '/export GOROOT/d' "$HOME/.${shell_profile}"
    sed -i '/:$GOROOT/d' "$HOME/.${shell_profile}"
    sed -i '/export GOPATH/d' "$HOME/.${shell_profile}"
    sed -i '/:$GOPATH/d' "$HOME/.${shell_profile}"
    echo "Go removed."
    exit 0
elif [ "$1" == "--help" ]; then
    print_help
    exit 0
else
    print_help
    exit 1
fi

find_latest $OS $PLATFORM
DFILE="go$VERSION.$OS-$PLATFORM.tar.gz"

if [ -d "$HOME/.go" ]; then
    if [[ ! $@ =~ "--force" ]]; then
        echo "The '.go' directories already exist. Exiting."
        exit 1
    fi

    rm -rf "$HOME/.go"
fi

echo "Downloading $DFILE ..."
wget https://storage.googleapis.com/golang/$DFILE -O /tmp/go.tar.gz

if [ $? -ne 0 ]; then
    echo "Download failed! Exiting."
    exit 1
fi

echo "Extracting File..."
tar -C "/tmp" -xzf /tmp/go.tar.gz
mv "/tmp/go" "$HOME/.go"
touch "$HOME/.${shell_profile}"

grep -E 'export GOROOT=' "$HOME/.${shell_profile}" > /dev/null \
    && sed -E 's/^(export GOROOT=).*/\1$HOME\/.go/' "$HOME/.${shell_profile}" | tee -a "$HOME/.${shell_profile}" > /dev/null \
    || echo 'export GOROOT=$HOME/.go' >> "$HOME/.${shell_profile}"

grep -E 'export GOPATH=' "$HOME/.${shell_profile}" > /dev/null \
    && sed -E 's/^(export GOPATH=).*/\1$HOME\/go/' "$HOME/.${shell_profile}" | tee -a "$HOME/.${shell_profile}" > /dev/null \
    || echo 'export GOPATH=$HOME/go' >> "$HOME/.${shell_profile}"

grep -E 'export PATH=$PATH:$GOROOT/bin' "$HOME/.${shell_profile}" > /dev/null \
    || echo 'export PATH=$PATH:$GOROOT/bin' >> "$HOME/.${shell_profile}"

grep -E 'export PATH=$PATH:$GOPATH/bin' "$HOME/.${shell_profile}" > /dev/null \
    || echo 'export PATH=$PATH:$GOPATH/bin' >> "$HOME/.${shell_profile}"

mkdir -p $HOME/go/{src,pkg,bin}

source "$HOME/.${shell_profile}"
go version

echo -e "\nGo $VERSION was installed.\nMake sure to relogin into your other shells or run:"
echo -e "\n\tsource $HOME/.${shell_profile}\n\nto update your environment variables."
echo "Tip: Opening a new terminal window usually just works. :)"
rm -f /tmp/go.tar.gz
