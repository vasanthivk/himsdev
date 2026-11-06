FROM python:3.12-slim
WORKDIR /app
RUN pip install --no-cache-dir "pyjwt[crypto]==2.10.1"
COPY validator.py .
USER nobody
EXPOSE 8000
CMD ["python", "validator.py"]
