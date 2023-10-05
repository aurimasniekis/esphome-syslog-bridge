# ESPHome Syslog Bridge

ESPHome Syslog Bridge is a lightweight tool that forwards ESPHome log events to a remote syslog server. The tool, packaged in a Docker container, doesn't have any language dependencies, making it simple and easy to use.

## Installation

Pull the Docker image by running:

```shell
docker pull aurimasniekis/esphome-syslog-bridge
```

## Usage

Execute the Docker run command with the necessary parameters:

```shell
docker run -it aurimasniekis/esphome-syslog-bridge --syslog-address=ADDRESS --esphome-url=URL [OPTIONS]
```

### Parameters & Options

| Parameter Name      | Default Value                | Description                                                       |
|---------------------|------------------------------|-------------------------------------------------------------------|
| `--syslog-address`  | N/A                          | Specifies the IP address or hostname of the remote syslog server. |
| `--esphome-url`     | http://esphome.local/events  | Specifies the URL of the ESPHome event stream.                    |
| `--syslog-port`     | 514                          | Defines the syslog server port.                                   |
| `--syslog-udp`      |                              | Sets the syslog to use UDP.                                       |
| `--syslog-tcp`      |                              | Sets the syslog to use TCP.                                       |
| `--syslog-facility` | user                         | Specifies the syslog facility.                                    |
| `--syslog-tag`      | esphome                      | Assigns a tag to each syslog entry.                               |
| `--syslog-rfc3164`  | RFC 5424                     | Sets the syslog standard to RFC 3164.                             |
| `--syslog-rfc5424`  | RFC 5424                     | Sets the syslog standard to RFC 5424.                             |
| `-h, --help`        |                              | Displays the help message.                                        |

### Example Usage

```shell
docker run -it esphome-syslog-bridge --syslog-address=192.168.1.1 --esphome-url=http://esphome.local/events
```

This command sends the events from an ESPHome appliance located at "http://esphome.local/events" to a syslog server at IP address "192.168.1.1", using all the other parameters in their default configuration.

## Syslog Message

For instance, if an ESPHome device logged a temperature sensor reading, the parsed logMessage may resemble the following:

```json
{
  "source": "http://esphome.local/events",
  "level": "INFO",
  "name": "temperature_sensor",
  "parsed_message": "Temp Sensor Reading: 25.3 degrees",
  "message": "[I][temperature_sensor]: Temp Sensor Reading: 25.3 degrees"
}
```

Below is an explanation of the fields in this message:

| Field            | Description                                                                                                                     |
|------------------|---------------------------------------------------------------------------------------------------------------------------------|
| `source`         | The URL of the ESPHome event stream that generated this log entry.                                                              |
| `level`          | The log level of the message. Possible values include "INFO", "WARNING", "ERROR", "DEBUG", "CONFIG", "VERBOSE", "VERY_VERBOSE". |
| `name`           | The name of the service or device that produced the log - in this case, the temperature sensor.                                 |
| `parsed_message` | The log message after it has been parsed and processed.                                                                         |
| `message`        | The original, raw log message received from the ESPHome device.                                                                 |


This tool processes the ESPHome device's logs, extracting the key data and formatting it in this structured, readable JSON format before sending it along to your chosen syslog server.

## Feedback

We welcome any feedback or inquiries to improve the tool. Please feel free to contact us.

## Contributions

We appreciate and encourage contributions from the community. If you'd like to help improve the tool, please feel free to submit pull requests.

## License

This project is licensed under the [MIT License](LICENSE.md).
