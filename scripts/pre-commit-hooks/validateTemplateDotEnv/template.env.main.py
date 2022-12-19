import re
import sys

assert len(sys.argv) == 2
original = open(sys.argv[1], "r+")
lines = original.readlines()
linesWithoutCaptures = []
validationRegex = "^(.*)=([\"'])?((\\$\\{[^:]*\\})|(null))([\"'])?$"
for line in lines:
    if len(line) > 0 and len(line.lstrip()) > 0:
        if line.lstrip()[0] != "#":  # Ignore commented lines
            matchObj = re.search(validationRegex, line)
            if not matchObj:
                linesWithoutCaptures.append(line)
if len(linesWithoutCaptures) == 0:
    exit(0)
else:
    print(
        "ALL LINES IN",
        sys.argv[1],
        "MUST CONTAIN PURE ASSIGNMENTS OR NULL (match the regex",
        validationRegex,
        ").",
    )
    print("Tip: Move all concatenations etc. to repo.config")
    print("Found the following troubling lines in", sys.argv[1], ":")
    for i in linesWithoutCaptures:
        print(" -", i.rstrip())
    exit(1)
