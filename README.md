# Mina Foundation Helm Charts

This repository contains Helm charts used by Mina Foundation.

## Deploying a Local Chart

To deploy a chart from this repository, you can first download the chart files and then install the chart using the `helm install` command.

1. Download the chart files for the `leaderboard` chart from the Mina Foundation Git repository.
2. Extract the files from the downloaded archive to a local directory.
3. Install the chart using the `helm install` command and passing in the path to the chart directory. For example:

```
helm install leaderboard ./leaderboard
```

This command installs the `leaderboard` chart using the local files in the `leaderboard` directory. You can adjust the command to fit your environment and specific requirements.

## Contributing

### Prerequisite binaries

```
pre-commit >= 3.6.2
```

### README generation

Please follow the guidelines on how to comment the `values.yaml` files.

After cloning the repository make sure to run

```
pre-commit install
pre-commit install-hooks
```

Now before each commit the hooks will run. The hook is designed to fail when generating the README and pass if it matches `values.yaml`. Adding the generated README will make it pass.

If you have suggestions or feedback, please raise an issue or a pull request.
