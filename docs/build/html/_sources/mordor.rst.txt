Mordor Environments
===================

The mordor project provides pre-recorded datasets to the community to expedite the analytics validation process and allow hunters to learn more about adversarial techniques.
Each Mordor environment was designed to replicate a very small network with the essential devices to colllect information from adversarial activities.
The Blacksmith project maintains the design and code to deploy custom mordor network environments to simulate adversarial techniques and export all the data generated.

The project provides the following templates and parameter files for a more dynamic build:

Templates
#########

+------------------------------------+----------------------------------------------------------------------------------------------------------------------------------+
| Template                           | Format                                                                                                                           |
+====================================+==================================================================================================================================+
| Mordor-EC2-Network                 | `JSON <https://github.com/hunters-forge/Blacksmith/blob/master/aws/mordor/cfn-templates/ec2-network-template.json>`_             |
+------------------------------------+----------------------------------------------------------------------------------------------------------------------------------+
| Mordor-HELK-Server                 | `JSON <https://github.com/hunters-forge/Blacksmith/blob/master/aws/mordor/cfn-templates/helk-server-template.json>`_             |
+------------------------------------+----------------------------------------------------------------------------------------------------------------------------------+
| Mordor-C2-Server                   | `JSON <https://github.com/hunters-forge/Blacksmith/blob/master/aws/mordor/cfn-templates/c2-server-template.json>`_               |
+------------------------------------+----------------------------------------------------------------------------------------------------------------------------------+
| Mordor-Windows-DC                  | `JSON <https://github.com/hunters-forge/Blacksmith/blob/master/aws/mordor/cfn-templates/windows-dc-template.json>`_              |
+------------------------------------+----------------------------------------------------------------------------------------------------------------------------------+
| Mordor-Windows-Servers             | `JSON <https://github.com/hunters-forge/Blacksmith/blob/master/aws/mordor/cfn-templates/windows-servers-template.json>`_         |
+------------------------------------+----------------------------------------------------------------------------------------------------------------------------------+
| Mordor-Windows-Workstations        | `JSON <https://github.com/hunters-forge/Blacksmith/blob/master/aws/mordor/cfn-templates/windows-workstations-template.json>`_    |
+------------------------------------+----------------------------------------------------------------------------------------------------------------------------------+

Pre-Requirements
################

* An existing AWS Account (Free tier is recommended)
* AWS CLI installed
* EC2 Key Pair Available
* 20 mins of your day

Environments
############

.. toctree::
   :maxdepth: 2

   The Shire <mordor_shire>