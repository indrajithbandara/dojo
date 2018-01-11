#!/bin/bash
#
# BLP_ENABLE_TLS=true/false (Default false)
#     Use connection with tls or not.
#
# BLP_USE_TEST_CA=true/false (Default true)
#     Use prepared ca certification for testing.
#     If BLP_ENABLE_TLS is false, the value of parameter will be ignored.
#
# BLP_USE_WINDOWS_DOMAIN=true/false (Default false)
#     Use Windows bind by using samba.
#
# ex)
# BLP_ENABLE_TLS=false BLP_USE_TEST_CA=false BLP_USE_WINDOWS_DOMAIN=true ./Build.sh
#

BLP_ENABLE_TLS=${BLP_ENABLE_TLS:-false}
BLP_USE_TEST_CA=${BLP_USE_TEST_CA:-true}
BLP_USE_WINDOWS_DOMAIN=${BLP_USE_WINDOWS_DOMAIN:-false}

function print_command_message {
    sync
    echo "============================================================"
    echo $1
    echo "============================================================"
}

function die {
    echo "die" >&2
    exit 1
}

# install packages
# @param list: package list delimited spaces
function install_lacking_packages {
    PACKAGES=$1

    REQUIRED_PACKAGE=""
    for PACKAGE in $PACKAGES; do
        rpm -q $PACKAGE
        RESULT=$?
        if [ $RESULT -ne 0 ]; then
            REQUIRED_PACKAGE="$REQUIRED_PACKAGE $PACKAGE"
        fi
    done

    if [ ! "$REQUIRED_PACKAGE" = "" ]; then
        dnf -y install $REQUIRED_PACKAGE
    fi
}

# install packages
install_lacking_packages "openldap openldap-clients openldap-servers"

# starting openldap
print_command_message "systemctl start slapd"
systemctl start slapd

print_command_message "systemctl start slapd"
systemctl enable slapd

# adding firewalld ldap
print_command_message "firewall-cmd --permanent --zone=FedoraServer --query-service=ldap"
firewall-cmd --permanent --zone=FedoraServer --add-service=ldap

print_command_message "firewall-cmd --permanent --zone=FedoraServer --query-service=ldaps"
firewall-cmd --permanent --zone=FedoraServer --add-service=ldaps

# confirm current settings of slapd
print_command_message "ldapsearch -LLL -Y EXTERNAL -H ldapi:/// -b \"cn=config\" \"(olcDatabase=*)\""
ldapsearch -LLL -Y EXTERNAL -H ldapi:/// -b "cn=config" "(olcDatabase=*)"

# confirm ldif to add olcRootPW
print_command_message "cat ldifs/starting_ldap/set_rootpw.ldif"
cat ldifs/starting_ldap/set_rootpw.ldif

# adding new root password as "password"
print_command_message "ldapadd -Y EXTERNAL -H ldapi:/// -f ldifs/starting_ldap/set_rootpw.ldif"
ldapadd -Y EXTERNAL -H ldapi:/// -f ldifs/starting_ldap/set_rootpw.ldif

# confirm slapd's root password
print_command_message "ldapsearch -x -LLL -D \"cn=config\" -w password -b \"cn=config\" \"(olcDatabase=*)\""
ldapsearch -x -LLL -D "cn=config" -w password -b "cn=config" "(olcDatabase=*)"

# Adding ldap schemas
print_command_message "ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/cosine.ldif"
ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/cosine.ldif

print_command_message "ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/nis.ldif"
ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/nis.ldif

print_command_message "ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/inetorgperson.ldif"
ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/inetorgperson.ldif

# modifing root dn
print_command_message "cat ldifs/starting_ldap/set_rootdn.ldif"
cat ldifs/starting_ldap/set_rootdn.ldif

print_command_message "ldapmodify -x -D cn=config -w password2 -f ./ldifs/starting_ldap/set_rootdn.ldif"
ldapmodify -x -D cn=config -w password -f ./ldifs/starting_ldap/set_rootdn.ldif

print_command_message "ldapsearch -x -LLL -D \"cn=config\" -w password -b \"cn=config\" \"(olcDatabase=*)\""
ldapsearch -x -LLL -D "cn=config" -w password -b "cn=config" "(olcDatabase=*)"

