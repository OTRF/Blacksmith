# /*****************************************************************************
# * Copyright (c) 2016, Palo Alto Networks. All rights reserved.              *
# *                                                                           *
# * This Software is the property of Palo Alto Networks. The Software and all *
# * accompanying documentation are copyrighted.                               *
# *****************************************************************************/
#
# Copyright 2016 Palo Alto Networks
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


import time
import shlex
import subprocess
import os
import logging
import urllib2
import socket
from socket import gethostname, gethostbyname
import sys
import ssl
import xml.etree.ElementTree as et
import threading

LOG_FILENAME = 'azure.log'
logging.basicConfig(filename=LOG_FILENAME,level=logging.INFO, filemode='w',format='[%(levelname)s] (%(threadName)-10s) %(message)s',)
logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)

MgmtIp = sys.argv[2]

#The api key is pre-generated for user and password combination defined in the ARM template
api_key = sys.argv[1]

#Need this to by pass invalid certificate issue. Should try to fix this
gcontext = ssl.SSLContext(ssl.PROTOCOL_TLSv1_2)

#baseStorageAccountName = ""
config_file_name = "azure-sample.xml"
curl_string = 'curl --form file=@%s --insecure "https://%s/api/?type=import&category=configuration&file-name=%s&key=%s"' % (config_file_name, MgmtIp, config_file_name, api_key)

def main():
    t1 = threading.Thread(name='config_fw',target=config_fw)
    t1.start()

def config_fw():
    global api_key
    global MgmtIp

    #This means firewall already configured..so exit script.
    if os.path.exists("./firewall_configured") == True:
        logger.info("[INFO]: FW already configured. auf wiedersehen!")
        return 'true'

    err = 'no'
    while (True):
        err = check_auto_commit_status()
        if err == 'yes':
            break
        else:
          time.sleep(10)
          continue

    while (True):
        err = check_fw_up()
        if err == 'yes':
            break
        else:
            time.sleep(10)
            continue

    #Load default outbound allow https/https config to fw
    #if(send_command('initial_config') == 'false'):
    #    logger.info("[ERROR]: Adding initial config failed")
    #    return 'false'
    #else:
    #    logger.info("[INFO]: Adding initial config success")


    #i = 0
    #while(i<5):
    #    err = send_command('commit')
    #    if(err == 'false'):
    #        logger.info("[ERROR]: Initial Commit error")
    #        return 'false'
    #    elif (err == 'try_commit_again'):
    #         logger.info("[INFO]: Trying initial commit again")
    #         i+=1
    #         time.sleep(15)
    #         continue
    #    else:
    #        logger.info("[INFO]: Initial Commit successful")
    #        break

    # XML Config is download via the ARM Template

    if (send_command('import_config') == 'false'):
        logger.info("[ERROR]: Import config error")
        return 'false'
    else:
        logger.info("[INFO]: Import config success")


    if (send_command('load_config') == 'false'):
        logger.info("[ERROR]: Load config error")
        return 'false'
    else:
        logger.info("[INFO]: Load config success")

    i = 0
    while(i<5):
        err = send_command('commit')
        if(err == 'false'):
            logger.info("[ERROR]: Commit error")
            return 'false'
        elif (err == 'try_commit_again'):
             logger.info("[INFO]: Trying commit again")
             i+=1
             time.sleep(15)
             continue
        else:
            logger.info("[INFO]: Commit successful")
            break

    if(send_command('download') == 'false'):
        logger.info("[ERROR]: Download content error")
        return 'false'
    else:
        logger.info("[INFO]: Download content success")


    if(send_command('install') == 'false'):
        logger.info("[ERROR]: Install content error")
        return 'false'
    else:
        logger.info("[INFO]: Install content success")


    logger.info("[INFO]: Firewall configured")
    #Create a marker file that shows firewall is already configured so we don't run this script again.
    open("./firewall_configured", "w").close()
    return 'true'

