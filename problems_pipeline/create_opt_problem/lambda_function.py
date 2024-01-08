import os
import logging
import sys
import psycopg

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
    conn = psycopg.connect(host=host, dbname=dbname, user=user, password=password, connect_timeout=10)
    logging.info("Successfully connected to PostgreSQL.")
except (Exception, psycopg.Error) as e:
    logger.error("ERROR: Failed to connect to PostgreSQL.")
    logger.error(e)
    sys.exit()


def lambda_handler(event, context):
    
    request_id = event['request_id']
    
    with conn.cursor() as cur:
        
        # Extract values from opt_requests table for the given request_id
        try:
            cur.callproc(extract_opt_request, [request_id])
            request = cur.fetchone()
            start_time, end_time, kwh_to_charge, kw_charge_rate = request
            logger.info(f"Successfully extracted user data from opt_requests table, for request_id: {request_id}.")

        except Exception as e:
            logger.error(f"ERROR: Failed to extract user data from opt_requests table, for request_id: {request_id}.")
            logger.error(e)
            sys.exit()

        # Calculate values to insert into opt_problems table
        start_rounded = round_time_up(start_time)
        end_rounded = round_time_down(end_time)
        periods_until_deadline = int((end_rounded - start_rounded).total_seconds() / 1800) # 1800 seconds per half-hour interval
        periods_of_charge_required = kwh_to_charge / kw_charge_rate * 2
        
        # Insert calculated values into opt_problems table
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
            
        except Exception as e:
            logger.error("ERROR: Failed to create an optimisation problem in opt_problems table.")
            logger.error(e)
            sys.exit()

        # Return problem id, to pass as input to the downstream function
        return {
            "prob_id": str(prob_id)
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