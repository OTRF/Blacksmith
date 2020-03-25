#!/usr/bin/env python3

# Author: Roberto Rodriguez @Cyb3rWard0g
# License: GPLv3

# Reference:
# https://docs.microsoft.com/en-us/azure/azure-monitor/platform/data-collector-api#python-2-sample
# https://github.com/MicrosoftDocs/azure-docs/issues/22715
# https://medium.com/@philipplies/progress-bar-and-status-logging-in-python-with-tqdm-35ce29b908f5

import json
import requests
import datetime
import hashlib
import hmac
import base64
import argparse
import string
from tqdm import tqdm
from time import sleep
import os
import glob
import sys

sys.stderr.write(r"""
   _____  .____       _____    ________          __          
  /  _  \ |    |     /  _  \   \______ \ _____ _/  |______   
 /  /_\  \|    |    /  /_\  \   |    |  \\__  \\   __\__  \  
/    |    \    |___/    |    \  |    `   \/ __ \|  |  / __ \_
\____|__  /_______ \____|__  / /_______  (____  /__| (____  /
        \/        \/       \/          \/     \/          \/ 
__________                   .___                            
\______   \_______  ____   __| _/_ __   ____  ___________    
 |     ___/\_  __ \/  _ \ / __ |  |  \_/ ___\/ __ \_  __ \   
 |    |     |  | \(  <_> ) /_/ |  |  /\  \__\  ___/|  | \/   
 |____|     |__|   \____/\____ |____/  \___  >___  >__|      
                              \/           \/    \/      V0.0.1

Creator: Roberto Rodriguez @Cyb3rWard0g
License: GPL-3.0
 
""")

# Initial description
text = "This script allows you to automate the process of sending pre-recorded security events from one or multiple JSON files to a Log Analytics workspace"
example_text = f'''examples:

 python3 {sys.argv[0]} -w "xxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx" -k "xxx...xx=" -l "customTable" -f dataset.json
 python3 {sys.argv[0]} -w "xxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx" -k "xxx...xx=" -l "customTable" -f dataset.json -p 
 python3 {sys.argv[0]} -w "xxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx" -k "xxx...xx=" -l "customTable" -f folder/
 python3 {sys.argv[0]} -w "xxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx" -k "xxx...xx=" -l "customTable" -f folder/ -p
 '''

# Initiate the parser
parser = argparse.ArgumentParser(description=text,epilog=example_text,formatter_class=argparse.RawDescriptionHelpFormatter)

# Add arguments (store_true means no argument needed)
parser.add_argument("-w", "--workspace-id", help="Log Analytics Workspace ID", type=str , required=True)
parser.add_argument("-k", "--shared-key", help="Log Analytics Primary Shared Key", type=str , required=True)
parser.add_argument("-l", "--log-type", help="Log Analytics Custom Logs table name", type=str , required=True)
parser.add_argument('-f', "--file-path", nargs='+', help="Path of JSON file(s) or folder(s) of JSON files", required=True)
parser.add_argument("-p", "--pack-message", help="Packs each JSON object under a 'Message' field to avoid exceeding the max number (500) of custom fields when sending multiple datasets", action="store_true", default=False)

args = parser.parse_args()

# Initial Workspace Variables
WORKSPACE_ID = args.workspace_id
WORKSPACE_SHARED_KEY = args.shared_key
LOG_TYPE = args.log_type

# Aggregate files from Input Paths
input_paths = [os.path.abspath(path) for path in args.file_path]
all_files = []
for path in input_paths:
    if os.path.isfile(path):
        all_files.append(path)
    elif os.path.isdir(path):
        for p in glob.glob(f"{path}**/*.json", recursive=True):
            all_files.append(p) 
    else:
        quit()

# Build the API signature
def build_signature(WORKSPACE_ID, WORKSPACE_SHARED_KEY, date, content_length, method, content_type, resource):
    x_headers = 'x-ms-date:' + date
    string_to_hash = method + "\n" + str(content_length) + "\n" + content_type + "\n" + x_headers + "\n" + resource
    bytes_to_hash = bytes(string_to_hash, encoding="utf-8") 
    decoded_key = base64.b64decode(WORKSPACE_SHARED_KEY)
    encoded_hash = base64.b64encode(hmac.new(decoded_key, bytes_to_hash, digestmod=hashlib.sha256).digest()).decode()
    authorization = f"SharedKey {WORKSPACE_ID}:{encoded_hash}"
    return authorization

# Build and send a request to the POST API
def post_data(WORKSPACE_ID, WORKSPACE_SHARED_KEY, body, LOG_TYPE):
    method = 'POST'
    content_type = 'application/json'
    resource = '/api/logs'
    rfc1123date = datetime.datetime.utcnow().strftime('%a, %d %b %Y %H:%M:%S GMT')
    content_length = len(body)
    signature = build_signature(WORKSPACE_ID, WORKSPACE_SHARED_KEY, rfc1123date, content_length, method, content_type, resource)
    uri = 'https://' + WORKSPACE_ID + '.ods.opinsights.azure.com' + resource + '?api-version=2016-04-01'

    headers = {
        'content-type': content_type,
        'Authorization': signature,
        'Log-Type': LOG_TYPE,
        'x-ms-date': rfc1123date
    }
    response = requests.post(uri,data=body, headers=headers)
    if (response.status_code >= 200 and response.status_code <= 299):
        return True
    else:
        print(f'Response code: {response.status_code}')

# Initializing outer progress bar and file POST response
outer = tqdm(total=len(all_files), desc='Files', position=0)

# Proces all JSON File(s)
for dataset in all_files:
    json_records = []
    json_current_size = 0
    
    # Initialize file reader progress bar
    total_file_size = os.path.getsize(f"{dataset}")
    t = tqdm(
        total=total_file_size,
        unit='B',
        desc=f"Processing {os.path.basename(dataset)} ...",
        unit_scale=True,
        unit_divisor=1024,
        position=1
    )

    # Read each JSON object from file in binary format 
    for line in open(f"{dataset}", 'rb'):
        # Update progress bar with current bytes size
        t.update(len(line))
        sleep(0.01)
        
        # If you want to pack each JSON object under field name Message
        if args.pack_message:
            message = dict()
            message_string = json.dumps(json.loads(line.decode('utf-8')))
            message['message'] = message_string
        else:
            message = json.loads(line.decode('utf-8'))
        
        # Maximum of 30 MB per post to Azure Monitor Data Collector API
        if (json_current_size + len(line)) < 31457280:
            json_records.append(message)
            json_current_size += len(line)
        else:
            body = json.dumps(json_records)
            post_data(WORKSPACE_ID, WORKSPACE_SHARED_KEY, body, LOG_TYPE)
            # Reset JSON records list internally on each POST request while still reading file
            json_records = []
            json_current_size = 0
        
        # If you get to read the whole file without reaching the 30MB limit per post
        if json_current_size == total_file_size:
            body = json.dumps(json_records)
            post_data(WORKSPACE_ID, WORKSPACE_SHARED_KEY, body, LOG_TYPE)
    t.close()
    outer.update(1)