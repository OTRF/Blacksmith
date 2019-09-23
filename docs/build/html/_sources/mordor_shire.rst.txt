Shire CloudFormation Deployment
===============================

Pre-Deployment
##############

First, make sure you **git clone** the main repo:

.. code-block:: console

    $ git clone https://github.com/Cyb3rWard0g/Blacksmith
    $ cd Blacksmith/aws/mordor/shire


Automatic Deployment
####################

You will just have to run the script named **deploy-mordor-shire.sh** in the same directory as the CloudFormation templates.

.. code-block:: console

    $ ./deploy-mordor-shire.sh

    [MORDOR-CLOUDFORMATION-INFO] Creating MordorNetworkStack ..
    
    {
        "StackId": "arn:aws:cloudformation:us-east-1:xxxxxxxxxxxxxx:stack/MordorNetworkStack/43fbb620-ddcb-11e9-8e4d-0eff07caa3c6"
    }
    
    [MORDOR-CLOUDFORMATION-INFO] EC2 Network stack template has been sent over to AWS and it is being processed remotely ..
    [MORDOR-CLOUDFORMATION-INFO] All other instances depend on it.
    [MORDOR-CLOUDFORMATION-INFO] Waiting for MordorNetworkStack to be created..
    
    
    [MORDOR-CLOUDFORMATION-INFO] MordorNetworkStack was created.
    [MORDOR-CLOUDFORMATION-INFO] Creating MordorHELKStack ..
    
    {
        "StackId": "arn:aws:cloudformation:us-east-1:xxxxxxxxxxxxxx:stack/MordorHELKStack/69987710-ddcb-11e9-aab3-0e0ed2de56d2"
    }
    
    [MORDOR-CLOUDFORMATION-INFO] HELK stack template has been sent over to AWS and it is being processed remotely ..
    [MORDOR-CLOUDFORMATION-INFO] Creating MordorC2Stack ..
    
    {
        "StackId": "arn:aws:cloudformation:us-east-1:xxxxxxxxxxxxxx:stack/MordorC2Stack/6a6256c0-ddcb-11e9-ade7-1253a26d999e"
    }
    
    [MORDOR-CLOUDFORMATION-INFO] C2 stack template has been sent over to AWS and it is being processed remotely ..
    [MORDOR-CLOUDFORMATION-INFO] Creating MordorWindowsDCStack ..
    
    {
        "StackId": "arn:aws:cloudformation:us-east-1:xxxxxxxxxxxxxx:stack/MordorWindowsDCStack/6b4b3020-ddcb-11e9-8a04-124d1eab42ba"
    }
    
    [MORDOR-CLOUDFORMATION-INFO] DC stack template has been sent over to AWS and it is being processed remotely ..
    [MORDOR-CLOUDFORMATION-INFO] All other Windows instances depend on it.
    [MORDOR-CLOUDFORMATION-INFO] Waiting for MordorWindowsDCStack to be created..
    
    
    [MORDOR-CLOUDFORMATION-INFO] MordorWindowsDCStack was created.
    [MORDOR-CLOUDFORMATION-INFO] Creating MordorWindowsServersStack ..
    
    {
        "StackId": "arn:aws:cloudformation:us-east-1:xxxxxxxxxxxxxx:stack/MordorWindowsServersStack/1360dca0-ddcd-11e9-909f-0eb49284c068"
    }
    
    [MORDOR-CLOUDFORMATION-INFO] Servers stack template has been sent over to AWS and it is being processed remotely ..
    
    [MORDOR-CLOUDFORMATION-INFO] Creating MordorWindowsWorkstationsStack ..
    {
        "StackId": "arn:aws:cloudformation:us-east-1:xxxxxxxxxxxxxx:stack/MordorWindowsWorkstationsStack/14a6f130-ddcd-11e9-84eb-0a62acea77ae"
    }
    
    [MORDOR-CLOUDFORMATION-INFO] Workstations stack template has been sent over to AWS and it is being processed remotely ..
    [MORDOR-CLOUDFORMATION-INFO] No other stack depends on Workstations or Servers
    [MORDOR-CLOUDFORMATION-INFO] You can track deployment progress via your CloudFormation Console
    [MORDOR-CLOUDFORMATION-INFO] CloudFormation Console: https://console.aws.amazon.com/cloudformation/home?region=us-east-1 

Monitor Stack Build Logs
########################

AWS CLI View
************

.. code-block:: console

    $ aws --region us-east-1 cloudformation describe-stack-events --stack-name MordorWindowsWorkstationsStack

AWS CloudFormation Console
**************************

You can use the AWS CloudFormation console to see all your stacks, their events, templates uploaded and more.

.. image:: _static/CFN-Services-CloudFormation.png
    :alt: The Shire
    :scale: 40%

All the templates that you sent over to AWS will start being processed immediately

.. image:: _static/CFN-Stacks-Console.png
    :alt: The Shire
    :scale: 40%

You can click on each stack and get more information about the deployment

.. image:: _static/CFN-Stack-HELK-Events.png
    :alt: The Shire
    :scale: 40%

You can also see the specific template mapped to each stack

.. image:: _static/CFN-Stack-HELK-Template.png
    :alt: The Shire
    :scale: 40%

Once a stack is complete you will be able to see it sending a successful signal back to the management console

.. image:: _static/CFN-Stack-C2-Complete.png
    :alt: The Shire
    :scale: 40%

Once all your instances are up and running you will be able to see them via the CloudFormation and the EC2 instances dashboard

.. image:: _static/CFN-Stacks-AllComplete.png
    :alt: The Shire
    :scale: 40%

.. image:: _static/CFN-EC2-Running.png
    :alt: The Shire
    :scale: 40%

Connect to Instances
####################

SSH (Linux)
***********

.. code-block:: console

    $ ssh -v -i <Private Key File>.pem ubuntu@<public-DNS-name>


RDP (Windows)
*************

.. image:: _static/CFN-Stack-DC-AD.png
    :alt: The Shire
    :scale: 40%

Browser (HELK & Covenant C2)
****************************

.. image:: _static/CFN-Stack-HELK-Kibana.png
    :alt: The Shire
    :scale: 40%

.. image:: _static/CFN-Stack-C2-Covenant.png
    :alt: The Shire
    :scale: 40%

Delete Stacks
#############

.. code-block:: console

    $ aws --region us-east-1 cloudformation delete-stack --stack-name MordorWindowsServersStack
