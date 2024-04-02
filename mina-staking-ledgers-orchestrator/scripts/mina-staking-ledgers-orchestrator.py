#!/usr/bin/env python3

import os
import subprocess
import json
import boto3
import requests
from requests_toolbelt.multipart.encoder import MultipartEncoder
import tarfile

# Function to check if an environment variable is set and not empty
def check_env_variable(var_name):
    if var_name not in os.environ or not os.environ[var_name]:
        print(f"The {var_name} environment variable is not set or is empty.")

# Function to get pods with a specific label using `kubectl`
def get_pods_with_label(label):
    command = ["kubectl", "get", "pods", "-l", label, "-o", "json"]
    output = subprocess.check_output(command)
    pods_info = json.loads(output)
    return pods_info['items']

# Function to check the synchronization status of a pod
def check_sync_status(pod_name):
    command = ["kubectl", "exec", pod_name, "-c", "mina", "--", "mina", "client", "status", "--json"]
    output = subprocess.check_output(command)
    status_info = json.loads(output)
    return status_info['sync_status']

# Function to copy a file from a pod to the local file system
def copy_file_from_pod(pod_name, remote_file_path, local_file_path):
    command = ["kubectl", "cp", f"{pod_name}:{remote_file_path}", local_file_path, "-c", "mina"]
    subprocess.run(command, check=True)
    print(f"File copied successfully from {pod_name}:{remote_file_path} to {local_file_path}")

# Function to get the current epoch from a pod
def get_current_epoch(pod_name):
    try:
        command = ["kubectl", "exec", pod_name, "-c", "mina", "--", "mina", "client", "status", "--json"]
        output = subprocess.check_output(command)
        status_info = json.loads(output)
        # Extract slot number and slots per epoch
        slot_number = int(status_info['consensus_time_now']['slot_number'])
        slots_per_epoch = int(status_info['consensus_time_now']['slots_per_epoch'])
        # Calculate current epoch
        current_epoch = slot_number // slots_per_epoch
        return current_epoch
    except Exception as e:
        print(f"Error extracting current epoch: {e}")
        return None

# Function to run a command on a pod
def run_command_on_pod(pod_name, command):
    # Construct the command string
    command_str = " ".join(command)
    # Log the command
    print(f"Running command on pod {pod_name}: {command_str}")
    try:
        # Execute the command within a shell and capture output
        result = subprocess.run(["kubectl", "exec", pod_name, "-c", "mina", "--", "/bin/sh", "-c", " ".join(command)],
                                check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, universal_newlines=True)
        output = result.stdout.strip()
        error = result.stderr.strip()
        if output:
            print(f"Command output from pod {pod_name}:")
            print(output)
        if error:
            print(f"Command error from pod {pod_name}:")
            print(error)
        return output
    except subprocess.CalledProcessError as e:
        print(f"Error running command on pod {pod_name}: {e}")
        return None

def check_file_existence_in_s3(bucket_name, subpath, object_name):
    # Create an S3 client
    s3_client = boto3.client('s3')
    try:
        # List objects in the specified subpath
        response = s3_client.list_objects_v2(Bucket=bucket_name, Prefix=f"{subpath}/{object_name}")

        # Check if any objects match the specified key
        for obj in response.get('Contents', []):
            if obj['Key'] == f"{subpath}/{object_name}":
                print(f"File {object_name} exists in S3 bucket {bucket_name}, Subpath: {subpath}")
                return True

        # File not found
        print(f"File {object_name} does not exist in S3 bucket {bucket_name}, Subpath: {subpath}")
        return False
    except Exception as e:
        print(f"Error checking file existence in S3: {e}")
        return False

def upload_file_to_s3(file_path, bucket_name, subpath, object_name):
    # Create an S3 client
    s3_client = boto3.client('s3')

    try:
        # Upload the file with the subpath included in the object key
        s3_client.upload_file(file_path, bucket_name, f"{subpath}/{object_name}")
        print(f"File uploaded successfully to S3 bucket: {bucket_name}, Subpath: {subpath}, Object key: {object_name}")
        return True
    except Exception as e:
        print(f"Error uploading file to S3: {e}")
        return False

