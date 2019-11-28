ATT&CK Website CloudFormation
=============================

You can take the docker `image <https://hub.docker.com/repository/docker/cyb3rward0g/attack-website>`_ I built and add it on the top of an AWS CloudFormation template. 

Templates
#########

+------------------------------------+----------------------------------------------------------------------------------------------------------------------------------+
| Template                           | Format                                                                                                                           |
+====================================+==================================================================================================================================+
| ec2-network-template               | `JSON <https://github.com/hunters-forge/Blacksmith/blob/master/aws/attack-website/cfn-templates/ec2-network-template.json>`_     |
+------------------------------------+----------------------------------------------------------------------------------------------------------------------------------+
| attack-server-template             | `JSON <https://github.com/hunters-forge/Blacksmith/blob/master/aws/attack-website/cfn-templates/attack-server-template.json>`_   |
+------------------------------------+----------------------------------------------------------------------------------------------------------------------------------+

Pre-Requirements
################

Make sure you follow the `AWS setup steps <https://blacksmith.readthedocs.io/en/latest/aws_setup.html>`_ provided to use the Blacksmith project.

* An existing AWS Account
* AWS CLI installed
* EC2 Key Pair Available
* 10 mins of your day

Pre-Deployment
##############

First, make sure you **git clone** the main repo:

.. code-block:: console

    $ git clone https://github.com/hunters-forge/Blacksmith
    $ cd Blacksmith/aws/attack-website/

Update Parameters File
**********************

You can update the parameters applied to the whole environment in the following folder:

.. code-block:: console

    $ cd cfn-parameters/

Most of them are already filled out for you to build the basic attack-website environment.
However, you must upate the following parametes:

* Edit **cfn-parameters/ec2-network-parameters.json** and set the parameter value for **RestrictLocation**. Set your house public IP.
* Edit **cfn-parameters/attack-server-parameters.json** and set the parameter value for **KeyName**. Set the key pair name you created in the pre-requirements step.

Automatic Deployment
####################

if you are still in the root directory of attack-website (Blacksmith/aws/attack-website), run the bash script ./deploy-attack.sh

.. code-block:: console

    $ ./deploy-attack.sh

Monitor Stack Build Logs
########################

AWS CloudFormation Console
**************************

All the templates that you sent over to AWS will start being processed immediately

.. image:: _static/CFN-Stacks-attack-Process.png
    :alt: ATT&CK process
    :scale: 30%

Connect to Instances
####################

SSH (Monitor Logs)
******************

.. code-block:: console

    $ ssh -v -i <Private Key File>.pem ubuntu@<public-DNS-attack-website-name>

.. code-block:: console

    $ sudo docker logs --follow attack-website

    Clean Build            : ---------------------------------------- 0.00s      
    Downloading STIX Data  : ---------------------------------------- 1.61s      
    Initializing Data      : ---------------------------------------- 38.70s      
    Index Page             : ---------------------------------------- 0.40s      
    Group Pages            : ---------------------------------------- 2.94s      
    Software Pages         : ---------------------------------------- 8.23s      
    Technique Pages        : ---------------------------------------- 7.01s      
    Matrix Pages           : ---------------------------------------- 8.29s      
    Tactic Pages           : ---------------------------------------- 0.83s      
    Mitigation Pages       : ---------------------------------------- 0.44s      
    Contribute Page        : ---------------------------------------- 0.12s      
    Resources Page         : ---------------------------------------- 0.00s      
    Redirection Pages      : ---------------------------------------- 0.58s      
    Search Index           : ---------------------------------------- 168.89s      
    Previous Versions      : ---------------------------------------- 9.10s      
    /home/attackuser/.local/lib/python3.7/site-packages/scss/selector.py:54: FutureWarning: Possible nested set at position 329
    ''', re.VERBOSE | re.MULTILINE)
    Pelican Content        : ---------------------------------------- 15.44s      

    Running tests:
    -------------------  --------------------------  -------------------------- 
    STATUS               TEST                        MESSAGE                    
    -------------------  --------------------------  -------------------------- 
    PASSED               Output Folder Size          Size: 671.90 MB            
    PASSED               Internal Links              5438 OK - 0 broken link(s) 
    PASSED               Unlinked Pages              0 unlinked page(s)         
    PASSED               Relative Links              0 page(s) with relative link(s) found
    PASSED               Broken Citations            3308 pages OK, 0 pages broken
    -------------------  --------------------------  -------------------------- 

    5 tests passed, 0 tests failed

    TOTAL Build Time       : ---------------------------------------- 262.94s      
    TOTAL Test Time        : ---------------------------------------- 11.72s      
    TOTAL Update Time      : ---------------------------------------- 274.66s


Browser
*******

.. image:: _static/CFN-attack-website-main.png
    :alt: ATT&CK Website
    :scale: 30%