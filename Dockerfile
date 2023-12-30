FROM python:3.9

ADD main.py .
RUN pip install mip
RUN pip install psycopg2
CMD ["python", "./main.py"]