def send_slack_notification(webhook_url, message):
    try:
        # Define the payload for the Slack message
        payload = {
            "text": message
        }

        # Send the POST request to the Slack webhook URL
        response = requests.post(webhook_url, json=payload)

        # Check if the request was successful (status code 200)
        if response.status_code == 200:
            print("Slack notification sent successfully")
            return True
        else:
            print(f"Failed to send Slack notification. Status code: {response.status_code}")
            return False
    except Exception as e:
        print(f"Error sending Slack notification: {e}")
        return False

def validate_json_file(file_path):
    try:
        with open(file_path, 'r') as file:
            json.load(file)
        print("JSON file is valid.")
        return True
    except FileNotFoundError:
        print("File not found.")
        return False
    except json.JSONDecodeError as e:
        print(f"JSON decoding error: {e}")
        return False

# Function to submit the mina payout data to the data provider
def submit_mina_payout_data(username, password, staking_ledger_name, staking_ledger_hash, api_url, epoch):
    url = f"{api_url}/{staking_ledger_hash}?userSpecifiedEpoch={epoch}"
    file_content = open(f'{staking_ledger_name}', 'rb').read()
    multipart_data = MultipartEncoder(
        fields={'jsonFile': (staking_ledger_name, file_content, 'application/json')}
    )
    auth = (username, password)
    headers = {'Content-Type': multipart_data.content_type}

    print(f"Submitting {staking_ledger_hash} to Mina Payout Data Provider API: {url}")

    try:
        response = requests.post(url, data=multipart_data, auth=auth, headers=headers)
        status_code = response.status_code
        print(f"Status code: {status_code}")
        if status_code == 200:
            print(f"Successfully posted ledger {staking_ledger_name}")
        elif status_code == 409:
            print(f"Ledger {staking_ledger_name} already exists.")
        else:
            print(f"Failed to upload {staking_ledger_name}, status code: {status_code}")
    except requests.exceptions.RequestException as e:
        print(f"Error submitting JSON file: {e}")

# Function to process the staking ledger
def process_staking_ledger(synced_pod, epoch, staking_ledger, network, s3_bucket, s3_subpath, slack_webhook_url, mina_payouts_data_provider_url, mina_payouts_data_provider_username, mina_payouts_data_provider_password):
    try:
        # Retrieve staking-ledger
        run_command_on_pod(synced_pod, ["/usr/local/bin/mina", "ledger", "export", staking_ledger, ">", f"/tmp/{staking_ledger}.json"])

        # Get ledger hash from staking-ledger
        staking_ledger_hash = run_command_on_pod(synced_pod, ["/usr/local/bin/mina", "ledger", "hash", "--ledger-file", f"/tmp/{staking_ledger}.json"])

        # Log the staking ledger hash
        staking_ledger_name = f"{network}-{epoch}-{staking_ledger_hash}.json"
        print(f"The staking ledger name is: {staking_ledger_name}")

        # Rename the staking-ledger file
        run_command_on_pod(synced_pod, ["mv", f"/tmp/{staking_ledger}.json", f"/tmp/{staking_ledger_name}"])

        # Compress the staking-ledger file
        run_command_on_pod(synced_pod, ["tar", "-zcvf", f"/tmp/{staking_ledger_name}.tar.gz", "-C", "/tmp", staking_ledger_name])

        # Copy the staking-ledger file from the pod to the local file system
        copy_file_from_pod(synced_pod, f"/tmp/{staking_ledger_name}.tar.gz", f"{staking_ledger_name}.tar.gz")

        # Untar the compressed file
        with tarfile.open(f"{staking_ledger_name}.tar.gz", "r:gz") as tar:
            tar.extractall(path='./')

        # Clean up staking-ledger
        run_command_on_pod(synced_pod, ["rm", "-rf", f"/tmp/*.json*"])

        # Validate the staking ledger JSON file
        if validate_json_file(staking_ledger_name):
            message = f"*Mina Staking Ledgers:*\n"
            # Upload the staking-ledger file to S3 if it doesn't already exist
            s3_upload_success = False
            if not check_file_existence_in_s3(s3_bucket, s3_subpath, f"{staking_ledger_name}.tar.gz"):
                s3_upload_success = upload_file_to_s3(f"{staking_ledger_name}.tar.gz", s3_bucket, s3_subpath, f"{staking_ledger_name}.tar.gz")
                if s3_upload_success:
                    message += f":tada: `{staking_ledger_name}` uploaded successfully to S3: `{s3_bucket}/{s3_subpath}`\n"
            mina_upload_success = submit_mina_payout_data(mina_payouts_data_provider_username, mina_payouts_data_provider_password, staking_ledger_name, staking_ledger_hash, mina_payouts_data_provider_url, epoch)
            if mina_upload_success:
                message += f":tada: `{staking_ledger_name}` uploaded successfully to Mina Payout Data Provider API: `{s3_bucket}/{s3_subpath}`"

            # Send Slack notification if either upload to S3 or Mina upload is successful
            if s3_upload_success or mina_upload_success:
                send_slack_notification(slack_webhook_url, message)

    except Exception as e:
        print(f"Error processing staking ledger: {e}")