# adding base dn
print_command_message "cat ldifs/starting_ldap/create_base.ldif"
cat ldifs/starting_ldap/create_base.ldif

print_command_message "ldapadd -x -D \"cn=Manager,dc=mysite,dc=example,dc=com\" -w password2 -f ldifs/starting_ldap/create_base.ldif"
ldapadd -x -D "cn=Manager,dc=mysite,dc=example,dc=com" -w password2 -f ldifs/starting_ldap/create_base.ldif

print_command_message "ldapsearch -x -LLL -H ldap:/// -b \"dc=mysite,dc=example,dc=com\""
ldapsearch -x -LLL -H ldap:/// -b "dc=mysite,dc=example,dc=com"

# adding groups
print_command_message "cat ldifs/starting_ldap/create_groups.ldif"
cat ldifs/starting_ldap/create_groups.ldif

print_command_message "ldapadd -x -w password2 -D \"cn=Manager,dc=mysite,dc=example,dc=com\" -f ldifs/starting_ldap/create_groups.ldif"
ldapadd -x -w password2 -D "cn=Manager,dc=mysite,dc=example,dc=com" -f ldifs/starting_ldap/create_groups.ldif

print_command_message "ldapsearch -x -LLL -H ldap:/// -b \"ou=Groups,dc=mysite,dc=example,dc=com\" \"(objectClass=*)\""
ldapsearch -x -LLL -H ldap:/// -b "ou=Groups,dc=mysite,dc=example,dc=com" "(objectClass=*)"

# adding users
print_command_message "cat ./ldifs/starting_ldap/create_users.ldif"
cat ./ldifs/starting_ldap/create_users.ldif

print_command_message "ldapadd -x -w password2 -D \"cn=Manager,dc=mysite,dc=example,dc=com\" -f ldifs/starting_ldap/create_users.ldif"
ldapadd -x -w password2 -D "cn=Manager,dc=mysite,dc=example,dc=com" -f ldifs/starting_ldap/create_users.ldif

print_command_message "ldapsearch -x -LLL -H ldap:/// -b \"ou=Users,dc=mysite,dc=example,dc=com\" \"(objectClass=*)\""
ldapsearch -x -LLL -H ldap:/// -b "ou=Users,dc=mysite,dc=example,dc=com" "(objectClass=*)"

# TODO:
# Setting LDAP ACL's
## print_command_message "cat ./ldifs/starting_ldap/setting_acls.ldif"
## cat ./ldifs/starting_ldap/setting_acls.ldif
## 
## print_command_message "ldapmodify -x -D cn=config -w password -f ./ldifs/starting_ldap/setting_acls.ldif"
## ldapmodify -x -D cn=config -w password -f ./ldifs/starting_ldap/setting_acls.ldif

# create indexes
print_command_message "cat ./ldifs/starting_ldap/create_indexes.ldif"
cat ./ldifs/starting_ldap/create_indexes.ldif

print_command_message "ldapmodify -x -D cn=config -w password -f ./ldifs/starting_ldap/create_indexes.ldif"
ldapmodify -x -D cn=config -w password -f ./ldifs/starting_ldap/create_indexes.ldif

#############################################################################
# Creating CA and TLS cert.
# We will create what things are below
#     CA's private key named "ca-key.pem"
#     CA's certificate named "ca.pem"
#     LDAP server's private key named ""
#     LDAP server's certificate named ""
#############################################################################
# Creating srl

