if [ "$1" = "" ]; then
 echo "Script that runs a sniffer, parser and wireshark all piped together."
 echo "Specifiy the serial port by giving the number. '0' means /dev/ttyUSB0."
 echo "The channel the sniffer operates on can also be changed by adding optional parameter (range: 11-26)"
 echo ""
 echo "Usage run_live_ws.sh <PORT> [CHANNEL] [WIRESHARK-PATH]"
 exit
fi
if [ "$2" = "" ]; then
 channel=""
else
 channel="$2"
fi
if [ "$3" = "" ]; then
 wireshark="wireshark"
else
 wireshark="$3"
fi

`stdbuf -oL $wireshark -k -i <(stdbuf -oL python -u listener.py $1 --channel=$channel | stdbuf -oL python -u pcap_parser.py)`
#stdbuf -oL ~/wireshark-1.99.7/wireshark -k -i <(stdbuf -oL python -u listener.py /dev/sniffer --channel 17 | stdbuf -oL python -u pcap_parser.py)
