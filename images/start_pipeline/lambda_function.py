import os
import sys
import logging
import boto3
import json
from uuid import uuid4

# Create logger object
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Create client to trigger the step function
state_machine_arn = os.environ['STATE_MACHINE_ARN']
step_func_client = boto3.client('stepfunctions')

def lambda_handler(event, context):

    # Extract user's input data from their API call
    try:
        user_input = event['queryStringParameters']
        expected_input = ('start', 'end', 'kwh', 'kw', 'node')
        if all(key in user_input for key in expected_input):
            start_time = user_input.get('start')
            end_time = user_input.get('end')
            kwh_to_charge = float(user_input.get('kwh'))
            kw_charge_rate = float(user_input.get('kw'))
            node = user_input.get('node')
            logger.info("Successfully extracted user input data.")
        else:
            missing_keys = [key for key in expected_input if key not in user_input]
            logger.error("ERROR: Failed to extract user input data, due to incomplete API call.")
            logger.error(f"Missing data: {missing_keys}")
            # logger.error(f"Data given: pass")
            sys.exit()
            
    # except KeyError as e:
    #    pass

    except Exception as e:
        logger.error("ERROR: Failed to extract user input data.")
        logger.error(e)
        sys.exit()

    # Trigger the step function to invoke the downstream functions
    try:

        request_id = uuid4()

        input = {
            "user_request" : {
                "request_id": request_id,
                "start_time": start_time,
                "end_time": end_time,
                "kwh_to_charge": kwh_to_charge,
                "kw_charge_rate": kw_charge_rate,
                "node": node
            }
        }

        response = step_func_client.start_execution(
            stateMachineArn = state_machine_arn,
            input = json.dumps(input)
        )

        logger.info(f"Successfully triggered the step function to start the problems pipeline, for request_id: {request_id}.")
        
    except Exception as e:
        logger.error("ERROR: Failed to trigger the step function to start the problems pipeline.")
        logger.error(e)
        sys.exit()

    # Return request_id to the user
    return {
        "request_id" : uuid_to_string(request_id)
    }

def uuid_to_string(obj):
    if isinstance(obj, UUID):
        return obj.hex