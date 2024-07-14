# Set the base image to use for subsequent instructions
FROM node:lts-alpine3.20

# bash is required for entrypoint.sh
RUN apk add --no-cache bash

# Install bruno cli
RUN npm install -g @usebruno/cli@1.x

# Set the working directory inside the container
WORKDIR /usr/src

# Copy any source file(s) required for the action
COPY entrypoint.sh .

# Configure the container to be run as an executable
ENTRYPOINT ["/usr/src/entrypoint.sh"]
