#!env python3
import argparse
import csv
import re

if __name__ == "__main__":
    PARSER = argparse.ArgumentParser(description="Converts a word into an FST")
    PARSER.add_argument("word", help="a word")
    args = PARSER.parse_args()
    input = args.word

    # read syms.txt file 
    with open('./syms.txt', 'r') as f:
        syms = f.readlines()
    
    # get first word of each line using re
    syms = [re.findall(r'^\S+', x)[0] for x in syms]
    
    # sort syms by length to ensure longest match
    syms.sort(key=len, reverse=True)

    # tokenize input using syms
    tokens = []
    while input != "":
        for s in syms:
            # check if input starts with s
            if str(input).startswith(s):
                # remove s from input and add to tokens
                tokens += [s]
                input = input[len(s):]
                break
        
        # throw error if no match found
        if input != "" and s == syms[-1]:
            print("ERROR: no match found for %s" % input)
            exit(1)
    
    # create FST
    for i, c in enumerate(tokens):
        print("%d %d %s %s" % (i, i + 1, c, c))
    print(i + 1)