def send_command(cmd):
    global MgmtIp
    global api_key
    global curl_string

    job_id = ""
    if (cmd == 'commit'):
        cmd_string = "https://"+MgmtIp+"/api/?type=commit&cmd=<commit></commit>&key="+api_key
    elif (cmd == 'import_config'):
        p = subprocess.Popen(shlex.split(curl_string), stdout=subprocess.PIPE)
        resp_header = et.fromstring(p.communicate()[0])
        if resp_header.tag != 'response':
            logger.info("[ERROR]: didn't get a valid response from firewall")
            return 'false'

        if resp_header.attrib['status'] == 'error':
            logger.info("[ERROR]: Got an error for the command")
            return 'false'

        if resp_header.attrib['status'] == 'success':
            #The fw responded with a successful command execution. No need to check what the actual response is
            logger.info("[INFO]: Successfully executed command")
            return 'true'
    elif (cmd == 'load_config'):
        cmd_string = "https://"+MgmtIp+"/api/?type=op&cmd=<load><config><from>"+config_file_name+"</from></config></load>&key="+api_key
    elif (cmd == 'download'):
        cmd_string =  "https://"+MgmtIp+"/api/?type=op&cmd=<request><content><upgrade><download><latest></latest></download></upgrade></content></request>&key="+api_key
    elif (cmd == 'install'):
        cmd_string = "https://"+MgmtIp+"/api/?type=op&cmd=<request><content><upgrade><install><version>latest</version></install></upgrade></content></request>&key="+api_key
    elif(cmd == 'initial_config'):
        cmd_string = "https://"+MgmtIp+"/api/?type=config&action=set&xpath=/config/devices/entry[@name='localhost.localdomain']/vsys/entry[@name='vsys1']/rulebase/security/rules/entry[@name='init_allow_all']&element=<source><member>any</member></source><destination><member>any</member></destination><service><member>service-https</member></service><action>allow</action><log-start>yes</log-start><from><member>any</member></from><to><member>any</member></to><application><member>any</member></application>&key="+api_key
    else:
        logger.info("[ERROR]: Unknown command")
        return 'false'

    logger.info('[INFO]: Sending command: %s', cmd_string)
    try:
        response = urllib2.urlopen(cmd_string, context=gcontext, timeout=5).read()
        #response = urllib2.urlopen(cmd_string,  timeout=20).read()
        logger.info("[RESPONSE] in send command: {}".format(response))
    except Exception as e:
        logger.info("[ERROR]: Something bad happened when sending command:{}".format(e))
        return  'false'
    else:
        logger.info("[INFO]: Got a (good?) response from command")

    resp_header = et.fromstring(response)
    if resp_header.tag != 'response':
        logger.info("[ERROR]: didn't get a valid response from firewall")
        return 'false'

    if resp_header.attrib['status'] == 'error':
        logger.info("[ERROR]: Got an error for the command")
        if (cmd == 'commit'):
            #Not all daemons avaialble error, then try again
            for element in resp_header:
                for iterator in element:
                    err = iterator.text
                    if ("All daemons are not available." in err):
                        return 'try_commit_again'
                    else:
                        return 'false'
        else:
            return 'false'

    elif resp_header.attrib['status'] == 'success':
    #The fw responded with a successful command execution. No need to check what the actual response is
        logger.info("[INFO]: Successfully executed command")

        if(cmd == 'commit' or cmd == 'download' or cmd == 'install'):
            for element in resp_header:
                for iterator in element:
                    if iterator.tag == 'job':
                        job_id = iterator.text
                        if job_id == None:
                            logger.info("[ERROR]: Didn't get a job id")
                            return 'false'
                        else:
                            break #break out of inner loop
                    else:
                        continue
                break #break out of outer loop
            job_status = 'false'
            while (True):
                job_status = check_job_status(job_id)
                if (job_status == 'true'):
                    logger.info("[INFO]: Job ID "+job_id+" completed successfully")
                    return 'true'
                elif (job_status == 'pending'):
                    logger.info("[INFO]: Job ID "+job_id+" pending")
                    time.sleep(30)
                    continue
                else:
                    logger.info("[ERROR]: Job ID "+job_id+" status check failed")
                    return 'false'
        else:
            return 'true'

