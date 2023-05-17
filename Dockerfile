FROM python:3.9-slim-buster

# Set the working directory
WORKDIR /app

# Copy the Python script to the container
COPY measure.py .

RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y 

# Install requirements
COPY requirements.txt /tmp/requirements.txt
RUN pip install --no-cache-dir -r /tmp/requirements.txt && \
    rm -f /tmp/requirements.txt

# Expose the port 
EXPOSE 8888

# Run the Python script when the container starts
CMD ["python", "./measure.py"]
