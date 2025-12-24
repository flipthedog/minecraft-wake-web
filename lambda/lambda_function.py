import boto3
import os
import json

ssm = boto3.client('ssm')
ec2 = boto3.client('ec2')

def get_parameter(name):
    response = ssm.get_parameter(Name=name, WithDecryption=True)
    return response['Parameter']['Value']

def lambda_handler(event, context):
    print(f'Received event: {json.dumps(event)}')
    
    try:
        # Get instance ID from Parameter Store
        instance_id = get_parameter(os.environ['INSTANCE_ID_PARAM'])
        print(f'Instance ID: {instance_id}')
        
        # Check instance status
        response = ec2.describe_instances(InstanceIds=[instance_id])
        instance = response['Reservations'][0]['Instances'][0]
        state = instance['State']['Name']
        print(f'Current instance state: {state}')
        
        # Start the instance if it's stopped
        if state == 'stopped':
            ec2.start_instances(InstanceIds=[instance_id])
            message = f'✅ Starting Minecraft server! Please give it a minute to start prior to connecting.'
            print(f'Started instance {instance_id}')
        elif state == 'running':
            message = '✅ Minecraft server is already running!'
            print('Instance already running')
        else:
            message = f'⚠️ Instance is {state}, cannot start'
            print(f'Instance in unsupported state: {state}')
        
        return {
            'statusCode': 200,
            'headers': {
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Headers': 'Content-Type',
                'Access-Control-Allow-Methods': 'POST,OPTIONS',
                'Content-Type': 'text/plain'
            },
            'body': message
        }
        
    except Exception as e:
        print(f'Error: {str(e)}')
        return {
            'statusCode': 500,
            'headers': {
                'Access-Control-Allow-Origin': '*',
                'Content-Type': 'text/plain'
            },
            'body': f'❌ Error starting server: {str(e)}'
        }
