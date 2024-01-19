import os
import logging
import sys
import psycopg2
import json
import boto3
from datetime import datetime

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
    conn = psycopg2.connect(host=host, dbname=dbname, user=user, password=password, connect_timeout=10)
    logging.info("Successfully connected to PostgreSQL.")
    
except (Exception, psycopg2.Error) as e:
    logger.error("ERROR: Failed to connect to PostgreSQL.")
    logger.error(e)
    sys.exit()


def lambda_handler(event, context):

    with conn.cursor() as cur:
            
        # Extract user's input data from their API call
        try:
            print('event:', json.dumps(event))
            print('queryStringParameters:', json.dumps(event['queryStringParameters']))
            
            user_input = event['queryStringParameters']
            expected_input = ('start', 'end', 'kwh', 'kw', 'node')
            if all(key in user_input for key in expected_input):
                start_time = datetime.strptime(user_input.get('start'), '%Y-%m-%d %H:%M:%S')
                end_time = datetime.strptime(user_input.get('end'), '%Y-%m-%d %H:%M:%S')
                kwh_to_charge = float(user_input.get('kwh'))
                kw_charge_rate = float(user_input.get('kw'))
                node = user_input.get('node')
                logger.info("Successfully extracted user input data.")
            else:
                missing_keys = [key for key in expected_input if key not in user_input]
                logger.error("ERROR: Failed to extract user input data, due to incomplete API call.")
                logger.error("Missing data: {}".format(missing_keys))
                sys.exit()
                
        # except KeyError as e:
        #    pass

        except Exception as e:
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
                    kw_charge_rate,
                    node
                )
            )
            conn.commit()
            request_id = cur.fetchone()[0]
            logger.info(f"Successfully logged the run request in opt_requests table, for request_id: {request_id}.")
            
        except (Exception, psycopg2.Error) as e:
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
            
        except (Exception, psycopg2.Error) as e:
            logger.error("ERROR: Failed to trigger the step function for the opt problems pipeline.")
            logger.error(e)
            sys.exit()