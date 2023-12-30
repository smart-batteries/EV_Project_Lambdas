FROM public.ecr.aws/lambda/python:3.11

# Install the specified packages
RUN pip install --upgrade pip
COPY requirements.txt ${LAMBDA_TASK_ROOT}
RUN pip install -r requirements.txt

# Copy function code
COPY lambda_function.py ${LAMBDA_TASK_ROOT}

# Set the CMD to the handler
CMD ["lambda_function.lambda_handler"]