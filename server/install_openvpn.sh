#!/bin/bash

# Update and upgrade the system
sudo apt-get update
sudo apt-get upgrade -y

# Install OpenVPN and Easy-RSA
sudo apt-get install -y openvpn easy-rsa

# Set up the Certificate Authority (CA)
make-cadir ~/openvpn-ca
cd ~/openvpn-ca

# Customize the variables (you can modify these as needed)
cat > vars <<EOF
export KEY_COUNTRY="US"
export KEY_PROVINCE="CA"
export KEY_CITY="SanFrancisco"
export KEY_ORG="MyOrg"
export KEY_EMAIL="email@example.com"
export KEY_OU="MyOrgUnit"
export KEY_NAME="server"
EOF

# Load the variables and build the CA
source vars
./clean-all
./build-ca --batch

# Generate the server certificate and key
./build-key-server --batch server

# Generate Diffie-Hellman parameters
./build-dh

# Generate HMAC key
openvpn --genkey --secret keys/ta.key

# Copy server files to /etc/openvpn
sudo cp keys/ca.crt keys/server.crt keys/server.key keys/ta.key keys/dh.pem /etc/openvpn/

# Copy the sample server.conf and modify it
sudo cp /usr/share/doc/openvpn/examples/sample-config-files/server.conf.gz /etc/openvpn/
cd /etc/openvpn/
sudo gzip -d server.conf.gz

# Edit the server.conf file
sudo sed -i 's/dh dh1024.pem/dh dh.pem/' server.conf
sudo sed -i 's/;tls-auth ta.key 0/tls-auth ta.key 0/' server.conf
sudo sed -i 's/;user nobody/user nobody/' server.conf
sudo sed -i 's/;group nogroup/group nogroup/' server.conf
sudo sed -i 's/;push "redirect-gateway def1 bypass-dhcp"/push "redirect-gateway def1 bypass-dhcp"/' server.conf

# Enable IP forwarding
sudo sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/' /etc/sysctl.conf
sudo sysctl -p

# Configure UFW to allow OpenVPN traffic
sudo ufw allow 1194/udp
sudo ufw allow OpenSSH

# Add NAT rules to UFW
sudo bash -c 'echo -e "*nat\n:POSTROUTING ACCEPT [0:0]\n-A POSTROUTING -s 10.8.0.0/8 -o eth0 -j MASQUERADE\nCOMMIT" >> /etc/ufw/before.rules'
sudo sed -i 's/DEFAULT_FORWARD_POLICY="DROP"/DEFAULT_FORWARD_POLICY="ACCEPT"/' /etc/default/ufw

# Restart UFW
sudo ufw disable
sudo ufw enable

# Start and enable the OpenVPN service
sudo systemctl start openvpn@server
sudo systemctl enable openvpn@server

# Generate a client certificate and key
cd ~/openvpn-ca
source vars
./build-key --batch client1

# Create client configuration directory
mkdir -p ~/client-configs/files
cp /usr/share/doc/openvpn/examples/sample-config-files/client.conf ~/client-configs/base.conf

# Modify the client configuration file
sed -i 's/;user nobody/user nobody/' ~/client-configs/base.conf
sed -i 's/;group nogroup/group nogroup/' ~/client-configs/base.conf
sed -i 's/ca ca.crt/cert client1.crt/' ~/client-configs/base.conf
sed -i 's/cert client.crt/key client1.key/' ~/client-configs/base.conf

# Create the client config file
cat > ~/client-configs/files/client.ovpn <<EOF
client
dev tun
proto udp
remote YOUR_SERVER_IP 1194
resolv-retry infinite
nobind
persist-key
persist-tun
remote-cert-tls server
cipher AES-256-CBC
comp-lzo
verb 3
key-direction 1

<ca>
$(cat ~/openvpn-ca/keys/ca.crt)
</ca>

<cert>
$(cat ~/openvpn-ca/keys/client1.crt)
</cert>

<key>
$(cat ~/openvpn-ca/keys/client1.key)
</key>

<tls-auth>
$(cat ~/openvpn-ca/keys/ta.key)
</tls-auth>
EOF

echo "OpenVPN installation and configuration complete!"
echo "The client configuration file is located at: ~/client-configs/files/client.ovpn"
