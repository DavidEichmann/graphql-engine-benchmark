{ pkgs ? import (fetchTarball "https://github.com/NixOS/nixpkgs/archive/520d00dd7d32094d3a0a7958591c3bf67f61d73f.tar.gz") {} }:

pkgs.mkShell {
  # See https://github.com/NixOS/nixpkgs/issues/3382#issuecomment-490475790 and https://github.com/NixOS/nixpkgs/issues/3382#issuecomment-513596055
  GIT_SSL_CAINFO = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
  LOCALE_ARCHIVE = "${pkgs.glibc}/lib/locale/locale-archive";
  LC_ALL   = "en_US.UTF-8";
  LANG     = "en_US.UTF-8";
  LANGUAGE = "en_US.UTF-8";
  buildInputs = with pkgs; [
    # Sys tools
    which
    shellcheck
    htop
    direnv
    figlet
    procps
    docker
    git
    cacert # see https://github.com/NixOS/nixpkgs/issues/3382#issuecomment-513596055

    # Nix
    nix

    # Haskell
    haskell.compiler.ghc8102
    cabal-install
    # haskell.packages.ghc8102.eventlog2html # broken

    # Node
    nodejs-12_x

    # Postgresql
    postgresql
    postgis

    python3
    python3Packages.pip
    python3Packages.tornado
    python3Packages.numpy
    python3Packages.tkinter
    pkgs.python3Packages.matplotlib

    google-cloud-sdk

    # Debugging tools
    gdbgui
    heaptrack
    valgrind
    massif-visualizer


    # Build libraries
    glibc
    glibcLocales
    openssl
    libpqxx
    zlib
    # numactl
  ];
}