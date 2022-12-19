import copy

# Possible improvements / features:
# -- Read env vars from console and substitute those as well.
# -- Read env vars from .env file in folder and substitute those as well.
import re

import typer

typerApp = typer.Typer()


@typerApp.command()
def main(
    sourceenv: str,
    targetenv: str,
    substitute: bool = typer.Option(False, help="Substitute Env Vars"),
    highlight: bool = typer.Option(False, help="Highlight Modifications"),
):
    """
    This script puts the env-vars from one .env file (source) into a second one (target),
    substituting the ones previously present in the target file.
    Values present in the source file and not in the target file will be omitted.
    Output is printed to stdout.
    If "highlight" is true, then changed lines are highlighted.
    If "substitute" is true, references to env-vars are subsituted recursively.
    """
    sourceLinesDict = {}
    with open(sourceenv, "r+") as sourceF:
        sourceLines = sourceF.readlines()
        for i, item in enumerate(sourceLines):
            if len(item) > 0 and len(item.strip()) > 0:
                if item.strip()[0] != "#":
                    key = item.split("=")[0].strip()
                    val = item.split("=")[1].strip()
                    sourceLinesDict[key] = val
                    # print(key,"-",val)
    #
    targetLinesDict = {}
    with open(targetenv, "r+") as targetF:
        targetLines = targetF.readlines()
        for i, item in enumerate(targetLines):
            if len(item) > 0 and len(item.strip()) > 0:
                if item.strip()[0] != "#":
                    key = item.split("=")[0].strip()
                    val = item.split("=")[1].strip()
                    targetLinesDict[key] = val
    stringsListOutput = []
    for key in targetLinesDict:
        if key in sourceLinesDict:
            targetString = str(key) + "=" + str(sourceLinesDict[key])
            # Optional debug variable:
            # saveOriginalTargetString = copy.deepcopy(targetString)
            while substitute and "${" in targetString:
                searchKey = targetString.split("${")[1].split("}")[0]
                # Handle stuff like this: ${DOCKER_REGISTRY:-itisfoundation}
                if re.search(r"\$\{.*[:].*\}", searchKey):
                    searchKey = searchKey.split(":")[0]
                    if searchKey in sourceLinesDict:
                        targetString = (
                            targetString.split("${")[0]
                            + sourceLinesDict[searchKey]
                            + targetString.split(searchKey + ":")[1].replace("}", "", 1)
                        )
                if searchKey in sourceLinesDict:
                    targetString = (
                        targetString.split("${")[0]
                        + sourceLinesDict[searchKey]
                        + "}".join(targetString.split("}")[1:])
                    )
        else:
            targetString = str(key) + "=" + str(targetLinesDict[key])
        stringsListOutput.append(copy.deepcopy(targetString))
        if (
            highlight
            and key in sourceLinesDict
            and sourceLinesDict[key] != targetLinesDict[key]
        ):
            print(targetString + "  ### modified ###")
        else:
            print(targetString)


if __name__ == "__main__":
    typer.run(main)
