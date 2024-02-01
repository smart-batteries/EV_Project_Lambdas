import os
import sys
import logging
import psycopg2
import json

# Set variables to connect to Postgres
host = os.environ['RDS_HOST']
dbname = os.environ['DB_NAME']
user = os.environ['USER_NAME']
password = os.environ['PASSWORD']

# Create logger object
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Connect to the database
try:
    conn = psycopg2.connect(host=host, dbname=dbname, user=user, password=password, connect_timeout=10)
    logging.info(f"Successfully connected to {dbname} database at {host}.")
    
except (Exception, psycopg2.Error) as e:
    logger.error("ERROR: Failed to connect to PostgreSQL.")
    logger.error(e)
    sys.exit()


def lambda_handler(event, context):

    request_id = event['request_id']
    
    with conn.cursor() as cur:

        # For each half-hour interval in the time window given, retrieve its yes/no decision value
        try:
            cur.callproc("extract_model_decisions", (request_id,))
            model_decisions = cur.fetchall()
            logger.info(f"Successfully extracted the model output: {model_decisions}")
    
        except (Exception, psycopg2.Error) as e:
            logger.error(f"ERROR: Failed to extract the model output for the request_id: {request_id}")
            logger.error(e)
            sys.exit()
            
        charging_schedule = {"Charging schedule": model_decisions }
        
        logger.info(charging_schedule)
        return json.dumps(charging_schedule)