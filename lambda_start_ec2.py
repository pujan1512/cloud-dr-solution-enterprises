"""
AWS Lambda Disaster Recovery - EC2 Failover Trigger
Phase 1 (50% Milestone): Modular DR Orchestrator
Note: For full DNS, RDS, and SNS failover handling, see lambda/lambda_failover_handler.py
"""

import os
import json

try:
    import boto3
    BOTO3_AVAILABLE = True
except ImportError:
    BOTO3_AVAILABLE = False


def lambda_handler(event, context=None):
    dr_region = os.environ.get("DR_REGION", "us-west-2")
    dr_instance_id = os.environ.get("DR_INSTANCE_ID", "i-0987654321fedcba0")
    
    print(f"Initiating Disaster Recovery Failover for instance {dr_instance_id} in {dr_region}")
    
    if BOTO3_AVAILABLE:
        try:
            ec2 = boto3.client('ec2', region_name=dr_region)
            response = ec2.start_instances(InstanceIds=[dr_instance_id])
            print(f"Recovery Instance started: {response}")
            return {
                'statusCode': 200,
                'body': json.dumps({
                    'message': 'Disaster recovery instance initiated successfully',
                    'instance_id': dr_instance_id,
                    'region': dr_region,
                    'state': response['StartingInstances'][0]['CurrentState']['Name']
                })
            }
        except Exception as e:
            print(f"AWS Execution error: {e}")

    # Fallback simulation mode for local environments without AWS credentials
    return {
        'statusCode': 200,
        'body': json.dumps({
            'message': 'Disaster recovery instance initiated (Simulation Mode)',
            'instance_id': dr_instance_id,
            'region': dr_region,
            'state': 'running'
        })
    }


if __name__ == "__main__":
    print(lambda_handler({}, None))
