# README

This repo attempts to make the subscriptions benchmark easily reproducible.

* Make sure you have `eventlog2html` installed
  * I haven't managed to add this to the `shell.nix` as the current pin of
    nixkgs contains a broken `eventlog2html`.

* Use shell.nix for all the following commands

    ```bash
    # From root dir
    nix-shell
    ```

To run:

* Start the database in a separate terminal

    ```bash
    # From root dir
    cd graphql-engine
    ./scripts/dev.sh postgres
    ```

* That starts a docker image. If you've run this before and want to start with a
  clean DB / docker image, then remove the docker image before running the above
  script:

  ```bash
  docker image ls
  # Find the <IMAGE ID> of circleci/postgres
  docker image rm <IMAGE ID>
  ```

* build the console assets

    ```bash
    # From root dir
    cd graphql-engine/console/
    npm ci && make server-build
    ```

* build the benchmark

    ```bash
    # From root dir
    cd graphql-bench/subscriptions/
    npm i
    ```

* build the server

    ```bash
    # From root dir
    cd graphql-engine/server
    cabal new-build
    ```

* Setup the db

    ```bash
    # From root dir
    psql postgres://postgres:postgres@127.0.0.1:25432/postgres -f chinook_pg_serial_pk_proper_naming.sql
    # Start to server so we can track all
    cd graphql-engine/server
    HASURA_GRAPHQL_SERVER_PORT=8181 HASURA_GRAPHQL_DATABASE_URL=postgres://postgres:postgres@127.0.0.1:25432/postgres cabal new-exec --RTS graphql-engine -- +RTS -N -RTS serve --enable-console --console-assets-dir ../console/static/dist
    ```

* Visit http://127.0.0.1:8181/console/data/schema/public and click "track all" everywhere
* You can now stop the graphql server with Ctl+C (but do keep the postgresql
  server running for the benchmark to work).

* Pick a list of subscription counts by setting `BENCH_SIZES` in
  `run.sh`. The benchmark will iterate over these sizes and run
  the subscriptions benchmark with that size.

* Run the benchmark

    ```bash
    # From root dir
    ./run.sh
    ```


## Benchmark Memory characteristics

The `run.sh` script runs multiple iterations of the subscription benchmark. You
should expect the the heap residency reported by the RTS to increase during the
benchmark (subscriptions are created), then to reset to a baseline between
benchmark iterations (subscriptions are closed). At the same time, memory usage
(e.g. VmRSS) reported by the OS will show memory strictly increasing i.e. *not*
returning to a base line. The disrepancy between heap residency reported by the
RTS and VmRSS reported by the OS is the original issue that Hasura tasked
Well-Typed with investigating. David Eichmann's original characterization of
this was that it is due to fragmentation of the heap. Using the compacting GC
(RTS option `-c`) has little effect implying that the fragmentation is largely
due to *pinned data*. See
https://www.well-typed.com/blog/2020/08/memory-fragmentation/ for an indepth
look at fragmentation.
