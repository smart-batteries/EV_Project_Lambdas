import os
import logging
import sys
import requests
import json
import boto3

# Set variables for schedule call
client_id = os.environ['CLIENT_ID']
client_secret = os.environ['CLIENT_SECRET']
schedule_auth_url = "https://api.electricityinfo.co.nz/login/oauth2/token"
schedule_call_url = "https://api.electricityinfo.co.nz/api/market-prices/v1/schedules/PRSS/prices?marketType=E&forward=8"

# Set variables for sending call results to sqs queue
queue_url = os.environ['QUEUE_URL']
message_attributes = {
  'source': {
    'DataType': 'String',
    'StringValue': 'PRSS'
  }
}
batch_size = 250 # Max 262144 bytes per message / 360 bytes per dict, but keep messages small for downstream functions

# Create logger object
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Create client to interact with SQS
sqs = boto3.client('sqs')

# Obtain the OAuth 2.0 Bearer Token
data = {
  "grant_type": "client_credentials",
  "client_id": client_id,
  "client_secret": client_secret
}
try:
  response_auth = requests.post(schedule_auth_url, data=data)
except Exception as e:
  logger.error("ERROR: Failed to obtain OAuth 2.0 Bearer Token.")
  logger.error(e)
  sys.exit()


def lambda_handler(event, context):

    # Obtain price data
    token = response_auth.json()["access_token"]
    headers = {"Authorization": "Bearer {}".format(token)}
    response_call = requests.get(schedule_call_url, headers=headers)
    parsed = response_call.json()
    prices = parsed['prices']
    
    
    # Batch data for sqs message contents
    for i in range(0, len(prices), batch_size):
      batch = prices[i:i+batch_size]
      
      # Prepare sqs message contents
      message_body = json.dumps(batch, indent=4)
      
      # Send price data to queue
      sqs.send_message(
        QueueUrl = queue_url,
        MessageAttributes = message_attributes,
        MessageBody = message_body
      )
    
    # Log the schedule runtime
    schedule_run_time = prices[0]["lastRunTime"]
    logging.info(f"Successfully called PRSS schedule for schedule runtime: {schedule_run_time}.")