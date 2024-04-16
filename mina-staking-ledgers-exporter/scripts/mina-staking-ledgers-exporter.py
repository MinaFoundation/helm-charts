#!/usr/bin/env python3

from requests_toolbelt.multipart.encoder import MultipartEncoder
import boto3
import json
import logging
import os
import requests
import subprocess
import tarfile

logger = logging.getLogger(__name__)
s3_client = boto3.client("s3")
logging.basicConfig(level=os.environ.get("APP_LOG_LEVEL", "info").upper())


class config:

    api_password = os.environ["APP_MINA_PAYOUTS_DATA_PROVIDER_PASSWORD"]
    api_url = os.environ["APP_MINA_PAYOUTS_DATA_PROVIDER_URL"]
    api_username = os.environ["APP_MINA_PAYOUTS_DATA_PROVIDER_USERNAME"]
    mina_node_label = os.environ["APP_MINA_NODE_LABEL"]
    network = os.environ["APP_NETWORK"]
    s3_bucket = os.environ["APP_S3_BUCKET"]
    s3_subpath = os.environ.get("APP_S3_SUBPATH", "")
    slack_webhook_info_url = os.environ["APP_SLACK_WEBHOOK_INFO_URL"]
    slack_webhook_warn_url = os.environ["APP_SLACK_WEBHOOK_WARN_URL"]


def main():

    logger.info(" -- Staking ledgers exporter started --")

    logger.info("Searching for synced mina node")
    synced_pod = get_synced_pod(config.mina_node_label)
    logger.info(f"Found synced node: {synced_pod}")
    current_epoch, next_epoch = get_epochs(synced_pod)

    logger.info(f" -- Processing current epoch ({current_epoch}) --")
    process_staking_ledger(synced_pod, current_epoch, "staking-epoch-ledger")
    logger.info(f" -- Processing next epoch ({next_epoch}) --")
    process_staking_ledger(synced_pod, next_epoch, "next-epoch-ledger")

    logger.info("Complete with success")


def process_staking_ledger(synced_pod, epoch, staking_ledger):

    logger.info(f"Exporting {staking_ledger}")
    run_command_on_pod(
        synced_pod,
        f"/usr/local/bin/mina ledger export {staking_ledger} > /tmp/{staking_ledger}.json",
    )

    logger.info(f"Calculating {staking_ledger} hash")
    staking_ledger_hash = run_command_on_pod(
        synced_pod, f"/usr/local/bin/mina ledger hash --ledger-file /tmp/{staking_ledger}.json"
    )

    staking_ledger_name = f"{config.network}-{epoch}-{staking_ledger_hash}.json"
    staking_ledger_archive_name = f"{staking_ledger_name}.tar.gz"
    logger.info(f"Ledger hash: {staking_ledger_hash}")
    logger.info(f"Ledger name: {staking_ledger_name}")

    logger.info("Copying ledger archive and cleanup")
    run_command_on_pod(synced_pod, f"mv /tmp/{staking_ledger}.json /tmp/{staking_ledger_name}")
    run_command_on_pod(
        synced_pod, f"tar -zcvf /tmp/{staking_ledger_name}.tar.gz -C /tmp {staking_ledger_name}"
    )
    copy_file_from_pod(
        synced_pod, f"/tmp/{staking_ledger_name}.tar.gz", f"{staking_ledger_name}.tar.gz"
    )
    run_command_on_pod(
        synced_pod, f"rm /tmp/{staking_ledger_name} /tmp/{staking_ledger_name}.tar.gz"
    )

    logger.info("Checking the ledger validity")
    with tarfile.open(staking_ledger_archive_name, "r:gz") as tar:
        tar.extractall(path="./")
    validate_json_file(staking_ledger_name)

    logger.info("Uploading to S3")
    uploaded_to_s3 = upload_file_to_s3(
        staking_ledger_archive_name,
        config.s3_bucket,
        config.s3_subpath,
        staking_ledger_archive_name,
    )

    logger.info("Uploading to Payout API")
    uploaded_to_api = submit_mina_payout_data(staking_ledger_name, staking_ledger_hash, epoch)

    logger.info("Sending notifications")
    message = ""
    if uploaded_to_s3:
        message += f":tada: Stacking ledger successfully uploaded to S3:\n"
        message += f"`{config.s3_bucket}/{config.s3_subpath}/{staking_ledger_archive_name}`\n\n"
    if uploaded_to_api:
        message += (
            f":tada: Stacking ledger successfully uploaded to Mina Payout Data Provider API:\n"
        )
        message += f"{config.api_url}"
    if message:
        slack_info(message)


