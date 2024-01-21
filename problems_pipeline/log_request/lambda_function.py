import os
import sys
import logging
import psycopg2
from datetime import datetime

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
    
    start_time = datetime.strptime( event.get('start_time'), '%Y-%m-%d %H:%M' )
    end_time = datetime.strptime( event.get('end_time'), '%Y-%m-%d %H:%M' )
    kwh_to_charge = event.get('kwh_to_charge')
    kw_charge_rate = event.get('kw_charge_rate')
    node = event.get('node')

    with conn.cursor() as cur:
          
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

        # Return request_id to the state machine
        return {
            "full_request" : {
                "request_id": request_id,
                "start_time": start_time,
                "end_time": end_time,
                "kwh_to_charge": kwh_to_charge,
                "kw_charge_rate": kw_charge_rate,
                "node": node
            }
        }



'''
if state machine is set to : $.full_request

if set to: $.request_id

use: 
        return {
            "request_id": request_id
        }
    
'''