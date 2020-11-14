import argparse
import json
from SurvivalAnalysis.Grid_Search import GridSearch


def main():
    # Create argument to read in Grid Search Parameters from JSON
    parser = argparse.ArgumentParser(description="Provide Parameter Grid for Search")
    parser.add_argument("-config",
                        help="Config file w/ library and Path to parameter dictionary")
    args = parser.parse_args()

    # Read config file for library and param path
    with open(args.config, "r") as config_file:
        config = json.load(config_file)


if __name__ == '__main__':
    main()