if [ "${BLP_ENABLE_TLS}" = "true" ]; then
    echo "00" > /etc/pki/CA/certs/ca.srl

    if [ "${BLP_USE_TEST_CA}" = "true" ]; then
        echo "## Using test ca"
        cp ./test_pki/ca.pem     /etc/pki/CA/certs/ca.pem
        cp ./test_pki/ca-key.pem /etc/pki/CA/private

        cp ./test_pki/ldap01.mysite.example.com.cert.pem /etc/openldap/certs
        cp ./test_pki/ldap01.mysite.example.com.pem      /etc/openldap/certs
    else
        # Creating CA private key and certificate
        cd /etc/pki/CA
        openssl genrsa -des3 -out ./private/ca-key.pem 2048
        openssl req -new -x509 -days 365 -key ./private/ca-key.pem -out ./certs/ca.pem \
            -subj "/C=JP/ST=Tokyo/L=Minatoku/O=Example Company/OU=Development/CN=ca.mysite.example.com"

        # Creating server private key and certificate
        cd /etc/openldap/certs
        openssl genrsa -des3 -out ldap01.mysite.example.com.pem 2048

        openssl req -new -key ldap01.mysite.example.com.pem -out ldap01.mysite.example.com.csr \
            -subj "/C=JP/ST=Tokyo/L=Hoge/O=Fuga Company/OU=Development/CN=ldap01.mysite.example.com"

        # Sign LDAP server's csr by using CA's private key to make LDAP server's certificate.
        openssl x509 -req -days 365 -in ldap01.mysite.example.com.csr -CA /etc/pki/CA/certs/ca.pem -CAkey /etc/pki/CA/private/ca-key.pem -out ldap01.mysite.example.com.cert.pem

        # Decryept LDAP server's private key to be able to load it by OpenLDAP
        openssl rsa -in ldap01.mysite.example.com.pem -out ldap01.mysite.example.com.pem
    fi

    # Regist the CA cert, the server key and the server certificate on OpenLDAP
    cd ~/BuildingLDAP

    print_command_message "cat ./ldifs/tls/set_tls.ldif"
    cat ./ldifs/tls/set_tls.ldif

    print_command_message "ldapmodify -x -w password -D cn=config -f ldifs/tls/set_tls.ldif"
    ldapmodify -x -w password -D cn=config -f ldifs/tls/set_tls.ldif

    print_command_message "ldapsearch -x -LLL -D \"cn=config\" -w password -b \"cn=config\" \"(olcTLSCACertificateFile=*)\""
    ldapsearch -x -LLL -D "cn=config" -w password -b "cn=config" "(olcTLSCACertificateFile=*)"

    echo "Please copy CA's certificate ca.pem and edit the client's ldap.conf like below"
    echo "  TLS_REQCERT   never"
    echo "  TLS_CACERT    /etc/pki/CA/certs/ca.pem"
    echo "  TLS_CACERTDIR /etc/pki/CA/certs"

fi

# TODO: Need I restart slapd to load certificate configs?

#############################################################################
# Samba LDAP
#############################################################################

[ "${BLP_USE_WINDOWS_DOMAIN}" = "false" ] && exit 0

# add own domain
MY_FQDN="ldap01.mysite.example.com"
REG_MY_FQDN=$(echo $MY_FQDN | sed -e 's/\./\\\./g')
egrep ".*$REG_MY_FQDN$" /etc/hosts > /dev/null
if [ $? -ne 0 ]; then
    echo "192.168.1.41 ${MY_FQDN}" >> /etc/hosts
fi

# install packages
install_lacking_packages "samba smbldap-tools"

SAMBA_LDIF=$(find /usr/share/doc/samba -type f -regex '.*/samba.ldif$')
FILE_COUNT=$(echo "$SAMBA_LDIF" | wc -l)
if [ ! "$FILE_COUNT" = "1" ]; then
    echo "Found multi samba.ldif files or missing it. Finished..."
    exit 1
fi

print_command_message "ldapadd -Y EXTERNAL -H ldapi:/// -f $SAMBA_LDIF"
ldapadd -Y EXTERNAL -H ldapi:/// -f $SAMBA_LDIF

# Create indexes
print_command_message "cat ./ldifs/smbldap/create_indexes.ldif"
cat ./ldifs/smbldap/create_indexes.ldif

print_command_message "ldapmodify -x -D cn=config -w password -f ./ldifs/smbldap/create_indexes.ldif"
ldapmodify -x -D cn=config -w password -f ./ldifs/smbldap/create_indexes.ldif

