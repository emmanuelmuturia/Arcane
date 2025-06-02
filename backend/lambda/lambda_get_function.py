import json
import boto3
from datetime import datetime, timedelta

def lambda_handler(event, context):
    try:
        ec2 = boto3.client('ec2')
        cw = boto3.client('cloudwatch')

        # Step 1: List the EC2 Instances...
        instances = ec2.describe_instances()
        instance_data = []

        for reservation in instances['Reservations']:
            for instance in reservation['Instances']:
                instance_id = instance['InstanceId']
                instance_state = instance['State']['Name']

                # Step 2: List the available metrics for this EC2 Instance...
                metrics = cw.list_metrics(
                    Namespace='AWS/EC2',
                    Dimensions=[{'Name': 'InstanceId', 'Value': instance_id}]
                )

                metric_data = {}
                seen_metrics = set()  # To avoid duplicate metric names...

                for metric in metrics['Metrics']:
                    metric_name = metric['MetricName']
                    if metric_name in seen_metrics:
                        continue
                    seen_metrics.add(metric_name)

                    # Step 3: Get the Metric Statistics...
                    stats = cw.get_metric_statistics(
                        Namespace='AWS/EC2',
                        MetricName=metric_name,
                        Dimensions=metric['Dimensions'],
                        StartTime=datetime.utcnow() - timedelta(hours=1),
                        EndTime=datetime.utcnow(),
                        Period=300,
                        Statistics=['Average']
                    )

                    if stats['Datapoints']:
                        latest = max(stats['Datapoints'], key=lambda x: x['Timestamp'])
                        metric_data[metric_name] = round(latest['Average'], 2)
                    else:
                        metric_data[metric_name] = None

                instance_data.append({
                    "InstanceId": instance_id,
                    "State": instance_state,
                    "Metrics": metric_data
                })

        return {
            "statusCode": 200,
            "body": json.dumps({"EC2Metrics": instance_data}, default=str)
        }

    except Exception as e:
        print("ERROR:", str(e))
        return {
            "statusCode": 500,
            "body": json.dumps({"error": str(e)})
        }