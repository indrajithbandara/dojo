#!/bin/bash

# Install packages
if [ "$LINUX_FAMILY" = "RedHat" ]; then

libacl-devel libblkid-devel gnutls-devel \
    install_lacking_packages "libacl-devel libblkid-devel gnutls-devel readline-devel python-devel gdb pkgconfig libattr-devel krb5-workstation python-crypto" "$LINUX_FAMILY"
    install_lacking_packages "samba smbldap-tools" "$LINUX_FAMILY"

elif [ "$LINUX_FAMILY" = "Debian" ]; then
    install_lacking_packages "acl attr autoconf bison build-essential 
                              debhelper dnsutils docbook-xml docbook-xsl flex gdb krb5-user
                              libacl1-dev libaio-dev libattr1-dev libblkid-dev libbsd-dev
                              libcap-dev libcups2-dev libgnutls-dev libjson-perl
                              libldap2-dev libncurses5-dev libpam0g-dev libparse-yapp-perl
                              libpopt-dev libreadline-dev perl perl-modules pkg-config
                              python-all-dev python-dev python-dnspython python-crypto
                              xsltproc zlib1g-dev"

    install_lacking_packages "samba samba-doc smbldap-tools"
fi

# Usually "/usr/share/doc/samba/LDAP/samba.ldif"
SAMBA_LDIF=$(find /usr/share/doc/samba -type f -regex '.*/samba.ldif$')
FILE_COUNT=$(echo "$SAMBA_LDIF" | wc -l)
if [ ! "$FILE_COUNT" = "1" ]; then
    echo "Found multi samba.ldif files or missing it. Finished..."
    exit 1
fi

print_command_message "ldapadd -Y EXTERNAL -H ldapi:/// -f $SAMBA_LDIF"
ldapadd -Y EXTERNAL -H ldapi:/// -f $SAMBA_LDIF

# Create indexes
print_command_message "cat ./lib/ldifs/smbldap/create_indexes.ldif"
cat ./lib/ldifs/smbldap/create_indexes.ldif

print_command_message "ldapmodify -x -D cn=config -w password -f ./lib/ldifs/smbldap/create_indexes.ldif"
ldapmodify -x -D "cn=config" -w password -f ./lib/ldifs/smbldap/create_indexes.ldif

# Prepareing smbldap.conf and smbldap_bind.conf
BACKUP_DATE=$(date +%Y%m%d%H%M%S)
if [ -f "$SMB_LDAP_CONF" ]; then
    cp $SMB_LDAP_CONF ${SMB_LDAP_CONF}.${BACKUP_DATE}
else
    # TODO:
    true
fi

if [ -f "$SMB_LDAP_BIND_CONF" ]; then
    cp $SMB_LDAP_BIND_CONF ${SMB_LDAP_BIND_CONF}.${BACKUP_DATE}
else
    # TODO
    true
fi

cp ${SMB_CONF} ${SMB_CONF}.${BACKUP_DATE}

# Get localsid
LOCAL_SID=$(net getlocalsid | sed -e 's|SID for domain [^\s]\+ is: ||')
print_command_message "net getlocalsid -> $LOCAL_SID"

# Settings for smbldap.conf ---------------------------------------------------------

# SID
print_command_message 'sed -i -e "s|^#*\s*SID=.*|SID=\"$LOCAL_SID\"|g" $SMB_LDAP_CONF'
sed -i -e "s|^#*\s*SID=.*|SID=\"$LOCAL_SID\"|g" $SMB_LDAP_CONF
# sambaDomain
print_command_message 'sed -i -e "s|^#*\s*sambaDomain=.*|sambaDomain=\"MYSITE\"|g" $SMB_LDAP_CONF'
sed -i -e "s|^#*\s*sambaDomain=.*|sambaDomain=\"MYSITE\"|g" $SMB_LDAP_CONF
# TODO: comment slaveLDAP
print_command_message 'sed -i -e "s|^slaveLDAP=|#slaveLDAP=|g" $SMB_LDAP_CONF'
sed -i -e "s|^slaveLDAP=|#slaveLDAP=|g" $SMB_LDAP_CONF
# masterLDAP
print_command_message 'sed -i -e "s|^#*\s*masterLDAP=.*|masterLDAP=\"$MY_FQDN\"|g" $SMB_LDAP_CONF'
sed -i -e "s|^#*\s*masterLDAP=.*|masterLDAP=\"ldap://${BLP_FQDN}/\"|g" $SMB_LDAP_CONF
# suffix
print_command_message 'sed -i -e "s|^#*\s*suffix=.*|suffix=\"dc=mysite,dc=example,dc=com\"|g" $SMB_LDAP_CONF'
sed -i -e "s|^#*\s*suffix=.*|suffix=\"dc=mysite,dc=example,dc=com\"|g" $SMB_LDAP_CONF
# usersdn
print_command_message 'sed -i -e "s|^#*\s*usersdn=.*|usersdn=\"ou=Users,\${suffix}\"|g" $SMB_LDAP_CONF'
sed -i -e "s|^#*\s*usersdn=.*|usersdn=\"ou=Users,\${suffix}\"|g" $SMB_LDAP_CONF
# TODO: computersdn
# groupsdn
print_command_message 'sed -i -e "s|^#*\s*groupsdn=.*|groupsdn=\"ou=Groups,\${suffix}\"|g" $SMB_LDAP_CONF'
sed -i -e "s|^#*\s*groupsdn=.*|groupsdn=\"ou=Groups,\${suffix}\"|g" $SMB_LDAP_CONF
# TODO: idmapdn
# mailDomain
print_command_message 'sed -i -e "s|^#*\s*mailDomain=.*|mailDomain=\"mysite.example.com\"|g" $SMB_LDAP_CONF'
sed -i -e "s|^#*\s*mailDomain=.*|mailDomain=\"mysite.example.com\"|g" $SMB_LDAP_CONF

