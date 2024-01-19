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
    logging.info("Successfully connected to PostgreSQL.")
    
except (Exception, psycopg2.Error) as e:
    logger.error("ERROR: Failed to connect to PostgreSQL.")
    logger.error(e)
    sys.exit()


def lambda_handler(event, context):

    
'''


# model's output is stored in the opt_run_decisions table

# user sends the run_id to the api gateway
# function is invoked
# from opt_run_decisions table, for the run_id, get each price_id and decision_value
# join to price_forecasts table, for each price_id, get the corresponding datetime & price



    prob_id = event['prob_id']
    
    with conn.cursor() as cur:

        # Retrieve the start & end times that define the time window
        try:
            cur.callproc("extract_time_window", [prob_id])
            window = cur.fetchone()
            start_time, end_time, node = window
            logger.info(f"Successfully retrieved the time window, from {start_time} to {end_time}, for node {node}.")

        except Exception as e:
            logger.error("ERROR: Failed to retrieve the start & end times of the time window.")
            logger.error(e)
            sys.exit()
        
        # Extract the price forecasts, for each half-hour interval of the time window for that node, from elec_prices table
        try:
            cur.callproc("extract_prob_prices", [start_time, end_time, node])
            forecast_data = cur.fetchall()
            start_period = min(forecast_data, key = lambda x: x[0])[0]
            end_period = max(forecast_data, key = lambda x: x[0])[0]
            logger.info(f"Successfully extracted the price forecasts, from trading periods {start_period} to {end_period}.")

        except Exception as e:
            logger.error("ERROR: Failed to extract the trading periods for the time window.")
            logger.error(e)
            sys.exit()
        
        for forecast in forecast_data:
                
            # Insert the price forecasts of each half-hour interval of the optimisation problem, into opt_prob_prices table
            try:
                trading_period = forecast[0]
                price = forecast[2]
                time_of_forecast = forecast[3]
                cur.callproc(
                    "insert_prob_prices",
                    (prob_id, trading_period, price, time_of_forecast)
                )
                conn.commit()
                price_id = cur.fetchone()[0]
                logger.info(f"Successfully inserted forecast data, with price id {price_id} for trading period {trading_period}.")
                
            except Exception as e:
                logger.error("ERROR: Failed to insert the forecast data.")
                logger.error(e)
                sys.exit()
                
        # Generate & return a run id, to pass to the solver downstream
        return {
            "run_id": str(uuid4())
        }


'''