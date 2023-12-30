import os
import logging
import sys
import psycopg
from uuid import uuid4

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

    prob_id = event['prob_id']
    
    with conn.cursor() as cur:

        # Retrieve the start & end times that define the time window
        try:
            cur.callproc("extract_time_window", [prob_id])
            window = cur.fetchone()
            start_time, end_time = window
            logger.info(f"Successfully retrieved the start-time: {start_time} and end-time: {end_time}.")

        except Exception as e:
            logger.error("ERROR: Failed to retrieve the start & end times of the time window.")
            logger.error(e)
            sys.exit()
        
        # Transform the start & end times to a series of half-hour intervals
        try:
            ##################### for now, just using a single chosen node, KAW2201
            cur.callproc("transform_time_window", [start_time, end_time])
            forecast_data = cur.fetchall()
            start_period = min(forecast_data, key = lambda x: x[0])[0]
            end_period = max(forecast_data, key = lambda x: x[0])[0]
            logger.info(f"Successfully extracted the trading periods, from periods {start_period} to {end_period}.")

        except Exception as e:
            logger.error("ERROR: Failed to extract the trading periods for the time window.")
            logger.error(e)
            sys.exit()
        
        for forecast in forecast_data:

            # Extract the forecast data of each half-hour interval of the optimisation problem, from elec_prices table
            try:
                trading_period = forecast[0]
                price = forecast[2]
                time_of_forecast = forecast[3]
                logger.info(f"Successfully retrieved the forecast prices, for trading period: {trading_period}.")

            except Exception as e:
                logger.error("ERROR: Failed to retrieve the forecast prices.")
                logger.error(e)
                sys.exit()
                
            # Insert the forecast price of each half-hour interval of the optimisation problem, into opt_prob_prices table
            try:
                cur.callproc(
                    "insert_prob_prices",
                    (prob_id, trading_period, price, time_of_forecast)
                )
                conn.commit()
                price_id = cur.fetchone()[0]
                logger.info(f"Successfully inserted forecast data, with the price id: {price_id}.")
                
            except Exception as e:
                logger.error("ERROR: Failed to insert the forecast data.")
                logger.error(e)
                sys.exit()
                
        # Generate & return a run id, to pass to the solver downstream
        return {
            "run_id": str(uuid4())
        }