# ldapTLS
if [ "${BLP_ENABLE_TLS}" = "true" ]; then
    print_command_message 'sed -i -e "s|^#*\s*ldapTLS=.*|ldapTLS=\"1\"|g" $SMB_LDAP_CONF'
    sed -i -e "s|^#*\s*ldapTLS=.*|ldapTLS=\"1\"|g" $SMB_LDAP_CONF
    # verify
    print_command_message 'sed -i -e "s|^#*\s*verify=.*|verify=\"require\"|g" $SMB_LDAP_CONF'
    sed -i -e "s|^#*\s*verify=.*|verify=\"require\"|g" $SMB_LDAP_CONF
    # cafile
    print_command_message 'sed -i -e "s|^#*\s*cafile=.*|cafile=\"/etc/pki/CA/certs/ca.pem\"|g" $SMB_LDAP_CONF'
    sed -i -e "s|^#*\s*cafile=.*|cafile=\"/etc/pki/CA/certs/ca.pem\"|g" $SMB_LDAP_CONF
    # clientcert
    print_command_message 'sed -i -e "s|^#*\s*clientcert=|#clientcert=|g" $SMB_LDAP_CONF'
    sed -i -e "s|^#*\s*clientcert=|#clientcert=|g" $SMB_LDAP_CONF
    # clientkey
    print_command_message 'sed -i -e "s|^#*\s*clientkey=|#clientkey=|g" $SMB_LDAP_CONF'
    sed -i -e "s|^#*\s*clientkey=|#clientkey=|g" $SMB_LDAP_CONF
else
    print_command_message 'sed -i -e "s|^#*\s*ldapTLS=.*|ldapTLS=\"0\"|g" $SMB_LDAP_CONF'
    sed -i -e "s|^#*\s*ldapTLS=.*|ldapTLS=\"0\"|g" $SMB_LDAP_CONF

    print_command_message 'sed -i -e "s|^#*\s*verify=.*|verify=\"none\"|g" $SMB_LDAP_CONF'
    sed -i -e "s|^#*\s*verify=.*|verify=\"none\"|g" $SMB_LDAP_CONF
fi

# Settings for smbldap_bind.conf ---------------------------------------------------------

# TODO: slaveDN
print_command_message 'sed -i -e "s|^#*\s*slaveDN=|#slaveDN=|g" $SMB_LDAP_BIND_CONF'
sed -i -e "s|^#*\s*slaveDN=|#slaveDN=|g" $SMB_LDAP_BIND_CONF
# TODO: slavePw
print_command_message 'sed -i -e "s|^#*\s*slavePw=|#slavePw=|g" $SMB_LDAP_BIND_CONF'
sed -i -e "s|^#*\s*slavePw=|#slavePw=|g" $SMB_LDAP_BIND_CONF
# masterDN
print_command_message 'sed -i -e "s|^#*\s*masterDN=.*|masterDN=\"cn=Manager,dc=mysite,dc=example,dc=com\"|g" $SMB_LDAP_BIND_CONF'
sed -i -e "s|^#*\s*masterDN=.*|masterDN=\"cn=Manager,dc=mysite,dc=example,dc=com\"|g" $SMB_LDAP_BIND_CONF
# masterPw
print_command_message 'sed -i -e "s|^#*\s*masterPw=.*|masterPw=\"password2\"|g" $SMB_LDAP_BIND_CONF'
sed -i -e "s|^#*\s*masterPw=.*|masterPw=\"password2\"|g" $SMB_LDAP_BIND_CONF

