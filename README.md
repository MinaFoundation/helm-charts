# Mina Foundation Helm Charts

This repository contains Helm charts used by Mina Foundation.

## Chart List

The following is a list of charts available in this repository:

- `block-producer-uptime`: This chart deploys the Mina Foundation Block Producer Uptime application.
- `block-producer-uptime-monitoring`: This chart deploys the Mina Foundation Block Producer Uptime Monitoring application.
- `leaderboard`: This chart deploys the Mina Foundation leaderboard application.
- `mina-archive`: This chart deploys the Mina Archive component from Mina Protocol.
- `mina-daemon`: This chart deploys the Mina Daemon component from Mina Protocol.
- `mina-light-explorer`: This chart deploys the Mina Light Explorer project from Mina Protocol.
- `node-stats-collector`: This chart deploys application for Mina nodes to report stats/errors to.
- `minametrix`: This chart deploys an application to track repository that use o1js.

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

Contributions to this repository are accepted. If you have suggestions or feedback, please raise an issue or a pull request.