def check_fw_up():
    global gcontext
    global MgmtIp
    global api_key
    cmd = "https://"+MgmtIp+"/api/?type=op&cmd=<show><chassis-ready></chassis-ready></show>&key="+api_key
    #Send command to fw and see if it times out or we get a response
    logger.info('[INFO]: Sending command: %s', cmd)
    try:
        response = urllib2.urlopen(cmd, context=gcontext, timeout=5).read()
        #response = urllib2.urlopen(cmd, timeout=5).read()
    except Exception as e:
        logger.info("[INFO]: No response from FW. So maybe not up! {}".format(e))
        return 'no'
    else:
        logger.info("[INFO]: FW is up!!")

    logger.info("[RESPONSE]: {}".format(response))
    resp_header = et.fromstring(response)

    if resp_header.tag != 'response':
        logger.info("[ERROR]: didn't get a valid response from firewall...maybe a timeout")
        return 'cmd_error'

    if resp_header.attrib['status'] == 'error':
        logger.info("[ERROR]: Got an error for the command")
        return 'cmd_error'

    if resp_header.attrib['status'] == 'success':
    #The fw responded with a successful command execution. So is it ready?
        for element in resp_header:
            if element.text.rstrip() == 'yes':
                logger.info("[INFO]: FW is ready for configure")
                return 'yes'
            else:
                return 'almost'

def check_auto_commit_status():
    global gcontext
    global MgmtIp
    global api_key

    job_id = '1' #auto commit job id is always 1
    cmd = "https://"+MgmtIp+"/api/?type=op&cmd=<show><jobs><id>"+job_id+"</id></jobs></show>&key="+api_key
    #Send command to fw and see if it times out or we get a response
    logger.info('[INFO]: Sending command: %s', cmd)
    try:
        response = urllib2.urlopen(cmd, context=gcontext, timeout=5).read()
        #response = urllib2.urlopen(cmd,  timeout=5).read()
    except Exception as e:
        logger.info("[INFO]: No response from FW. So maybe not up! {}".format(e))
        return 'no'
    else:
        logger.info("[INFO]: FW is up!!")

    logger.info("[RESPONSE]: {}".format(response))
    resp_header = et.fromstring(response)

    if resp_header.tag != 'response':
        logger.info("[ERROR]: didn't get a valid response from firewall...maybe a timeout")
        return 'cmd_error'

    if resp_header.attrib['status'] == 'error':
        logger.info("[ERROR]: Got an error for the command")
        for element1 in resp_header:
            for element2 in element1:
                if element2.text == "job 1 not found":
                    logger.info("[INFO]: Job 1 not found...so try again")
                    return 'almost'
                elif "Invalid credentials" in element2.text:
                    logger.info("[INFO]:Invalid credentials...so try again")
                    return 'almost'
                else:
                    logger.info("[ERROR]: Some other error when checking auto commit status")
                    return 'cmd_error'

    if resp_header.attrib['status'] == 'success':
    #The fw responded with a successful command execution. So is it ready?
        for element1 in resp_header:
            for element2 in element1:
                for element3 in element2:
                    if element3.tag == 'status':
                        if element3.text == 'FIN':
                            logger.info("[INFO]: FW is ready for configure")
                            return 'yes'
                        else:
                            return 'almost'


def check_job_status(job_id):

    global gcontext
    global MgmtIp
    global api_key

    cmd = "https://"+MgmtIp+"/api/?type=op&cmd=<show><jobs><id>"+job_id+"</id></jobs></show>&key="+api_key
    logger.info('[INFO]: Sending command: %s', cmd)
    try:
        response = urllib2.urlopen(cmd, context=gcontext, timeout=5).read()
        #response = urllib2.urlopen(cmd,  timeout=5).read()
    except Exception as e:
        logger.info("[ERROR]: ERROR...fw should be up!! {}".format(e))
        return 'false'

    logger.info("[RESPONSE]: {}".format(response))
    resp_header = et.fromstring(response)

    if resp_header.tag != 'response':
        logger.info("[ERROR]: didn't get a valid response from firewall...maybe a timeout")
        return 'false'

    if resp_header.attrib['status'] == 'error':
        logger.info("[ERROR]: Got an error for the command")
        for element1 in resp_header:
            for element2 in element1:
                if element2.text == "job "+job_id+" not found":
                    logger.info("[ERROR]: Job "+job_id+" not found...so try again")
                    return 'false'
                elif "Invalid credentials" in element2.text:
                    logger.info("[ERROR]:Invalid credentials...")
                    return 'false'
                else:
                    logger.info("[ERROR]: Some other error when checking auto commit status")
                    return 'false'

    if resp_header.attrib['status'] == 'success':
        for element1 in resp_header:
            for element2 in element1:
                for element3 in element2:
                    if element3.tag == 'status':
                        if element3.text == 'FIN':
                            logger.info("[INFO]: Job "+job_id+" done")
                            return 'true'
                        else:
                            return 'pending'

if __name__ == "__main__":
    main()