## print_command_message 'sed -i -e "s|^#*\s*masterPw=.*|masterPw=\"p@ssword3\"|g" $SMB_LDAP_BIND_CONF'
## sed -i -e "s|^#*\s*masterPw=.*|masterPw=\"p@ssword3\"|g" $SMB_LDAP_BIND_CONF

# Settings for smb.conf ------------------------------------------------------------------

print_command_message "cp -f /usr/share/doc/smbldap-tools/smb.conf.example $SMB_CONF"
\cp -f /usr/share/doc/smbldap-tools/smb.conf.example $SMB_CONF

print_command_message "replace_smb_conf.pl 'global' 'workgroup'            'MYSITE'            $SMB_CONF"
replace_smb_conf.pl 'global' 'workgroup'            'MYSITE'            $SMB_CONF
#print_command_message "replace_smb_conf.pl 'global' 'netbios name'         'MYSITE-PDC'        $SMB_CONF"
#replace_smb_conf.pl 'global' 'netbios name'         'MYSITE-PDC'        $SMB_CONF
print_command_message "replace_smb_conf.pl 'global' 'netbios name'         'LDAP'        $SMB_CONF"
replace_smb_conf.pl 'global' 'netbios name'         'LDAP'        $SMB_CONF

print_command_message "replace_smb_conf.pl 'global' 'deadtime'             '10'                $SMB_CONF"
replace_smb_conf.pl 'global' 'deadtime'             '10'                $SMB_CONF

print_command_message "replace_smb_conf.pl 'global' 'log level'            '1'                 $SMB_CONF"
replace_smb_conf.pl 'global' 'log level'            '1'                 $SMB_CONF
print_command_message "replace_smb_conf.pl 'global' 'debug pid'            'yes'               $SMB_CONF"
replace_smb_conf.pl 'global' 'debug pid'            'yes'               $SMB_CONF
print_command_message "replace_smb_conf.pl 'global' 'debug uid'            'yes'               $SMB_CONF"
replace_smb_conf.pl 'global' 'debug uid'            'yes'               $SMB_CONF
print_command_message "replace_smb_conf.pl 'global' 'syslog'               '3'                 $SMB_CONF"
replace_smb_conf.pl 'global' 'syslog'               '3'                 $SMB_CONF
print_command_message "replace_smb_conf.pl 'global' 'utmp'                 'yes'               $SMB_CONF"
replace_smb_conf.pl 'global' 'utmp'                 'yes'               $SMB_CONF

print_command_message "replace_smb_conf.pl 'global' 'passdb backend'       'ldapsam:\"ldap://ldap.mysite.example.com/\"'       $SMB_CONF"
replace_smb_conf.pl 'global' 'passdb backend'       'ldapsam:"ldap://ldap.mysite.example.com/"'       $SMB_CONF
print_command_message "replace_smb_conf.pl 'global' 'security'             'user'              $SMB_CONF"
replace_smb_conf.pl 'global' 'security'             'user'              $SMB_CONF
print_command_message "replace_smb_conf.pl 'global' 'domain logons'        'yes'               $SMB_CONF"
replace_smb_conf.pl 'global' 'domain logons'        'yes'               $SMB_CONF
print_command_message "replace_smb_conf.pl 'global' 'os level'             '64'                $SMB_CONF"
replace_smb_conf.pl 'global' 'os level'             '64'                $SMB_CONF
print_command_message "replace_smb_conf.pl 'global' 'logon path'           ''                  $SMB_CONF"
replace_smb_conf.pl 'global' 'logon path'           ''                  $SMB_CONF
print_command_message "replace_smb_conf.pl 'global' 'logon home'           ''                  $SMB_CONF"
replace_smb_conf.pl 'global' 'logon home'           ''                  $SMB_CONF
print_command_message "replace_smb_conf.pl 'global' 'logon drive'          ''                  $SMB_CONF"
replace_smb_conf.pl 'global' 'logon drive'          ''                  $SMB_CONF
print_command_message "replace_smb_conf.pl 'global' 'logon script'         ''                  $SMB_CONF"
replace_smb_conf.pl 'global' 'logon script'         ''                  $SMB_CONF

if [ "$BLP_ENABLE_TLS" = "true" ]; then
    print_command_message "replace_smb_conf.pl 'global' 'ldap ssl'         'on'                $SMB_CONF"
    replace_smb_conf.pl 'global' 'ldap ssl'         'on'                $SMB_CONF
