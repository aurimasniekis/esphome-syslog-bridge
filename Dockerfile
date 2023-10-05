# Use an official lightweight Alpine image as a parent image
FROM alpine:latest

LABEL maintainer="Aurimas Niekis <aurimas@niekis.lt>"

# Install bash, curl, jq, sed, and logger
RUN apk --no-cache add bash curl jq sed logger

# Copy the shell script into the container
COPY esphome-syslog-bridge.sh /usr/local/bin/esphome-syslog-bridge

# Make the script executable
RUN chmod +x /usr/local/bin/esphome-syslog-bridge

# Set the script as the default thing to run when the container starts
ENTRYPOINT ["/usr/local/bin/esphome-syslog-bridge"]
