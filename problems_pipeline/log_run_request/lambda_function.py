import os
import logging
import sys
import psycopg
import json
import boto3

# Postgres connection settings
host = os.environ['RDS_HOST']
dbname = os.environ['DB_NAME']
user = os.environ['USER_NAME']
password = os.environ['PASSWORD']

# Create logger object
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Create client to trigger the step function
step_func_client = boto3.client('stepfunctions')

# Connect to the database
try:
    conn = psycopg.connect(host=host, dbname=dbname, user=user, password=password, connect_timeout=10)
    logging.info("Successfully connected to PostgreSQL.")
    
except (Exception, psycopg.Error) as e:
    logger.error("ERROR: Failed to connect to PostgreSQL.")
    logger.error(e)
    sys.exit()


def lambda_handler(event, context):

    with conn.cursor() as cur:
            
        # Extract info from user's external API call
        try:
            user_input = event['queryStringParameters']
            start_time = user_input['start_time']
            end_time = user_input['end_time']
            kwh_to_charge = user_input['kwh_to_charge']
            kw_charge_rate = user_input['kw_charge_rate']
            logger.info("Successfully extracted user input data.")

        except (Exception) as e:
            logger.error("ERROR: Failed to extract user input data.")
            logger.error(e)
            sys.exit()
            
        # Log the new run request in opt_requests table
        try:
            cur.callproc(
                "insert_opt_request",
                (
                    start_time,
                    end_time,
                    kwh_to_charge,
                    kw_charge_rate
                )
            )
            conn.commit()
            request_id = cur.fetchone()[0]
            logger.info(f"Successfully logged the run request in opt_requests table, for request_id: {request_id}.")
            
        except (Exception, psycopg.Error) as e:
            logger.error("ERROR: Failed to log the run request in opt_requests table.")
            logger.error(e)
            sys.exit()
            
        # Trigger the step function to invoke the downstream functions
        try:
            input = {
                "request_id": str(request_id)
            }
            response = step_func_client.start_execution(
                stateMachineArn = 'arn:aws:states:us-east-1:133433735071:stateMachine:problems_pipeline_state_machine',
                input = json.dumps(input)
            )
            logger.info("Successfully triggered the step function to invoke the rest of the opt problems pipeline.")
            
        except (Exception, psycopg.Error) as e:
            logger.error("ERROR: Failed to trigger the step function for the opt problems pipeline.")
            logger.error(e)
            sys.exit()