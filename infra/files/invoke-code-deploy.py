import json
import sys
import time
from argparse import ArgumentParser

import boto3

code_deploy_client = boto3.client('codedeploy')


def get_args():
    """

    """
    parser = ArgumentParser(description='Deploy a CodeDeploy application and wait for it to finish')
    parser.add_argument('--input-file-path', required=True,
                        help='This is the input file as expected by the AWS CLI when using "aws deploy create-deployment --cli-input-json ...".')

    return parser.parse_args()


def wait_for_deployment(deployment_id: str) -> bool:
    """
    Wait until the deployment is complete (success or failure).
    """

    while True:
        response = code_deploy_client.get_deployment(
            deploymentId=deployment_id
        )
        status = response["deploymentInfo"]['status']

        match status:
            case 'Created' | 'Queued' | 'InProgress' | 'Baking' | 'Ready':
                print(f"Deployment '{deployment_id}' {status}...")
                time.sleep(5)
            case 'Succeeded':
                print(f"Deployment '{deployment_id}' succeeded")
                return True
            case 'Failed':
                print(f"Deployment '{deployment_id}' failed")
                return False
            case 'Stopped':
                print(f"Deployment '{deployment_id}' stopped")
                return False
            case _:
                print(f"Unexpected status: {status}")
                return False


def main():
    args = get_args()
    with open(args.input_file_path) as f:
        input_data = json.load(f)

    msg = f"Deploying the application '{input_data['applicationName']}' and deployment group '{input_data['deploymentGroupName']}'. "
    msg += f"Description: {input_data['description']}"
    deployment = code_deploy_client.create_deployment(**input_data)
    print(msg)

    status = wait_for_deployment(deployment['deploymentId'])

    if not status:
        print("The deployment has failed")
        sys.exit(1)


main()
