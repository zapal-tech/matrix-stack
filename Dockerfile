FROM matrixdotorg/synapse:latest

RUN apt update
RUN apt install git
RUN pip install synapse-s3-storage-provider
RUN pip install git+https://github.com/devture/matrix-synapse-shared-secret-auth
