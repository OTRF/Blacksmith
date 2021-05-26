#!/usr/bin/env python3

# Author: Roberto Rodriguez (@Cyb3rWard0g)
# License: GPL-3.0
# References:
# https://github.com/Azure/Azure-Sentinel/blob/master/DataConnectors/CEF/cef_troubleshoot.py
# https://real-world-systems.com/docs/logger.1.html

import subprocess
import sys
import os
import argparse
import logging
import glob
import yaml
from datetime import datetime
#from dateutil import tz

# Bannner
print(r"""
_________  ______________________                                 
\_   ___ \ \_   _____/\_   _____/                                 
/    \  \/  |    __)_  |    __)                                   
\     \____ |        \ |     \                                    
 \______  //_______  / \___  /                                    
        \/         \/      \/                                     
                                                                  
  _________.__                 .__            __                  
 /   _____/|__|  _____   __ __ |  |  _____  _/  |_  ____ _______  
 \_____  \ |  | /     \ |  |  \|  |  \__  \ \   __\/  _ \\_  __ \ 
 /        \|  ||  Y Y  \|  |  /|  |__ / __ \_|  | (  <_> )|  | \/ 
/_______  /|__||__|_|  /|____/ |____/(____  /|__|  \____/ |__|   V0.1
 
 Creator: Roberto Rodriguez @Cyb3rWard0g
 License: GPL-3.0
 """)

# Initial description
text = "This script allows you to send CEF message directly to a CEF server to simulate security events and alerts"
example_text = f'''example:

 python3 {sys.argv[0]}
 python3 {sys.argv[0]} -s 127.0.0.1
 python3 {sys.argv[0]} -s 127.0.0.1 -p 514
 python3 {sys.argv[0]} -s 127.0.0.1 -p 514 -e test/rdpAlert.yaml
 python3 {sys.argv[0]} -s 127.0.0.1 -p 514 -e test/
 python3 {sys.argv[0]} -s 127.0.0.1 -p 514 -e test/ -r cef_replace.yaml
 python3 {sys.argv[0]} -s 127.0.0.1 -p 514 -e test/ -r cef_replace.yaml --debug
 '''
# Initiate the parser
parser = argparse.ArgumentParser(description=text,epilog=example_text,formatter_class=argparse.RawDescriptionHelpFormatter)

# Add arguments (store_true means no argument needed)
parser.add_argument("-s", "--cef-server", help="Name or Ip address of the CEF Server", type=str , required=False)
parser.add_argument("-p", "--cef-port", help="Port number to connect to the CEF server", type=str , required=False)
parser.add_argument("-e", "--event-sample", help="Path to the yaml file that contains the CEF event or directory", type=str , required=False)
parser.add_argument("-r", "--replace-values", help="Path to the yaml file with key:value pairs to replace values in the CEF message", type=str , required=False)
parser.add_argument("-d", "--debug", help="Print lots of debugging statements", action="store_const", dest="loglevel", const=logging.DEBUG, default=logging.WARNING)

args = parser.parse_args()

logging.basicConfig(level=args.loglevel, format='%(asctime)s %(message)s', datefmt='%m/%d/%Y %I:%M:%S %p', filename="cef_simulator_debug.log")
log = logging.getLogger(__name__)

# Log all exceptions
def my_excepthook(excType, excValue, traceback, logger=log):
    logger.error("Logging an uncaught exception",exc_info=(excType, excValue, traceback))
sys.excepthook = my_excepthook

log.debug("-----------------------")
if args.cef_server:
    CEFSERVER = args.cef_server
else:
    CEFSERVER = "127.0.0.1"
if args.cef_port:
    CEFPORT = args.cef_port
else:
    CEFPORT = "514"
if args.event_sample:
    log.debug(f'Parsing a custom sample event..')
    EVENTSAMPLE = os.path.abspath(args.event_sample)
    if (os.path.isdir(EVENTSAMPLE)):
        EVENTSAMPLE =  glob.glob("{}\*.yaml".format(EVENTSAMPLE))
    else:
        EVENTSAMPLE =  glob.glob(EVENTSAMPLE)
    # Read Yaml Files
    log.debug("Reading CEF event samples..")
    samples_loaded = [yaml.safe_load(open(sample).read()) for sample in EVENTSAMPLE]
else:
    log.debug(f'Parsing a default sample event..')
    samples_loaded = []
    sample_event = dict()
    sample_event['name'] = "Default Sample"
    sample_event['priority'] = dict()
    sample_event['priority']['facility'] = 'local4'
    sample_event['priority']['level'] = 'warn'
    # Reference: https://github.com/Azure/Azure-Sentinel/blob/master/DataConnectors/CEF/cef_troubleshoot.py#L86
    sample_event['event'] = "0|TestCommonEventFormat|MOCK|common=event-format-test|end|TRAFFIC|1|rt=$common=event-formatted-receive_time deviceExternalId=0002D01655 src=1.1.1.1 dst=2.2.2.2 sourceTranslatedAddress=1.1.1.1 destinationTranslatedAddress=3.3.3.3 cs1Label=Rule cs1=CEF_TEST_InternetDNS "
    samples_loaded.append(sample_event)
if args.replace_values:
    log.debug(f'Parsing replace file..')
    REPLACEFILE = os.path.abspath(args.replace_values)
    REPLACEVALUES = yaml.safe_load(open(REPLACEFILE).read())
    log.debug(f'Values to replace: {REPLACEVALUES}')

print("-----------------------")
print(f"CEF Server: {CEFSERVER}")
print(f"CEF Port: {CEFPORT}")
print("-----------------------")
log.debug(f"CEF Server: {CEFSERVER}")
log.debug(f"CEF Port: {CEFPORT}")
log.debug("-----------------------")
# Loop over every single message
for sl in samples_loaded:
    print(f"Sending event: {sl['name']}")
    log.debug(f"Sending event: {sl['name']}")
    message_to_send = sl['event'] + "|data" + str(1) + "=example"
    # Replace values
    if args.replace_values:
        # Update datetime
        #current_time = datetime.now().astimezone(tz=tz.UTC).strftime("%b %d %Y %H:%M:%S %Z")
        current_time = datetime.now().strftime("%b %d %Y %H:%M:%S %Z")
        log.debug(f"Setting current datetime: {current_time}..")
        message_to_send = message_to_send.replace('DATETIME', current_time)
        for k, v in REPLACEVALUES.items():
            log.debug(f"Replacing value {k} with {v}")
            message_to_send = message_to_send.replace(k, v)
    log.debug(f"Sending the following message: {message_to_send}..")
    command_tokens = ["logger", "-p", f"{sl['priority']['facility']}.{sl['priority']['level']}", "-t", "CEF:", message_to_send, "-P", str(CEFPORT), "-n", f"{CEFSERVER}"]
    log.debug(f"Executing the following command: {command_tokens}..")
    logger = subprocess.Popen(command_tokens, stdout=subprocess.PIPE)
    o, e = logger.communicate()
    if e is not None:
        log.debug("Error could not send cef sample message")
        print("Error could not send cef sample message")