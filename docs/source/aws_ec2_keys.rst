AWS EC2 Key Pairs
=================

Amazon EC2 uses public–key cryptography to encrypt and decrypt login information.
Public–key cryptography uses a public key to encrypt a piece of data, and then the recipient uses the private key to decrypt the data.
The public and private keys are known as a key pair.
Public-key cryptography enables you to securely access your instances using a private key instead of a password.
When you launch an instance, you specify the key pair.

You can specify an existing key pair or a new key pair that you create at launch.
At boot time, the public key content is placed on the instance in an entry within **~/.ssh/authorized_keys**.
To log in to your instance, you must specify the private key when you connect to the instance.

All the AWS CloudFormation templates provided by the project allow you to define the name of your Key Pair via the variable **KeyName**.
It will make sense once you start using the templates.

Create Key Pair
###############

.. code-block:: console

    $ aws --region us-east-1 ec2 create-key-pair --key-name aws-ubuntu-key --query 'KeyMaterial' --output text > aws-ubuntu-key.pem

(Optional) You can also delete any keys you have available or created by accident or for testing with the following command:

.. code-block:: console

    $ aws --region us-east-1 ec2 delete-key-pair --key-name aws-ubuntu-key


Verify Key
##########

You can verify if the Key you created is already associated with your AWS account by running the following command:

.. code-block:: console

    $ aws --region us-east-1 ec2 describe-key-pairs

.. code-block:: console

    {
        "KeyPairs": [
            {
                "KeyFingerprint": "xxxxxxxxxxxxxxxxxxxx",
                "KeyName": "aws-ubuntu-key"
            }
        ]
    }

Update Key Permissions
######################

Protect your private key.
If you will use an SSH client on a Mac or Linux computer to connect to your Linux instance, use the following command to set the permissions of your private key file so that only you can read it.
If you do not set these permissions, then you cannot connect to your instance using this key pair.
For more information, see: `Error: Unprotected Private Key File <https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/TroubleshootingInstancesConnecting.html#troubleshoot-unprotected-key>`_.

.. code-block:: console

    $ chmod 400 aws-ubuntu-key.pem

References
##########

* https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-key-pairs.html