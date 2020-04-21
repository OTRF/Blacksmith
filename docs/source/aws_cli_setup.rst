AWS CLI Installation
====================

The AWS Command Line Interface (CLI) is a unified tool to manage your AWS services.
With just one tool to download and configure, you can control multiple AWS services from the command line and automate them through scripts.

PIP Install
###########

.. code-block:: console

    $ pip3 install --upgrade --user awscli

After installing with pip, you might need to add the aws program to your operating system's PATH environment variable.
The location of the program depends on where Python is installed.

.. code-block:: console

    $ which python3
    
    /usr/local/bin/python3

The output might be the path to a symlink, not the actual program. Run ls -al to see where it points.

.. code-block:: console

    $ ls -al /usr/local/bin/python3

    ~/Library/Python/3.7/bin/python3.6

To modify your PATH variable (Linux or macOS), find your shell's profile script in your user folder.
If you're not sure which shell you have, run echo $SHELL.

* Bash – .bash_profile, .profile, or .bash_login
* Zsh – .zshrc
* Tcsh – .tcshrc, .cshrc, or .login

Add an export command to the end of your profile's startup script (for example, ~/.zshrc) to persist the change between command line sessions.

.. code-block:: console

    export PATH=$HOME/Library/Python/3.7/bin:$PATH

Load the updated profile into your current session

.. code-block:: console

    $ source ~/.zshrc

Configure AWS Creds
###################

Once you have a user created under your root account, you can start using that account to interact with AWS services.
However, you have to first set up your AWS credentials locally.
You will have to run the **configure** command via the AWS CLI, and it will prompt you for four pieces of information (access key, secret access key and AWS Region, and output format).
The blacksmith project supports the **US-EAST-1** region ONLY for now.

.. code-block:: console

    $ aws configure


Fill out your AWS credentials.
Replace **abc123** with your own **AWS Access Key ID** and your **AWS Secret Access Key**.
The AWS Access Key ID and AWS Secret Access Key are your AWS credentials.
They are associated with the AWS Identity and Access Management (IAM) user or role that you created.
Once again, for a tutorial on how to create a user with the IAM service, see `Creating Your First IAM Admin User and Group <https://docs.aws.amazon.com/IAM/latest/UserGuide/getting-started_create-admin-group.html>`_ in the IAM User Guide.

This will reduce the risk of you commiting your AWS keys in templates or other documents that you share.

.. code-block:: console

    AWS Access Key ID [None]: abc123 
    AWS Secret Access Key [None]: abc123
    Default region name [None]: us-east-1
    Default output format [None]:

References
##########

* https://docs.aws.amazon.com/cli/latest/userguide/install-linux-al2017.html
* https://aws.amazon.com/cli/