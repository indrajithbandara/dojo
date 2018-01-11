# ---------------------------------------------------------------------------------
# Basic configuration
# ---------------------------------------------------------------------------------
# These parameters below starting with "BLP_" are used to about LDAP server.

# Domain name for ldap server.
BLP_DOMAIN="mysite.example.com"

# Organization Name
BLP_ORGANIZATION="Example Inc."

# Hostname for ldap server
BLP_HOSTNAME="ldap"

# FQDN of the ldap server
BLP_FQDN="${BLP_HOSTNAME}.${BLP_DOMAIN}"

# LDAP Domain Component
# (Like ... "mysite.example.com" -> "dc=mysite,dc=example,dc=com")
BLP_DOMAIN_COMPONENT=$(echo "dc="`echo ${BLP_DOMAIN} | sed -e 's|\.|,dc=|g'`)

# Password for config root(olcDatabase={0}config,cn=config").
BLP_CONFIG_ROOT_PW="password"
# DN for config root(olcDatabase={0}config,cn=config").
BLP_CONFIG_ROOT_DN="cn=admin,cn=config"

# Common name of Manager
BLP_CN_MANAGER="cn=Manager,${BLP_DOMAIN_COMPONENT}"
# Password for backend db in OpenLDAP (ex, dn: olcDatabase={1}mdb,cn=config).
BLP_BACKEND_PW="password2"

# Domain "uid=root,ou=Users,${BLP_DOMAIN_COMPONENT}" after smbldap-populate after smbldap-populate
BLP_SMB_DOMAIN_ROOT_PW="pw-root"
#BLP_SMB_DOMAIN_ROOT_PW="password2"

# Network interface of the server.
#BLP_INTERFACE="eno16777736"
BLP_INTERFACE="eth0"

# IP address of the server.
# If this parameter is empty, this program will get correct IP from BLP_INTERFACE's interface
BLP_INTERFACE_IP=

# TODO: This parameter has not supported yet.
BLP_CA_PEM_FILE="/etc/pki/CA/certs/ca.pem"

# ---------------------------------------------------------------------------------
# Samba configuration
# ---------------------------------------------------------------------------------
# These parameters below starting with "SMB_" are used to about Samba Active Directory.

# Domain name
SMB_DOMAIN="MYSITE"

# Samba realm name
SMB_REALM="${BLP_DOMAIN^^}"

# Samba server role
SMB_SERVER_ROLE="dc"

# Samba backend dns.
# This parameter possible to be SAMBA_INTERNAL, BIND9_FLATFILE, BIND9_DLZ or NONE.
SMB_DNS_BACKEND="SAMBA_INTERNAL"

SMB_DNS_BACKEND_IP="127.0.0.1"

SMB_DNS_BACKEND_SEARCH_DOMAIN="${BLP_DOMAIN}"

# Hostname of Samba
SMB_HOST_NAME=${BLP_HOSTNAME^^}

# IP address of Samba server
SMB_HOST_IP=

# DNS IP address.
SMB_BACKEND_DNS_IP=8.8.8.8

# Linux basic information ---------------------------------------------------------
# Distribution of Linux
LINUX_DISTRIBUTION=$(. /etc/os-release && echo $NAME)

# Version of Linux distribution
LINUX_VERSION=$(. /etc/os-release && echo $VERSION_ID)

# Family of Linux like as Debian, RedHat etc.
LINUX_FAMILY=

# OpenLDAP's etc dir of each distributions
BLP_ETC_LDAP_DIR=""

# Add parameters depend on distribution
if [[ "$LINUX_DISTRIBUTION" =~ ^Fedora.* ]]; then
    LINUX_DISTRIBUTION="Fedora"
    LINUX_FAMILY="RedHat"
    BLP_ETC_LDAP_DIR="/etc/openldap"
elif [[ "$LINUX_DISTRIBUTION" =~ ^CentOS.* ]]; then
    LINUX_DISTRIBUTION="CentOS"
    LINUX_FAMILY="RedHat"
    # TODO: confirm
    BLP_ETC_LDAP_DIR="/etc/openldap"
elif [[ "$LINUX_DISTRIBUTION" =~ ^Ubuntu.* ]]; then
    LINUX_DISTRIBUTION="Ubuntu"
    LINUX_FAMILY="Debian"
    BLP_ETC_LDAP_DIR="/etc/ldap"
