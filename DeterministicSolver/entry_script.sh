#!/bin/sh

if [ -z "${AWS_LAMBDA_RUNTIME_API}" ]; then
  exec /usr/local/bin/aws-lambda-rie /usr/bin/python -m awslambdaric --log-level "debug" "$@"
else
  exec /usr/local/bin/python -m awslambdaric "$@"
fi