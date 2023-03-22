
# Pre requisites

Define the secrets in the PrivateRules.mak
```
SNMP_DELL_IDRAC_AUTH_COMMUNITY=<<comunity_string>>
SNMP_RIELLO_UPS_AUTH_COMMUNITY=<<comunity_string>>
```

# Deploy SNMPN exporter
The snmp exporter runs as a docker container. It translates the snmp metrics to prometheus data.

Run the playbook
```
PLAYBOOKS_HOSTS=<<host>> make playbooks monitoring snmp_exporter
```

# Deploy SNMPN services for the ups trap

The snmptrapd reciver kicks off with the snmpd.service that has an override to run also the snmptrapd.service

To make sure the trap system works the **snmptrapd.service** and **snmptrapd.socket** must be **stoped** and **disable**


Run the playbook
```
PLAYBOOKS_HOSTS=<<host>> make playbooks monitoring snmp_install
```

## Note
snmptt may need the install of the Net::IP Perl module
```
cpan install Net::IP
```

# Destroy SNMPN services
Run the playbook
```
PLAYBOOKS_HOSTS=<<host>> make playbooks monitoring snmp_destroy
```

# Generate snmptt translations config for riello ups mib

Download riello ups mib from https://www.riello-ups.com/downloads/25-netman-204 (private mibs)

Extract the files to a folder.

```
sudo apt install snmptt

# you may need to install the Net::IP Perl module
cpan install Net::IP

```

To generate we will need the RielloUPS.mib and the RIELLO-MIB.mib in the extracted folder.
Run the command

```
snmpttconvertmib --in=<<path>>/RielloUPS.mib  --out /etc/snmp/riello-ups.conf
```