elif [[ "${LINUX_DISTRIBUTION}" =~ ^Debian.* ]];then
    LINUX_DISTRIBUTION="Debian"
    LINUX_FAMILY="Debian"
    # TODO: confirm
    BLP_ETC_LDAP_DIR="/etc/ldap"
else
    echo "Sorry, this script doesn't support distribution ${LINUX_DISTRIBUTION}. Exit." >&2
    exit 1
fi

# Samba configuration files -------------------------------------------------------
SMB_LDAP_DIR="/etc/smbldap-tools"
SMB_LDAP_CONF="${SMB_LDAP_DIR}/smbldap.conf"
SMB_LDAP_BIND_CONF="${SMB_LDAP_DIR}/smbldap_bind.conf"
SMB_CONF="/etc/samba/smb.conf"
SMB_KRB_CONF="/etc/krb5.conf"

# Example file for smbldap.conf.
# This value is used if SMB_LDAP_BIND_CONF is not exist.
SMB_LDAP_CONF_EXAMPLE=$(
    if [ "${LINUX_DISTRIBUTION}" = "Debian" ]; then
        echo "/usr/share/doc/smbldap-tools/examples/smbldap.conf.gz"
    fi
)
# Example file for smbldap_bind.conf
SMB_LDAP_BIND_CONF_EXAMPLE=$(
    if [ "${LINUX_DISTRIBUTION}" = "Debian" ]; then
        echo "/usr/share/doc/smbldap-tools/examples/smbldap_bind.conf"
    fi
)

# Create First Domain Computers ---------------------------------------------------
SMB_DOMAIN_COMPUTER='workstation$'

# Create First Domain Admins(FDA) user --------------------------------------------
SMB_FDA_USER_NAME="Administrator"
SMB_FDA_USER_PASSWORD="p@ssword3"

# Create First Domain Users(FDU) user ---------------------------------------------
SMB_FDU_USER_NAME="saburo-suzuki"
SMB_FDU_USER_PASSWORD="pw-saburo-suzuki"

# Samba ldap sync option.
# If true, set "ldap password sync = yes" in smb.conf
SMB_LDAP_SYNC_METHOD=true

# ---------------------------------------------------------------------------------
# ---------------------------------------------------------------------------------
# ---------------------------------------------------------------------------------
# ---------------------------------------------------------------------------------
# ---------------------------------------------------------------------------------
# These parameters below are not necessary to edit.
# ---------------------------------------------------------------------------------

BLP_SHUTDOWN_STAT_FILE="/var/tmp/.__blp_shutdown_status__"

BLP_SHUTDOWN_STATUS=""

# Script file path
BLP_BASE_SCRIPT=$0

# Script file directory
BLP_BASE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# FQDN string for regex
BLP_REG_FQDN=$(echo $BLP_FQDN | sed -e 's/\./\\\./g')

# Backend of slqpd
BLP_BACKEND=""

# Pki dir of each distributions
BLP_PKI_DIR=""

# ---------------------------------------------------------------------------------
if [ -f "${BLP_SHUTDOWN_STAT_FILE}" ]; then
    read BLP_SHUTDOWN_STATUS < ${BLP_SHUTDOWN_STAT_FILE}
fi

# Get ip addresses
if [ "${BLP_INTERFACE}" = "" ]; then
    echo "A parameter BLP_INTERFACE in global.conf is not defined. The program will be terminated."
    exit 1
else
    IP_ADDRESS=$(get_ip_address_from_interface ${BLP_INTERFACE})
    if [ "${IP_ADDRESS}" = "" ]; then
        echo "IP address of ${BLP_INTERFACE} is not found. The program will be terminated."
        exit 1
    fi

    # Initialize parameters if not exist
    BLP_INTERFACE_IP=${BLP_INTERFACE_IP:-$IP_ADDRESS}
    SMB_HOST_IP=${SMB_HOST_IP:-$IP_ADDRESS}
fi

# TODO:
# These following variables are not supported yet.
BLP_ENABLE_TLS="false"
BLP_USE_WINDOWS_DOMAIN="true"
BLP_USE_TEST_CA="true"
BLP_CA_FQDN="ca.${BLP_DOMAIN}"