# Prepareing smbldap.conf and smbldap_bind.conf
SMBLDAP_CONF="/etc/smbldap-tools/smbldap.conf"
SMBLDAP_BIND_CONF="/etc/smbldap-tools/smbldap_bind.conf"
SMB_CONF="/etc/samba/smb.conf"
BACKUP_DATE=$(date +%Y%m%d%H%M%S)
if [ ! -f $SMBLDAP_CONF ]; then
    # TODO:
    true
else
    cp $SMBLDAP_CONF ${SMBLDAP_CONF}.${BACKUP_DATE}
fi

if [ ! -f $SMBLDAP_BIND_CONF ]; then
    # TODO:
    true
else
    cp $SMBLDAP_BIND_CONF ${SMBLDAP_BIND_CONF}.${BACKUP_DATE}
fi

cp ${SMB_CONF} ${SMB_CONF}.${BACKUP_DATE}

# Get localsid
LOCAL_SID=$(net getlocalsid | sed -e 's|SID for domain [^\s]\+ is: ||')
print_command_message "net getlocalsid -> $LOCAL_SID"

# Settings for smbldap.conf ---------------------------------------------------------

# SID
print_command_message 'sed -i -e "s|^#*\s*SID=.*|SID=\"$LOCAL_SID\"|g" $SMBLDAP_CONF'
sed -i -e "s|^#*\s*SID=.*|SID=\"$LOCAL_SID\"|g" $SMBLDAP_CONF
# sambaDomain
print_command_message 'sed -i -e "s|^#*\s*sambaDomain=.*|sambaDomain=\"MYSITE\"|g" $SMBLDAP_CONF'
sed -i -e "s|^#*\s*sambaDomain=.*|sambaDomain=\"MYSITE\"|g" $SMBLDAP_CONF
# TODO: comment slaveLDAP
print_command_message 'sed -i -e "s|^slaveLDAP=|#slaveLDAP=|g" $SMBLDAP_CONF'
sed -i -e "s|^slaveLDAP=|#slaveLDAP=|g" $SMBLDAP_CONF
# masterLDAP
print_command_message 'sed -i -e "s|^#*\s*masterLDAP=.*|masterLDAP=\"$MY_FQDN\"|g" $SMBLDAP_CONF'
sed -i -e "s|^#*\s*masterLDAP=.*|masterLDAP=\"$MY_FQDN\"|g" $SMBLDAP_CONF
# suffix
print_command_message 'sed -i -e "s|^#*\s*suffix=.*|suffix=\"dc=mysite,dc=example,dc=com\"|g" $SMBLDAP_CONF'
sed -i -e "s|^#*\s*suffix=.*|suffix=\"dc=mysite,dc=example,dc=com\"|g" $SMBLDAP_CONF
# usersdn
print_command_message 'sed -i -e "s|^#*\s*usersdn=.*|usersdn=\"ou=Users,\${suffix}\"|g" $SMBLDAP_CONF'
sed -i -e "s|^#*\s*usersdn=.*|usersdn=\"ou=Users,\${suffix}\"|g" $SMBLDAP_CONF
# TODO: computersdn
# groupsdn
print_command_message 'sed -i -e "s|^#*\s*groupsdn=.*|groupsdn=\"ou=Groups,\${suffix}\"|g" $SMBLDAP_CONF'
sed -i -e "s|^#*\s*groupsdn=.*|groupsdn=\"ou=Groups,\${suffix}\"|g" $SMBLDAP_CONF
# TODO: idmapdn
# mailDomain
print_command_message 'sed -i -e "s|^#*\s*mailDomain=.*|mailDomain=\"mysite.example.com\"|g" $SMBLDAP_CONF'
sed -i -e "s|^#*\s*mailDomain=.*|mailDomain=\"mysite.example.com\"|g" $SMBLDAP_CONF