else
    print_command_message "replace_smb_conf.pl 'global' 'ldap ssl'         'off'               $SMB_CONF"
    replace_smb_conf.pl 'global' 'ldap ssl'         'off'               $SMB_CONF
fi
print_command_message "replace_smb_conf.pl 'global' 'ldap admin dn'        'cn=Manager,dc=mysite,dc=example,dc=com' $SMB_CONF"
replace_smb_conf.pl 'global' 'ldap admin dn'        'cn=Manager,dc=mysite,dc=example,dc=com' $SMB_CONF
print_command_message "replace_smb_conf.pl 'global' 'ldap delete dn'       'no'                $SMB_CONF"
replace_smb_conf.pl 'global' 'ldap delete dn'       'no'                $SMB_CONF

print_command_message "replace_smb_conf.pl 'global' 'ldap password sync'   'yes'               $SMB_CONF"
replace_smb_conf.pl 'global' 'ldap password sync'   'yes'               $SMB_CONF

print_command_message "replace_smb_conf.pl 'global' 'ldap suffix'          'dc=example,dc=com' $SMB_CONF"
replace_smb_conf.pl 'global' 'ldap suffix'          'dc=mysite,dc=example,dc=com' $SMB_CONF
print_command_message "replace_smb_conf.pl 'global' 'ldap user suffix'     'ou=Users'          $SMB_CONF"
replace_smb_conf.pl 'global' 'ldap user suffix'     'ou=Users'          $SMB_CONF
print_command_message "replace_smb_conf.pl 'global' 'ldap group suffix'    'ou=Groups'         $SMB_CONF"
replace_smb_conf.pl 'global' 'ldap group suffix'    'ou=Groups'         $SMB_CONF
print_command_message "replace_smb_conf.pl 'global' 'ldap machine suffix'  'ou=Computers'      $SMB_CONF"
replace_smb_conf.pl 'global' 'ldap machine suffix'  'ou=Computers'      $SMB_CONF
print_command_message "replace_smb_conf.pl 'global' 'ldap idmap suffix'    'ou=Idmap'          $SMB_CONF"
replace_smb_conf.pl 'global' 'ldap idmap suffix'    'ou=Idmap'          $SMB_CONF

print_command_message "replace_smb_conf.pl 'global' 'add user script'      \"/usr/sbin/smbldap-useradd -m '%u' -t 1\" $SMB_CONF"
replace_smb_conf.pl 'global' 'add user script'      "/usr/sbin/smbldap-useradd -m '%u' -t 1" $SMB_CONF
print_command_message "replace_smb_conf.pl 'global' 'rename user script'   \"/usr/sbin/smbldap-usermod -r '%unew' '%uold'\" $SMB_CONF"
replace_smb_conf.pl 'global' 'rename user script'   "/usr/sbin/smbldap-usermod -r '%unew' '%uold'" $SMB_CONF
print_command_message "replace_smb_conf.pl 'global' 'delete user script'   \"/usr/sbin/smbldap-userdel '%u'\" $SMB_CONF"
replace_smb_conf.pl 'global' 'delete user script'   "/usr/sbin/smbldap-userdel '%u'" $SMB_CONF
print_command_message "replace_smb_conf.pl 'global' 'set primary group script' \"/usr/sbin/smbldap-usermod -g '%g' '%u'\" $SMB_CONF"
replace_smb_conf.pl 'global' 'set primary group script' "/usr/sbin/smbldap-usermod -g '%g' '%u'" $SMB_CONF
print_command_message "replace_smb_conf.pl 'global' 'add group script'     \"/usr/sbin/smbldap-groupadd -p '%g'\" $SMB_CONF"
replace_smb_conf.pl 'global' 'add group script'     "/usr/sbin/smbldap-groupadd -p '%g'" $SMB_CONF
print_command_message "replace_smb_conf.pl 'global' 'delete group script'  \"/usr/sbin/smbldap-groupdel '%g'\" $SMB_CONF"
replace_smb_conf.pl 'global' 'delete group script'  "/usr/sbin/smbldap-groupdel '%g'" $SMB_CONF
print_command_message "replace_smb_conf.pl 'global' 'delete group script'  \"/usr/sbin/smbldap-groupdel '%g'\" $SMB_CONF"
replace_smb_conf.pl 'global' 'add user to group script' "/usr/sbin/smbldap-groupmod -m '%u' '%g'" $SMB_CONF
print_command_message "replace_smb_conf.pl 'global' 'delete user from group script' \"/usr/sbin/smbldap-groupmod -x '%u' '%g'\" $SMB_CONF"
replace_smb_conf.pl 'global' 'delete user from group script' "/usr/sbin/smbldap-groupmod -x '%u' '%g'" $SMB_CONF
print_command_message "replace_smb_conf.pl 'global' 'add machine script'   \"/usr/sbin/smbldap-useradd -w '%u' -t 1\" $SMB_CONF"
replace_smb_conf.pl 'global' 'add machine script'   "/usr/sbin/smbldap-useradd -w '%u' -t 1" $SMB_CONF

