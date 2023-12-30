FROM public.ecr.aws/lambda/provided:al2023

ENV USER_NAME="postgres"
ENV PASSWORD=">%7T&]pq8WNG9%3s"
ENV RDS_HOST="db-instance.caseq5rlslmk.us-east-1.rds.amazonaws.com"
ENV DB_NAME="db1"

RUN dnf install -y python3

RUN dnf install -y gcc

# Copy requirements.txt
COPY requirements.txt ${LAMBDA_TASK_ROOT}

# Install the specified packages
RUN pip install -r requirements.txt

RUN pip install awslambdaric

COPY lambda_function.py ${LAMBDA_TASK_ROOT}

COPY Deterministic_Optimizer.py ${LAMBDA_TASK_ROOT}
COPY PostgresDBInteraction.py ${LAMBDA_TASK_ROOT}

COPY ./entry_script.sh /entry_script.sh
RUN chmod +x /entry_script.sh
ADD aws-lambda-rie /usr/local/bin/aws-lambda-rie

ENTRYPOINT [ "/entry_script.sh","lambda_function.handler" ]


# Copy function code


# Set the CMD to your handler (could also be done as a parameter override outside of the Dockerfile)
#CMD [ "lambda_function.handler" ]