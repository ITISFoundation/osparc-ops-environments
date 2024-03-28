import re
import sys

assert len(sys.argv) == 2

with open(sys.argv[1], "r+") as original:
    lines = original.readlines()

linesWithoutCaptures = []
VALIDATION_REGEX = r"^(.*)=(\s*(.+)|(null))$"
for line in lines:
    if len(line) > 0 and len(line.lstrip()) > 0:
        if line.lstrip()[0] != "#":  # Ignore commented lines
            matchObj = re.search(VALIDATION_REGEX, line)
            if not matchObj:
                linesWithoutCaptures.append(line)
if len(linesWithoutCaptures) == 0:
    sys.exit(0)
else:
    print(
        "ALL LINES IN",
        sys.argv[1],
        "MUST CONTAIN VALUES OR NULL (match the regex",
        VALIDATION_REGEX,
        ").",
    )
    print("Found the following troubling lines in", sys.argv[1], ":")
    for i in linesWithoutCaptures:
        print(" -", i.rstrip())
    sys.exit(1)
