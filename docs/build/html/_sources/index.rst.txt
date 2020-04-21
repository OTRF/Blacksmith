.. Blacksmith documentation master file, created by
   sphinx-quickstart on Sat Sep 14 23:37:29 2019.
   You can adapt this file completely to your liking, but it should at least
   contain the root `toctree` directive.

The Blacksmith Project
======================

The Blacksmith project focuses on providing dynamic easy-to-use templates for security researches to model 
and provision resources to automatically deploy applications and small networks in the cloud. It currently 
leverages `AWS CloudFormation <https://aws.amazon.com/cloudformation/>`_ and `Microsoft Azure Resource Manager (ARM) <https://docs.microsoft.com/en-us/azure/azure-resource-manager/templates/overview>`_
templates to implement infrastructure as code for cloud solutions.

Goals
*****

* Expedite research by providing dynamic templates to deploy applications in the cloud.
* Translate favorite applications or tools into cloud templates for developing and testing.
* Replicate research environments for training purposes
* Learn more about AWS CloudFormation
* Learn more about Microsoft's Azure Resource Manager (ARM) templates

.. toctree::
   :maxdepth: 2
   :caption: Getting Started:

   AWS Setup <aws_setup>
   Azure Setup <azure_setup>

.. toctree::
   :maxdepth: 2
   :caption: Available Projects:

   Mordor Labs <mordor_labs>
   SilkETW <silketw>
   ATT&CK Website <attack_website>
   Azure Sentinel2Go <azure_sentinel2go>

.. toctree::
   :maxdepth: 2
   :caption: Licenses:

   GNU General Public License V3 <license>