def upload_file_to_s3(file_path, bucket_name, subpath, object_name):
    if is_file_existing_on_s3(bucket_name, subpath, object_name):
        logger.debug("File already on S3, upload skipped.")
        return False

    key = f"{subpath}/{object_name}"
    s3_client.upload_file(file_path, bucket_name, key)
    logger.debug(
        f"File uploaded successfully to S3 bucket: {bucket_name}, Subpath: {subpath}, Object key: {object_name}"
    )
    return True


def submit_mina_payout_data(staking_ledger_name, staking_ledger_hash, epoch):
    url = f"{config.api_url}/{staking_ledger_hash}"
    file_content = open(f"{staking_ledger_name}", "rb").read()
    data = MultipartEncoder(
        fields={"jsonFile": (staking_ledger_name, file_content, "application/json")}
    )
    auth = (config.api_username, config.api_password)
    headers = {"Content-Type": data.content_type}
    params = dict(userSpecifiedEpoch=epoch)

    logger.debug(f"Submitting {staking_ledger_hash} to Mina Payout Data Provider API: {url}")

    try:
        requests.post(url, data=data, auth=auth, headers=headers, params=params).raise_for_status()
        return True
    except requests.exceptions.HTTPError as e:
        logger.debug(f"Ledger {staking_ledger_name} already exists.")
        if e.response.status_code == 409:
            return False
        raise (e)
    except Exception as e:
        logger.error("Error on uploading to Payout API")
        raise (e)


def get_synced_pod(mina_node_label):
    pods = get_pods_with_label(mina_node_label)
    pod_names = [pod["metadata"]["name"] for pod in pods]

    for pod_name in pod_names:
        if is_synced_node(pod_name):
            return pod_name

    raise Exception(f"No synced pod found for the specified label: {mina_node_label}")


def get_pods_with_label(label):
    command = ["kubectl", "get", "pods", "-l", label, "-o", "json"]
    output = subprocess.check_output(command)
    pods_info = json.loads(output)
    return pods_info["items"]


def is_synced_node(pod_name):
    command = f"kubectl exec {pod_name} -c mina -- mina client status --json".split(" ")
    try:
        # The command could return non-zero exit code if the node is not ready
        output = subprocess.check_output(command)
        sync_status = json.loads(output)["sync_status"]
        return sync_status == "Synced"
    except Exception:
        return False


def get_epochs(pod_name):
    command = f"kubectl exec {pod_name} -c mina -- mina client status --json".split(" ")
    output = subprocess.check_output(command)
    status_info = json.loads(output)
    slot_number = int(status_info["consensus_time_now"]["slot_number"])
    slots_per_epoch = int(status_info["consensus_time_now"]["slots_per_epoch"])
    current_epoch = slot_number // slots_per_epoch
    next_epoch = current_epoch + 1
    return current_epoch, next_epoch


def copy_file_from_pod(pod_name, remote_file_path, local_file_path):
    command = ["kubectl", "cp", f"{pod_name}:{remote_file_path}", local_file_path, "-c", "mina"]
    subprocess.run(command, check=True)
    logger.debug(
        f"File copied successfully from {pod_name}:{remote_file_path} to {local_file_path}"
    )


def run_command_on_pod(pod_name, command):
    logger.debug(f"Running command on pod {pod_name}:\n{command}")
    result = subprocess.run(
        ["kubectl", "exec", pod_name, "-c", "mina", "--", "/bin/sh", "-c", command],
        check=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        universal_newlines=True,
    )
    output = result.stdout.strip()
    return output


def validate_json_file(file_path):
    try:
        with open(file_path, "r") as file:
            json.load(file)
    except Exception as e:
        logger.error("Unable to validate the JSON file")
        raise (e)


def is_file_existing_on_s3(bucket_name, subpath, object_name):
    contents = s3_client.list_objects_v2(Bucket=bucket_name, Prefix=f"{subpath}/{object_name}").get(
        "Contents", []
    )
    for obj in contents:
        if obj["Key"] == f"{subpath}/{object_name}":
            logger.debug(
                f"File {object_name} exists in S3 bucket {bucket_name}, Subpath: {subpath}"
            )
            return True
    logger.debug(
        f"File {object_name} does not exist in S3 bucket {bucket_name}, Subpath: {subpath}"
    )
    return False


def slack_info(message):
    send_slack_notification(config.slack_webhook_info_url, message)


def slack_warn(message):
    send_slack_notification(config.slack_webhook_warn_url, message)


def send_slack_notification(webhook_url, message):
    if not message:
        return
    json = dict(username="Mina Staking Ledgers Exporter", text=message)
    try:
        requests.post(webhook_url, json=json).raise_for_status()
    except Exception as e:
        logger.error("Unable to send slack notification")
        logger.error(e)


if __name__ == "__main__":
    try:
        main()
    except Exception as e:
        slack_warn(str(e))
        raise (e)
