# Amazon Web Services Provider

# AWS CloudFormation

Blacksmith leverages CloudFormation to deploy templates in AWS. AWS CloudFormation provides a common language for you to describe and provision all the infrastructure resources in your cloud environment. CloudFormation allows you to use a simple text file to model and provision, in an automated and secure manner, all the resources needed for your applications across all regions and accounts.

# AWS Free Tier Account

You can try some AWS services free of charge within certain usage limits. When you create an AWS account, you're automatically signed up for the Free Tier for 12 months. Your Free Tier eligibility expires at the end of the 12-month period. When your Free Tier expires, AWS starts charging the regular rates for any AWS services and resources that you're using.

To avoid charges while on the Free Tier, you must keep your usage below the [Free Tier limits](https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/free-tier-limits.html). You are charged for any usage that exceeds the limits. To help you stay within the limits, you can track your Free Tier usage and set a billing alarm to notify you if you start incurring charges.

AWS Free Tier Services : https://aws.amazon.com/free/?all-free-tier.sort-by=item.additionalFields.SortRank&all-free-tier.sort-order=asc

When you sign up for Amazon Web Services (AWS), your AWS account is automatically signed up for all services in AWS. Remember that you are charged **ONLY** for the services that you use. Part of the sign-up procedure involves receiving a phone call and entering a verification code on the phone keypad. Note your AWS account ID and information.

# Local AWS Setup

## Sign up for AWS account

* Open https://portal.aws.amazon.com/billing/signup.
* Follow the online instructions.

## Create an IAM User

It is not good to use your new root AWS account. I highly recommend to add an IAM user following these instructions: https://docs.aws.amazon.com/en_pv/IAM/latest/UserGuide/id_users_create.html

## Install AWS CLI

Reference: https://docs.aws.amazon.com/cli/latest/userguide/install-linux-al2017.html

### PIP install

```
pip3 install --upgrade --user awscli
```

Add the install location to the beginning of your PATH variable:

```
export PATH=/home/ec2-user/.local/bin:$PATH
```

Add this command to the end of your profile's startup script (for example, ~/.bashrc) to persist the change between command line sessions.

## Configure AWS CLI (Locally)

Once you have a user created under your root account, you can start using that account to interact with AWS services. You can run the `configure` command via the AWS CLI. When you type this command, the AWS CLI prompts you for four pieces of information (access key, secret access key, AWS Region, and output format). The blacksmith project supports the **US-EAST-1** region ONLY for now.

```
aws configure
```

Fill out your AWS credentials. Replace **abc123** with your own `AWS Access Key ID` and your `AWS Secret Access Key`.
The AWS Access Key ID and AWS Secret Access Key are your AWS credentials. They are associated with the AWS Identity and Access Management (IAM) user or role that you created. Once again, for a tutorial on how to create a user with the IAM service, see [Creating Your First IAM Admin User and Group](https://docs.aws.amazon.com/IAM/latest/UserGuide/getting-started_create-admin-group.html) in the IAM User Guide.

This will avoid you commiting your AWS keys in templates or other documents that you share .

```
AWS Access Key ID [None]: abc123 
AWS Secret Access Key [None]: abc123
Default region name [None]: us-east-1
Default output format [None]:
```

# Set up Amazon EC2 Key Pairs

Amazon EC2 uses public–key cryptography to encrypt and decrypt login information. Public–key cryptography uses a public key to encrypt a piece of data, and then the recipient uses the private key to decrypt the data. The public and private keys are known as a key pair. Public-key cryptography enables you to securely access your instances using a private key instead of a password.

When you launch an instance, you specify the key pair. You can specify an existing key pair or a new key pair that you create at launch. At boot time, the public key content is placed on the instance in an entry within `~/.ssh/authorized_keys`. To log in to your instance, you must specify the private key when you connect to the instance.

All the AWS CloudFormation templates provided by the project allow you to define the name of your Key Pair via the variable **KeyName**. It will make sense once you start using the templates.

## Create Key Pair

```
aws --region us-east-1 ec2 create-key-pair --key-name aws-ubuntu-key --query 'KeyMaterial' --output text > aws-ubuntu-key.pem
```

## Delete Key Pair (Optional)

If you already have a Key set up in you AWS zone, and you want to delete it, you can run the following commands:

```
aws ec2 delete-key-pair --key-name aws-ubuntu-key

```

## Verify Key

You can verify the Key Pairs associated with your AWS account. Run the following commands:

```
aws --region us-east-1 ec2 describe-key-pairs
```

```
{
    "KeyPairs": [
        {
            "KeyFingerprint": "xxxxxxxxxxxxxxxxxxxx",
            "KeyName": "aws-ubuntu-key"
        }
    ]
}
```

## Update AWS Key Permissions (Protect Key File)

If you will use an SSH client on a Mac or Linux computer to connect to your Linux instance, use the following command to set the permissions of your private key file so that only you can read it. If you do not set these permissions, then you cannot connect to your instance using this key pair. For more information, see [Error: Unprotected Private Key File](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/TroubleshootingInstancesConnecting.html#troubleshoot-unprotected-key).

```
chmod 400 aws-ubuntu-key.pem 
```