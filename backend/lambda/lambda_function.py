import boto3
import os
import json

ec2 = boto3.client("ec2")
sns = boto3.client("sns")

SNS_TOPIC_ARN = os.environ.get("SNS_TOPIC_ARN")

def lambda_handler(event, context):
    try:
        print("EVENT:", event)

        body = json.loads(event.get("body", "{}"))
        instance_id = body.get("instance_id")

        if not instance_id:
            raise ValueError("No instance_id provided")

        response = ec2.describe_instances(InstanceIds=[instance_id])
        state = response["Reservations"][0]["Instances"][0]["State"]["Name"]

        if state == "running":
            ec2.reboot_instances(InstanceIds=[instance_id])
            msg = f"Instance {instance_id} was running. Reboot triggered..."
        elif state == "stopped":
            ec2.start_instances(InstanceIds=[instance_id])
            msg = f"Instance {instance_id} was stopped. Starting now..."
        else:
            msg = f"Instance {instance_id} is in '{state}' state. No action taken..."

        # Publish to SNS...
        if SNS_TOPIC_ARN:
            sns.publish(
                TopicArn=SNS_TOPIC_ARN,
                Subject="The Arcane Self-Heal Functionality Has Been Triggered...",
                Message=msg
            )

        return {
            "statusCode": 200,
            "body": json.dumps({"message": msg})
        }

    except Exception as e:
        print("ERROR:", str(e))
        if SNS_TOPIC_ARN:
            sns.publish(
                TopicArn=SNS_TOPIC_ARN,
                Subject="Arcane Self-Heal FAILED",
                Message=str(e)
            )
        return {
            "statusCode": 500,
            "body": json.dumps({"error": str(e)})
        }