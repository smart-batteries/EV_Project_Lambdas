import os
import sys
import logging
import psycopg2
from uuid import uuid4

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

    prob_id = event
    
    with conn.cursor() as cur:

        # Retrieve the start & end times that define the time window
        try:
            cur.callproc('extract_time_window', (prob_id,))
            window = cur.fetchall()[0]
            start_time, end_time, node = window
            logger.info(f"Successfully retrieved the time window, from {start_time} to {end_time}, for node {node}.")

        except Exception as e:
            logger.error("ERROR: Failed to retrieve the start & end times of the time window.")
            logger.error(e)
            sys.exit()
        
        # Extract the price forecasts, for each half-hour interval of the time window for that node, from elec_prices table
        try:
            cur.callproc('extract_prob_prices', (start_time, end_time, node))
            forecast_data = cur.fetchall()
            start_period = min(forecast_data, key = lambda x: x[1])[1]
            end_period = max(forecast_data, key = lambda x: x[1])[1]
            logger.info(f"Successfully extracted the price forecasts, from trading periods {start_period} to {end_period}.")

        except Exception as e:
            logger.error("ERROR: Failed to extract the trading periods for the time window.")
            logger.error(e)
            sys.exit()
        
        for forecast in forecast_data:
                
            # Insert the price forecasts of each half-hour interval of the optimisation problem, into opt_prob_prices table
            try:
                trading_period = forecast[1]
                price = forecast[2]
                time_of_forecast = forecast[3]
                cur.callproc(
                    "insert_prob_prices",
                    (prob_id, price, trading_period, time_of_forecast)
                )
                conn.commit()
                price_id = cur.fetchall()[0][0]
                logger.info(f"Successfully inserted forecast data, with price id {price_id} for trading period {trading_period}.")
                
            except Exception as e:
                logger.error("ERROR: Failed to insert the forecast data.")
                logger.error(e)
                sys.exit()
                
        # Generate & return a run id, to pass to the state machine
        return {
            "run_id": str(uuid4())
        }