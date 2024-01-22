import os
import sys
import logging
import psycopg2
from datetime import datetime

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


def lambda_handler(event, context):

    request_id = event
    
    with conn.cursor() as cur:

        # Extract values from state machine's input
        try:
            cur.callproc('extract_run_request', (request_id,) )
            request = cur.fetchall()[0]
            start_time, end_time, kwh_to_charge, kw_charge_rate = request
            logger.info(f"Successfully extracted user data from opt_requests table, for request_id: {request_id}.")
            
        except Exception as e:
            logger.error("ERROR: Failed to receive user data from state machine.")
            logger.error(e)
            sys.exit()
        
        # Transform into values to insert into opt_problems table
        try:
            start_rounded = round_time_up(start_time)
            end_rounded = round_time_down(end_time)
            periods_until_deadline = int((end_rounded - start_rounded).total_seconds() / 1800) # 1800 seconds per half-hour interval
            periods_of_charge_required = int(kwh_to_charge / kw_charge_rate * 2)
            logger.info(f"Successfully transformed user data into inputs for the model, for request_id: {request_id}.")
            
        except Exception as e:
            logger.error(f"ERROR: Failed to transform user data, for request_id: {request_id}.")
            logger.error(e)
            sys.exit()

        # Insert transformed values into opt_problems table, generating the optimisation problem
        try:
            cur.callproc(
                "insert_opt_problem",
                (
                    request_id,
                    periods_until_deadline,
                    periods_of_charge_required
                )
            )
            
            conn.commit()
            prob_id = cur.fetchone()[0]
            logger.info(f"Successfully created an optimisation problem in opt_problems table, with the problem id: {prob_id}.")
            logger.info("End.")
            
        except Exception as e:
            logger.error("ERROR: Failed to create an optimisation problem in opt_problems table.")
            logger.error(e)
            sys.exit()

        # Return prob_id to the state machine
        return {
            "prob_id": prob_id
        }


def round_time_up(dt):
    if dt.minute < 30:
        dt = dt.replace(minute=30, second=0, microsecond=0)
    else:
        dt = dt.replace(hour=dt.hour + 1, minute=0, second=0, microsecond=0)
    return dt

def round_time_down(dt):
    if dt.minute >= 30:
        dt = dt.replace(minute=30, second=0, microsecond=0)
    else:
        dt = dt.replace(minute=0, second=0, microsecond=0)
    return dt
