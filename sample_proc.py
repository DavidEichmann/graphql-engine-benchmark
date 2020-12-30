#!/usr/bin/env python
# -*- coding: utf-8 -*-

from pathlib import Path
import sys
import time
from typing import List, Optional

def read_proc(pid: int) -> dict:
    f = Path('/proc') / str(pid) / 'status'
    result = {}
    for line in open(f).readlines():
        k,v = line.split(':')
        result[k.strip()] = v.strip()

    return result


def plot_it(results: "numpy.ndarray",
            out_file: Optional[Path],
            labels: List[str]):
    import matplotlib
    if out_file is not None:
        matplotlib.use('Agg')

    from matplotlib import pyplot as pl
    import numpy as np
    cols = results.shape[1]
    for col, label in zip(range(1, cols), labels):
        pl.subplot(cols-1,1,col)
        pl.plot(results[:,0], results[:,col])
        pl.ylabel(label)

    pl.xlabel('time (seconds)')
    pl.legend()
    if out_file:
        pl.savefig(out_file)
    else:
        pl.show()

def main():
    import argparse
    parser = argparse.ArgumentParser()
    parser.add_argument('-p', '--pid', type=int, help='process id')
    parser.add_argument('-m', '--metric', action='append', type=str, help='metric names')
    parser.add_argument('-s', '--period', type=float, help='sampling period (seconds)', default=0.1)
    parser.add_argument('-o', '--output', type=argparse.FileType('w'), help='output file', default=sys.stdout)
    parser.add_argument('-P', '--plot', nargs='?', help='plot it', default=False, const=True)
    args = parser.parse_args()

    metrics = args.metric
    period = args.period
    pid = args.pid
    output = args.output

    if args.plot and output == sys.stdout:
        print("Must output to file in order to plot", file=sys.stderr)
        sys.exit(1)

    try:
        while True:
            t = time.time()
            result = read_proc(args.pid)
            values = [result[metric].split()[0] for metric in metrics]
            output.write('\t'.join([str(t)] + values) + '\n')
            output.flush()
            time.sleep(period)
    except Exception as e:
        print(f"Failed with {e}", file=sys.stderr)

    if args.plot is not False:
        if args.plot is True:
            out_file = None
        else:
            out_file = args.plot

        import numpy as np
        results = np.genfromtxt(args.output.name)
        plot_it(results, out_file, labels=metrics)

if __name__ == '__main__':
    main()