# ldapTLS
if [ "${BLP_ENABLE_TLS}" = "true" ]; then
    print_command_message 'sed -i -e "s|^#*\s*ldapTLS=.*|ldapTLS=\"1\"|g" $SMBLDAP_CONF'
    sed -i -e "s|^#*\s*ldapTLS=.*|ldapTLS=\"1\"|g" $SMBLDAP_CONF
    # verify
    print_command_message 'sed -i -e "s|^#*\s*verify=.*|verify=\"require\"|g" $SMBLDAP_CONF'
    sed -i -e "s|^#*\s*verify=.*|verify=\"require\"|g" $SMBLDAP_CONF
    # cafile
    print_command_message 'sed -i -e "s|^#*\s*cafile=.*|cafile=\"/etc/pki/CA/certs/ca.pem\"|g" $SMBLDAP_CONF'
    sed -i -e "s|^#*\s*cafile=.*|cafile=\"/etc/pki/CA/certs/ca.pem\"|g" $SMBLDAP_CONF
    # clientcert
    print_command_message 'sed -i -e "s|^#*\s*clientcert=|#clientcert=|g" $SMBLDAP_CONF'
    sed -i -e "s|^#*\s*clientcert=|#clientcert=|g" $SMBLDAP_CONF
    # clientkey
    print_command_message 'sed -i -e "s|^#*\s*clientkey=|#clientkey=|g" $SMBLDAP_CONF'
    sed -i -e "s|^#*\s*clientkey=|#clientkey=|g" $SMBLDAP_CONF
else
    print_command_message 'sed -i -e "s|^#*\s*ldapTLS=.*|ldapTLS=\"0\"|g" $SMBLDAP_CONF'
    sed -i -e "s|^#*\s*ldapTLS=.*|ldapTLS=\"0\"|g" $SMBLDAP_CONF

    print_command_message 'sed -i -e "s|^#*\s*verify=.*|verify=\"none\"|g" $SMBLDAP_CONF'
    sed -i -e "s|^#*\s*verify=.*|verify=\"none\"|g" $SMBLDAP_CONF
fi

# Settings for smbldap_bind.conf ---------------------------------------------------------

# TODO: slaveDN
print_command_message 'sed -i -e "s|^#*\s*slaveDN=|#slaveDN=|g" $SMBLDAP_BIND_CONF'
sed -i -e "s|^#*\s*slaveDN=|#slaveDN=|g" $SMBLDAP_BIND_CONF
# TODO: slavePw
print_command_message 'sed -i -e "s|^#*\s*slavePw=|#slavePw=|g" $SMBLDAP_BIND_CONF'
sed -i -e "s|^#*\s*slavePw=|#slavePw=|g" $SMBLDAP_BIND_CONF
# masterDN
print_command_message 'sed -i -e "s|^#*\s*masterDN=.*|masterDN=\"cn=Manager,dc=mysite,dc=example,dc=com\"|g" $SMBLDAP_BIND_CONF'
sed -i -e "s|^#*\s*masterDN=.*|masterDN=\"cn=Manager,dc=mysite,dc=example,dc=com\"|g" $SMBLDAP_BIND_CONF
# masterPw
print_command_message 'sed -i -e "s|^#*\s*masterPw=.*|masterPw=\"password2\"|g" $SMBLDAP_BIND_CONF'
sed -i -e "s|^#*\s*masterPw=.*|masterPw=\"password2\"|g" $SMBLDAP_BIND_CONF

# Settings for smb.conf ------------------------------------------------------------------
# TODO: 
INSERTATIONS="\t# These parameters were added for smb domain controller at `LC_ALL=en_US.UTF-8 date` ----------\n"
if [ "$BLP_ENABLE_TLS" = "true" ]; then
    INSERTATIONS="${INSERTATIONS}\tldap ssl = on\n"
else
    INSERTATIONS="${INSERTATIONS}\tldap ssl = off\n"
fi
INSERTATIONS="${INSERTATIONS}\tnt acl support = yes\n"
INSERTATIONS="${INSERTATIONS}\tsocket options = TCP_NODELAY SO_RCVBUF=8192 SO_SNDBUF=8192 SO_KEEPALIVE\n"
print_command_message 'sed -i -e "s|^(#*\s*\[global\]\s*)|\1${INSERTATIONS}|g" $SMB_CONF'
sed -i -e "s|^\(\s*\[global\]\s*\)|\1\n${INSERTATIONS}|g" $SMB_CONF


# Populate LDAP database -----------------------------------------------------------------
print_command_message 'smbldap-populate'
smbldap-populate

