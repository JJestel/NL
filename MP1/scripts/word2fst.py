#!env python3
import argparse
import csv
import re

if __name__ == "__main__":
    PARSER = argparse.ArgumentParser(description="Converts a word into an FST")
    PARSER.add_argument("word", help="a word")
    PARSER.add_argument("--separator", help="separator for split", default=None)
    args = PARSER.parse_args()

    if args.separator is None or args.separator == "":
        l = args.word
    else:
        l = args.word.split(args.separator)

    for i, c in enumerate(l):
        print("%d %d %s %s" % (i, i + 1, c, c))
    print(i + 1)