print_command_message "replace_smb_conf.pl 'global' 'nt acl support'       'yes'               $SMB_CONF"
replace_smb_conf.pl 'global' 'nt acl support'       'yes'               $SMB_CONF
print_command_message "replace_smb_conf.pl 'global' 'socket options'       'TCP_NODELAY SO_RCVBUF=8192 SO_SNDBUF=8192 SO_KEEPALIVE' $SMB_CONF"
replace_smb_conf.pl 'global' 'socket options'       'TCP_NODELAY SO_RCVBUF=8192 SO_SNDBUF=8192 SO_KEEPALIVE' $SMB_CONF

# Change permissions ---------------------------------------------------------------------
print_command_message "chmod 644 $SMB_LDAP_CONF"
chmod 644 $SMB_LDAP_CONF
print_command_message "chmod 600 $SMB_LDAP_BIND_CONF"
chmod 600 $SMB_LDAP_BIND_CONF

# Populate LDAP database -----------------------------------------------------------------
print_command_message 'smbpasswd -w password2    # password for cn=Manager,dc=mysite,dc=example,dc=com'
smbpasswd -w password2

######
# TODO: Execute below command after...
#   * /etc/hosts file is editted correctly
#   * Registered dn="cn=Manager,dc=mysite,dc=example,dc=com"
#   * Registered password of cn=Manager,dc=mysite,dc=example,dc=com

print_command_message 'smbldap-populate'
smbldap-populate 1>&2

# Start samba ----------------------------------------------------------------------------
print_command_message "systemctl start smb.service"
systemctl restart smb.service
print_command_message "systemctl enable smb.service"
systemctl enable smb.service

# TODO: nmb
print_command_message "systemctl restart nmb.service"
systemctl restart nmb.service

sync_groups_between_domain_and_unix

# reference-> http://www.unixmen.com/setup-samba-domain-controller-with-openldap-backend-in-ubuntu-13-04/
# 1.
#   useradd <username>
# 2.
#   smbldap-useradd -a -G 'Domain Users' -m -s /bin/bash -d /home/user2 -F "" -P user1
# 3.
#  net sam rights grant user1 SeMachineAccountPrivilege
#

useradd Administrator
smbldap-useradd -a -G 'Domain Users' -m -s /bin/bash -d /home/Administrator -F "" -P Administrator
smbpasswd -e Administrator
net sam rights grant Administrator SeMachineAccountPrivilege
useradd -M -g smb_domain_computers -s /bin/false my-pc$

useradd rokuro-suzuki
smbldap-useradd -a -G 'Domain Users' -m -s /bin/bash -d /home/rokuro-suzuki -F "" -P rokuro-suzuki
smbpasswd -e Administrator
net sam rights grant Administrator SeMachineAccountPrivilege
useradd -M -g smb_domain_computers -s /bin/false my-pc$


## # Creating smb user for test -------------------------------------------------------------
## print_command_message "add_user_and_smb_groups \"shiro-suzuki\" 1500 1500 \"Domain Users\" \"pw-shiro-suzuki\""
## add_user_and_smb_groups "shiro-suzuki" 1500 1500 "Domain Users" "pw-shiro-suzuki"
## 
## # Adding correlating groups to unix ------------------------------------------------------
## sync_groups_between_domain_and_unix
## 
## print_command_message "net groupmap list"
## net groupmap list
## 
## # Adding test Domain Group  --------------------------------------------------------------
## print_command_message "smbldap-groupadd -g 1010 -a \"Office Users\""
## smbldap-groupadd -g 1010 -a "Office Users"
## 
## print_command_message "sync_groups_between_domain_and_unix"
## sync_groups_between_domain_and_unix
## 
## print_command_message "net groupmap list"
## net groupmap list
## 
## # Adding test User  ----------------------------------------------------------------------
## print_command_message "add_user_and_smb_groups \"goro-suzuki\" 1501 1501 \"Office Users\" \"pw-goro-suzuki\""
## add_user_and_smb_groups "goro-suzuki" 1501 1501 "Office Users" "pw-goro-suzuki"
## 
## # Adding Windows computer ----------------------------------------------------------------
## useradd -M -g 515 -s /bin/false goro-suzuki-computer$


