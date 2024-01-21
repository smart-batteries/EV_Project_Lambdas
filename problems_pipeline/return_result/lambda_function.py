import os
import logging
import sys
import psycopg2
# from uuid import uuid4

# db connection settings
host = os.environ['RDS_HOST']
dbname = os.environ['DB_NAME']
user = os.environ['USER_NAME']
password = os.environ['PASSWORD']

# create logger object
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


# model's output is stored in the opt_run_decisions table

# user sends the run_id to the api gateway
# function is invoked
# function extracts the run_id from the api call
# from opt_run_decisions table, for the run_id, get each price_id and decision_value
# join to price_forecasts table, for each price_id, get the corresponding datetime & price


def lambda_handler(event, context):
            
    with conn.cursor() as cur:
            
        # Extract user's run_id from the their API call
        try:
            print('event:', json.dumps(event))
            print('queryStringParameters:', json.dumps(event['queryStringParameters']))
            
            user_input = event['queryStringParameters']
            if tracking_id in user_input:
                run_id = user_input.get('tracking_id')
                logger.info("Successfully extracted user's run_id.")
            else:
                missing_keys = [key for key in expected_input if key not in user_input]
                logger.error("ERROR: Failed because user's API call is missing the run_id.")
                sys.exit()
                
        # except KeyError as e:
        #    pass

        except Exception as e:
            logger.error("ERROR: Failed to extract user's run_id.")
            logger.error(e)
            sys.exit()
            
        # Extract all price_id and decision_value for that run_id

'''
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


'''