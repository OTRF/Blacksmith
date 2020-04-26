Azure P2S VPN Setup
===================

A Point-to-Site (P2S) VPN gateway connection lets you create a secure connection to your virtual network from an individual client computer.
A P2S connection is established by starting it from the client computer.

Almost every Azure environment deployed under the Blacksmith's project leverages the OpenVPN® Protocol, an SSL/TLS based VPN protocol for P2S VPN.

Azure VPN Gateway
#################

In order to connect a local endpoints to the environments deployed in Azure, the project leverages an `Azure VPN Gateway <https://docs.microsoft.com/en-us/azure/vpn-gateway/vpn-gateway-about-vpngateways>`_.
A VPN gateway is a specific type of virtual network gateway that is used to send encrypted traffic between an Azure virtual network and an on-premises location over the public Internet.

Azure ARM Tepmplate: https://docs.microsoft.com/en-us/azure/templates/microsoft.network/2019-04-01/virtualnetworkgateways

Azure VPN Gateway Subnet
########################

Before creating a VPN gateway, a gateway subnet is created first to define the range of IP Addresses that the virtual network gateway VMs would use.
The gateway subnet must be always named 'GatewaySubnet' to work properly.
According to Azure documentation, naming the gateway subnet 'GatewaySubnet' lets Azure know that this is the subnet to deploy the virtual network gateway VMs and services to.

P2S VPN Certificates
####################

Install strongSwan (MAC)
************************

.. code-block:: console

    brew install strongSwan

Create a root CA certificate
****************************

create the root CA Key

.. code-block:: console

    ipsec pki --gen --outform pem > caKey.pem

Generate the root CA certificate and sign it with the CA's root key

.. code-block:: console

    ipsec pki --self --in caKey.pem --dn "CN=VPNrootCA" --ca --outform pem > caCert.pem

You can verify new root CA certificate

.. code-block:: console

    openssl x509 -in caCert.pem -text -noout

Copy root CA cert one-line

.. code-block:: console

    openssl x509 -in caCert.pem -outform def | base64 | pbcopy

Create a Client Certificate signed with the CA's root key
*********************************************************

.. code-block:: console

    export USERNAME="xxxxxxxx"

create the child Key

.. code-block:: console

    ipsec pki --gen --outform pem > "${USERNAME}Key.pem"

Generate the certificate with the device CSR and the device key and sign it with the CA's certificate

.. code-block:: console

    ipsec pki --pub --in "${USERNAME}Key.pem" | ipsec pki --issue --cacert caCert.pem --cakey caKey.pem --dn "CN=${USERNAME}" --san "${USERNAME}" --flag clientAuth --outform pem > "${USERNAME}Cert.pem"

Get Certificate Public Key

.. code-block:: console

    openssl x509 -in "${USERNAME}Cert.pem" -outform der | base64 | pbcopy

OpenVPN Client Setup
####################

This is a great reference to do it in platforms such as Windows, Linux and Mac : https://docs.microsoft.com/en-us/azure/vpn-gateway/vpn-gateway-howto-openvpn-clients

References
##########

* https://docs.microsoft.com/en-us/azure/vpn-gateway/point-to-site-about
* https://docs.microsoft.com/en-us/azure/vpn-gateway/vpn-gateway-about-vpngateways
* https://docs.microsoft.com/en-us/azure/vpn-gateway/vpn-gateway-about-vpn-gateway-settings#gwsub
* https://docs.microsoft.com/en-us/azure/vpn-gateway/vpn-gateway-certificates-point-to-site-linux
* https://docs.microsoft.com/en-us/azure/vpn-gateway/vpn-gateway-howto-openvpn-clients#mac