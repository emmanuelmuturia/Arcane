import json
import boto3

def lambda_handler(event, context):
    try:
        ec2 = boto3.client('ec2')
        cw = boto3.client('cloudwatch')

        # Step 1: List EC2 Instances
        instances = ec2.describe_instances()
        instance_data = []

        for reservation in instances['Reservations']:
            for instance in reservation['Instances']:
                instance_id = instance['InstanceId']
                instance_state = instance['State']['Name']

                # Step 2: Get CPU Utilization (last hour average)
                metrics = cw.get_metric_statistics(
                    Namespace='AWS/EC2',
                    MetricName='CPUUtilization',
                    Dimensions=[{'Name': 'InstanceId', 'Value': instance_id}],
                    StartTime=datetime.utcnow() - timedelta(hours=1),
                    EndTime=datetime.utcnow(),
                    Period=3600,
                    Statistics=['Average']
                )

                avg_cpu = metrics['Datapoints'][0]['Average'] if metrics['Datapoints'] else 0.0

                instance_data.append({
                    "InstanceId": instance_id,
                    "State": instance_state,
                    "AverageCPUUtilization": round(avg_cpu, 2)
                })

        return {
            "statusCode": 200,
            "body": json.dumps({"EC2Metrics": instance_data})
        }

    except Exception as e:
        print("ERROR:", str(e))
        return {
            "statusCode": 500,
            "body": json.dumps({"error": str(e)})
        }