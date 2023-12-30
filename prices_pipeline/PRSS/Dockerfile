FROM public.ecr.aws/lambda/python:3.11

# Install requirements
COPY requirements.txt ${LAMBDA_TASK_ROOT}
RUN pip3 install -r requirements.txt

# Copy function code
COPY lambda_function.py ${LAMBDA_TASK_ROOT}

# Set the CMD to the handler
CMD ["lambda_function.lambda_handler"]