import os
import sys
import logging
import boto3
import json

# create logger object
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Create client to invoke the internal lambda function
lambda_client = boto3.client('lambda')




# model's output is stored in the opt_run_decisions table

# function extracts the request_id from the result call
# from opt_run_decisions table, for the request_id, get each price_id and decision_value
# join to price_forecasts table, for each price_id, get the corresponding datetime & price




def lambda_handler(event, context):

    # Extract user's request_id from the their call to the result API
    try:
        user_input = event['queryStringParameters']
        request_id = user_input.get('id')
        ############# what if it's a list of many ids
        logger.info(f"Successfully extracted the request_id: {request_id}")

    # except KeyError as e:
    #    pass

    except Exception as e:
        logger.error("ERROR: Failed to extract user's request_id.")
        logger.error(e)
        sys.exit()

    # Invoke internal lambda function, to connect to db & extract the result for the given request_id
    try:
        payload = {"request_id": request_id}

        response_inner = lambda_client.invoke(
            FunctionName = "return_result_inner",
            InvocationType = "RequestResponse", # synchronous invocation
            Payload = json.dumps(payload)
        )
        logger.info("Successfully invoked return_result_inner function.")

    except Exception as e:
        logger.error("ERROR: Failed to invoke return_result_inner function.")
        logger.error(e)
        sys.exit()

    response_outer = response_inner['Payload'].read().decode('utf-8')
    logger.info(f"The return_result_inner function returned: {response_outer}")

    return response_outer
    # need to return a dummy answer if it's an internal error