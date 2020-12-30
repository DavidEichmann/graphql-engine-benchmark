#!/bin/bash

set -emx

ROOT=$(realpath "$(dirname "$0")")

CONN_PER_SEC=200

BENCH_SIZES="50 100 200 400 800 1600"

# Kill graphql-engine if running already
kill -s INT "$(pgrep graphql-engine)" || true

SAMPLE=$ROOT/sample_proc.py
ulimit -n 4000
BASEDIR=$ROOT/profile_output
BASENAME=$BASEDIR/$(date +%s).eventlog
cd $ROOT/graphql-engine/server
# HASURA_GRAPHQL_SERVER_PORT=8181 HASURA_GRAPHQL_DATABASE_URL=postgres://postgres:postgres@127.0.0.1:25432/postgres cabal new-exec --RTS -- exe:graphql-engine serve --enable-console --console-assets-dir /home/david/MEGA/File_Dump/Well-Typed/hasura/_nosync_git/graphql-engine/console/static/dist +RTS -N -T -s  -RTS \
cabal new-build --project-file=cabal.project.dev-sh exe:graphql-engine
mkdir -p $BASEDIR
HASURA_GRAPHQL_SERVER_PORT=8181 HASURA_GRAPHQL_DATABASE_URL=postgres://postgres:postgres@127.0.0.1:25432/postgres cabal new-exec --project-file=cabal.project.dev-sh --RTS graphql-engine -- serve --enable-console --console-assets-dir /home/david/Well-Typed/hasura/_nosync_git/graphql-engine/console/static/dist +RTS \
  -N -T -hT -i0.01 -s \
	-l $@ \
	-ol$BASENAME \
  -RTS &
echo "############# Server started ################"
sleep 4
PID=$(pgrep graphql-engine)
python3 $SAMPLE --plot -p $PID -mVmRSS -o ${BASENAME}.mem.tsv -s0.01 &
sleep 2
pushd $ROOT/graphql-bench/subscriptions/
sed -i "s/connections_per_second: .*/connections_per_second: $CONN_PER_SEC/g" src/config.yaml
for CONN in $BENCH_SIZES; do
  (( T = 8 + ($CONN / $CONN_PER_SEC) ))
  sed -i "s/max_connections: .*/max_connections: $CONN/g" src/config.yaml
  timeout -sINT $T npm run start || true
  sleep 5
done
popd
kill -s INT $PID || true
wait $PID || true
sleep 2
HTMLOUT=$BASENAME.html
eventlog2html --bands 35 -o "$HTMLOUT" "$BASENAME"
echo "Wrote: ${HTMLOUT}"
# firefox -new-tab ${HTMLOUT}