def main():
    # Set up logging
    log_level = os.environ.get("LOG_LEVEL", "INFO")

    # Check required environment variables
    check_env_variable("NETWORK")
    check_env_variable("S3_BUCKET")
    check_env_variable("MINA_NODE_LABEL")
    check_env_variable("MINA_PAYOUTS_DATA_PROVIDER_URL")
    check_env_variable("MINA_PAYOUTS_DATA_PROVIDER_USERNAME")
    check_env_variable("MINA_PAYOUTS_DATA_PROVIDER_PASSWORD")
    check_env_variable("SLACK_WEBHOOK_URL")

    # Get the MINA_NODE_LABEL from the environment variables
    MINA_NODE_LABEL = os.environ.get("MINA_NODE_LABEL")
    NETWORK = os.environ.get("NETWORK")
    S3_BUCKET = os.environ.get("S3_BUCKET")
    S3_SUBPATH = os.environ.get("S3_SUBPATH")
    SLACK_WEBHOOK_URL = os.environ.get("SLACK_WEBHOOK_URL")
    MINA_PAYOUTS_DATA_PROVIDER_URL = os.environ.get("MINA_PAYOUTS_DATA_PROVIDER_URL")
    MINA_PAYOUTS_DATA_PROVIDER_USERNAME = os.environ.get("MINA_PAYOUTS_DATA_PROVIDER_USERNAME")
    MINA_PAYOUTS_DATA_PROVIDER_PASSWORD = os.environ.get("MINA_PAYOUTS_DATA_PROVIDER_PASSWORD")

    # Get pods with the specified label
    pods = get_pods_with_label(MINA_NODE_LABEL)
    synced_pod = None  # Initialize variable to hold the synced pod
    current_epoch = None  # Initialize variable to hold the current epoch
    staking_ledger_hash = None  # Initialize variable to hold the staking ledger hash
    staking_ledger_name = None  # Initialize variable to hold the staking ledger name

    # Iterate over the pods
    for pod in pods:
        pod_name = pod['metadata']['name']
        try:
            # Check synchronization status for each pod
            sync_status = check_sync_status(pod_name)
            if sync_status == "Synced":
                print(f"{pod_name} is synced")
                synced_pod = pod_name  # Store the name of the synced pod
                break  # Break the loop if a synced pod is found
        except Exception as e:
            print(f"Error checking sync status for {pod_name}: {e}")

    # Use the synced_pod variable for further operations
    if synced_pod:
        print(f"The synced pod is: {synced_pod}")

        # Get current Epoch
        current_epoch=get_current_epoch(pod_name)
        print(f"The current epoch is: {current_epoch}")

        # Process staking-epoch-ledger
        process_staking_ledger(synced_pod, current_epoch, "staking-epoch-ledger", NETWORK, S3_BUCKET, S3_SUBPATH, SLACK_WEBHOOK_URL, MINA_PAYOUTS_DATA_PROVIDER_URL, MINA_PAYOUTS_DATA_PROVIDER_USERNAME, MINA_PAYOUTS_DATA_PROVIDER_PASSWORD)

        # Process next-epoch-ledger
        next_epoch=current_epoch + 1
        process_staking_ledger(synced_pod, next_epoch, "next-epoch-ledger", NETWORK, S3_BUCKET, S3_SUBPATH, SLACK_WEBHOOK_URL, MINA_PAYOUTS_DATA_PROVIDER_URL, MINA_PAYOUTS_DATA_PROVIDER_USERNAME, MINA_PAYOUTS_DATA_PROVIDER_PASSWORD)


    else:
        message= "*Mina Staking Ledgers:*\n No synced pod found for the specified label: {MINA_NODE_LABEL}"
        send_slack_notification(SLACK_WEBHOOK_URL, message)

if __name__ == "__main__":
    main()
