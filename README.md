# Mina Foundation Private Helm Charts

This repository contains private Helm charts used by Mina Foundation. These charts are not intended for public consumption and are only available to authorized parties.

## Getting Started

To use these charts, you must have access to the Mina Foundation's private Git repository that contains the charts. Contact the Mina Foundation team for more information on obtaining access.

## Chart List

The following is a list of charts available in this repository:

- `block-producer-uptime`: This chart deploys the Mina Foundation Block Producer Uptime application.
- `leaderboard`: This chart deploys the Mina Foundation leaderboard application.
- `mina-archive`: This chart deploys the Mina Daemon component from Mina Protocol.
- `mina-daemon`: This chart deploys the Mina Archive component from Mina Protocol.

## Deploying a Local Chart

To deploy a chart from this repository, you can first download the chart files and then install the chart using the `helm install` command.

1. Download the chart files for the `leaderboard` chart from the Mina Foundation private Git repository.
2. Extract the files from the downloaded archive to a local directory.
3. Install the chart using the `helm install` command and passing in the path to the chart directory. For example:

```
helm install leaderboard ./leaderboard
```

This command installs the `leaderboard` chart using the local files in the `leaderboard` directory. You can adjust the command to fit your environment and specific requirements.

## Contributing

Contributions to this repository are not accepted. If you have suggestions or feedback, please contact the Mina Foundation DevOps team directly.

## License

These charts are proprietary and confidential to Mina Foundation.
