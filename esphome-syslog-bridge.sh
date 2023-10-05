#!/bin/bash

# Function to display help message
print_help() {
    echo "Usage: $0 [OPTIONS]"
    echo "Send ESPHome logs to a remote syslog server."
    echo ""
    echo "Options:"
    echo "  --syslog-address=ADDRESS    Address of the remote syslog server."
    echo "  --syslog-port=PORT          Port of the remote syslog server (default: 514)."
    echo "  --syslog-udp                Use UDP for syslog (default: TCP)."
    echo "  --syslog-tcp                Use TCP for syslog."
    echo "  --syslog-facility=FACILITY  Syslog facility (default: user)."
    echo "  --syslog-tag=TAG            Syslog tag (default: esphome)."
    echo "  --syslog-rfc3164            Use RFC 3164 syslog standard."
    echo "  --syslog-rfc5424            Use RFC 5424 syslog standard (default)."
    echo "  --esphome-url=URL           URL of the ESPHome event stream."
    echo "  -h, --help                  Display this help message and exit."
    echo ""
    echo "Example:"
    echo "  $0 --syslog-address=192.168.1.1 --esphome-url=http://esphome.local/events"
}

# Default values
SYSLOG_PORT=514
SYSLOG_PROTOCOL="tcp"
SYSLOG_FACILITY="user"
SYSLOG_TAG="esphome"
SYSLOG_STANDARD="rfc5424"

if [ "$#" -eq 0 ] || [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]]; then
    print_help
    exit 0
fi

# Parse command-line arguments
while [ "$#" -gt 0 ]; do
    case "$1" in
        --syslog-address=*) SYSLOG_ADDRESS="${1#*=}" ;;
        --syslog-port=*) SYSLOG_PORT="${1#*=}" ;;
        --syslog-udp) SYSLOG_PROTOCOL="udp" ;;
        --syslog-tcp) SYSLOG_PROTOCOL="tcp" ;;
        --syslog-facility=*) SYSLOG_FACILITY="${1#*=}" ;;
        --syslog-tag=*) SYSLOG_TAG="${1#*=}" ;;
        --syslog-rfc3164) SYSLOG_STANDARD="rfc3164" ;;
        --syslog-rfc5424) SYSLOG_STANDARD="rfc5424" ;;
        --esphome-url=*) ESPHOME_URL="${1#*=}" ;;
        *) echo "Unknown parameter passed: $1"; exit 1 ;;
    esac
    shift
done

# Validate required parameters
if [ -z "$SYSLOG_ADDRESS" ] || [ -z "$ESPHOME_URL" ]; then
    echo "$0: --syslog-address=127.0.0.1 and --esphome-url=http://127.0.0.1/events are required"
    exit 1
fi

#echo "$SYSLOG_ADDRESS"
#echo "$ESPHOME_URL"

# Fetch and process the event stream
curl -N -s "$ESPHOME_URL" | while IFS= read -r line; do
    line="${line//$'\r'/}"

    # Check if the line contains 'event: log'
    if [[ "$line" == "event: log" ]]; then
        # Read the next line (data line)
        IFS= read -r data_line

        data_line="${data_line//$'\r'/}"

#        printf 'Data line "%q"\n' "$data_line"

        # Remove 'data: ' prefix and ANSI color codes
#        cleanLine=$(echo "$data_line" | awk '{ sub(/^data: /, ""); gsub(/\033\[([01];)?([0-9]{2}|5|6)m/, ""); print $0 }')
        cleanLine=$(echo "$data_line" | awk '{ sub(/^data: /, ""); gsub(/\033\[[0-9;]*m/, ""); print $0 }')



#        printf 'Clean line "%q"\n' "$cleanLine"

        levelLetter=$(echo "$cleanLine" | sed -n 's/^\[\([A-Z]\)\].*$/\1/p')
        name=$(echo "$cleanLine" | sed -n 's/^\[[A-Z]\]\[\([^]]*\)\].*$/\1/p')
        message=$(echo "$cleanLine" | sed -n 's/^\[[A-Z]\]\[[^]]*\]:[[:space:]]*\(.*\)$/\1/p')

        levelName="NONE"
        syslogLevel="notice"
        case "$levelLetter" in
            "E")
                levelName="ERROR"
        syslogLevel="err"
                ;;
            "W")
                levelName="WARNING"
        syslogLevel="warning"
                ;;
            "I")
                levelName="INFO"
        syslogLevel="info"
                ;;
            "C")
                levelName="CONFIG"
        syslogLevel="notice"
                ;;
            "D")
                levelName="DEBUG"
        syslogLevel="debug"
                ;;
            "V")
                levelName="VERBOSE"
        syslogLevel="debug"
                ;;
            "VV")
                levelName="VERY_VERBOSE"
        syslogLevel="debug"
                ;;
        esac

        logMessage=$(jq -cn \
                  --arg url "$ESPHOME_URL" \
                  --arg lvl "$levelName" \
                  --arg nm "$name" \
                  --arg msg "$message" \
                  --arg rawMsg "$cleanLine" \
                  '{source: $url, level: $lvl, name: $nm, parsed_message: $msg, message: $rawMsg}')


        # Build the logger command
        logger_command="logger -n $SYSLOG_ADDRESS -P $SYSLOG_PORT -T -d"

        # Add optional parameters
        [ "$SYSLOG_PROTOCOL" == "udp" ] && logger_command+=" -u"
        [ -n "$SYSLOG_FACILITY" ] && logger_command+=" -p $SYSLOG_FACILITY.$syslogLevel"
        [ -n "$SYSLOG_TAG" ] && logger_command+=" -t $SYSLOG_TAG"
        [ "$SYSLOG_STANDARD" == "rfc5424" ] && logger_command+=" --rfc5424"
        [ "$SYSLOG_STANDARD" == "rfc3164" ] && logger_command+=" --rfc3164"

        $logger_command "$logMessage"
    fi
done
