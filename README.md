# Mina Foundation Helm Charts

This repository contains Helm charts used by Mina Foundation.

## Chart List

The following is a list of charts available in this repository:

- `block-producer-uptime-monitoring`: Monitoring tool for Uptime Service Backend application
- `delegation-program-leaderboard`: Leaderboard application from the Delegation Program stack
- `delegation-program-payouts`: Payout application from the Delegation Program stack
- `delegation-verify-coordinator`: Coordinator application from the Delegation Program stack
- `gpt-survey-summarizer`: Discord bot for managing governance surveys
- `leaderboard`: Generic Leaderboard application
- `mina-archive`: Mina Archive node component
- `mina-daemon`: Mina Daemon component
- `mina-light-explorer`: Mina Light Explorer project
- `minametrix`: Application to track repositories that use o1js
- `mina-payouts-data-provider`:
- `mina-rosetta`:
- `mina-staking-ledgers-exporter`:
- `mina-transaction-generator`:
- `node-stats-collector`: Backend to collect stats from nodes
- `on-chain-voting`:
- `pod-rotation-controller`:
- `uptime-service-backend`: Uptime Service Backend to monitor node uptimes
- `uptime-service-payloads-scrapper`: Application that saves payload to filesystem

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
