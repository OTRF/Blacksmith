Mordor Environments
===================

The mordor project provides pre-recorded datasets to the community to expedite the analytics validation process and allow hunters to learn more about adversarial techniques.
Each Mordor environment was designed to replicate a very small network with the essential devices to colllect information from adversarial activities.
The Blacksmith project maintains the design and code to deploy custom mordor network environments to simulate adversarial techniques and export all the data generated.

The project provides the following templates and parameter files for a more dynamic build:

Templates
#########

+------------------------------------+----------------------------------------------------------------------------------------------------------------+
| Template                           | Format                                                                                                         |
+====================================+================================================================================================================+
| Mordor-EC2-Network                 | `JSON <https://github.com/Cyb3rWard0g/Blacksmith/blob/master/aws/mordor/Mordor-EC2-Network.json>`_             |
+------------------------------------+----------------------------------------------------------------------------------------------------------------+
| Mordor-HELK-Server                 | `JSON <https://github.com/Cyb3rWard0g/Blacksmith/blob/master/aws/mordor/Mordor-HELK-Server.json>`_             |
+------------------------------------+----------------------------------------------------------------------------------------------------------------+
| Mordor-C2-Server                   | `JSON <https://github.com/Cyb3rWard0g/Blacksmith/blob/master/aws/mordor/Mordor-C2-Server.json>`_               |
+------------------------------------+----------------------------------------------------------------------------------------------------------------+
| Mordor-Windows-DC                  | `JSON <https://github.com/Cyb3rWard0g/Blacksmith/blob/master/aws/mordor/Mordor-Windows-DC.json>`_              |
+------------------------------------+----------------------------------------------------------------------------------------------------------------+
| Mordor-Windows-Servers             | `JSON <https://github.com/Cyb3rWard0g/Blacksmith/blob/master/aws/mordor/Mordor-Windows-Servers.json>`_         |
+------------------------------------+----------------------------------------------------------------------------------------------------------------+
| Mordor-Windows-Workstations        | `JSON <https://github.com/Cyb3rWard0g/Blacksmith/blob/master/aws/mordor/Mordor-Windows-Workstations.json>`_    |
+------------------------------------+----------------------------------------------------------------------------------------------------------------+

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