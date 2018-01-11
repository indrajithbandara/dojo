#!/bin/bash

# script base dir
BLP_BASE_DIR=$1
BLP_BASE_SCRIPT=$2

# load environments
. ${BLP_BASE_DIR}/global.conf.sh

. ${BLP_BASE_DIR}/lib/Functions.sh

function main() {
    if [ ! "$BLP_SHUTDOWN_STATUS" = "restarted_after_buildng_samba_base" ]; then
        build_samba_base
        echo "####################################################################"
        echo "####################################################################"
        echo "Base instructions of building samba were finished but some of the rest instructions are not finished yet."
        echo "Please restart your Linux and then you run this script again."
        echo "example)"
        echo "> shutdown -r now"
        echo "> ${BLP_BASE_SCRIPT}"
        echo "####################################################################"
        echo "####################################################################"

        echo "restarted_after_buildng_samba_base" > ${BLP_SHUTDOWN_STAT_FILE}
        exit 0
    fi

    build_samba_pdc
}

function build_samba_base() {
    # Install packages -----------------------------------------------------------------------
    print_command_message "install_lacking_packages \"acl attr autoconf ...\""
    install_lacking_packages "acl attr autoconf bison build-essential 
                              debhelper dnsutils docbook-xml docbook-xsl flex gdb krb5-user
                              libacl1-dev libaio-dev libattr1-dev libblkid-dev libbsd-dev
                              libcap-dev libcups2-dev libgnutls-dev libjson-perl
                              libldap2-dev libncurses5-dev libpam0g-dev libparse-yapp-perl
                              libpopt-dev libreadline-dev perl perl-modules pkg-config
                              python-all-dev python-dev python-dnspython python-crypto
                              xsltproc zlib1g-dev" "$LINUX_FAMILY"

    print_command_message "install_lacking_packages acl attr autoconf ..."
    install_lacking_packages "samba samba-doc smbldap-tools smbclient" "$LINUX_FAMILY"

    # Setting DNS ----------------------------------------------------------------------------
    # print_command_message "replace_debian_interface.pl \"${BLP_INTERFACE}\" \"dns-nameservers\" \"${SMB_BACKEND_DNS_IP}\" /etc/network/interfaces"
    # replace_debian_interface.pl "${BLP_INTERFACE}" "dns-nameservers" "${SMB_BACKEND_DNS_IP}" /etc/network/interfaces
    # print_command_message "replace_debian_interface.pl \"${BLP_INTERFACE}\" \"dns-search\" \"${BLP_DOMAIN}\" /etc/network/interfaces"
    # replace_debian_interface.pl "${BLP_INTERFACE}" "dns-search" "${BLP_DOMAIN}" /etc/network/interfaces

    print_command_message "Restert networking"
    ifdown ${BLP_INTERFACE} && ifup ${BLP_INTERFACE}

    # Adding samba schemes -------------------------------------------------------------------
    export SAMBA_LDIF=$(find /usr/share/doc/samba -type f -regextype posix-extended -regex '.*/samba.ldif(.gz)?$')
    export FILE_COUNT=$(echo "$SAMBA_LDIF" | wc -l)
    if [ ! "$FILE_COUNT" = "1" ]; then
        echo "Found multi samba.ldif files or missing it. Finished..."
        exit 1
    fi

    # Adding samba schema
    ## print_command_message "ldapadd -Y EXTERNAL -H ldapi:/// -f $SAMBA_LDIF"
    ## if [ $(LANG=C file $SAMBA_LDIF | grep ': gzip compressed data, ' > /dev/null 2>&1; echo $?) = 0 ]; then
    ##     gunzip -c $SAMBA_LDIF
    ## else
    ##     cat $SAMBA_LDIF
    ## fi | ldapadd -Y EXTERNAL -H ldapi:///

    # Create indexes
    ## if [ "$BLP_BACKEND" = "mdb" ]; then
    ##     print_command_message "cat ./lib/ldifs/smbldap/create_indexes.ldif"
    ##     cat ./lib/ldifs/smbldap/create_indexes.ldif

    ##     print_command_message "ldapmodify -x -D cn=config -w password -f ./lib/ldifs/smbldap/create_indexes.ldif"
    ##     ldapmodify -x -D cn=config -w password -f ./lib/ldifs/smbldap/create_indexes.ldif
    ## elif [ "$BLP_BACKEND" = "hdb"  ]; then
    ##     print_command_message "cat ./lib/ldifs/smbldap/create_indexes_hdb.ldif"
    ##     cat ./lib/ldifs/smbldap/create_indexes_hdb.ldif

    ##     print_command_message "ldapmodify -x -D cn=config -w password -f ./lib/ldifs/smbldap/create_indexes_hdb.ldif"
    ##     ldapmodify -x -D cn=config -w password -f ./lib/ldifs/smbldap/create_indexes_hdb.ldif
    ## fi

    # Backuping files ------------------------------------------------------------------------
    BACKUP_DATE=$(date +%Y%m%d%H%M%S)
    if [ -f "$SMB_LDAP_CONF" ]; then
        print_command_message "cp -p ${SMB_LDAP_CONF} ${SMB_LDAP_CONF}.${BACKUP_DATE}"
        cp -p ${SMB_LDAP_CONF} ${SMB_LDAP_CONF}.${BACKUP_DATE}
    fi
    if [ -f "$SMB_LDAP_BIND_CONF" ]; then
        print_command_message "cp -p ${SMB_LDAP_BIND_CONF} ${SMB_LDAP_BIND_CONF}.${BACKUP_DATE}"
        cp -p ${SMB_LDAP_BIND_CONF} ${SMB_LDAP_BIND_CONF}.${BACKUP_DATE}
    fi
    if [ -f "$SMB_CONF" ]; then
        print_command_message "mv ${SMB_CONF} ${SMB_CONF}.${BACKUP_DATE}"
        mv ${SMB_CONF} ${SMB_CONF}.${BACKUP_DATE}
    fi
    if [ -f "$SMB_KRB_CONF" ]; then
        print_command_message "cp -p ${SMB_KRB_CONF} ${SMB_KRB_CONF}.${BACKUP_DATE}"
        cp -p ${SMB_KRB_CONF} ${SMB_KRB_CONF}.${BACKUP_DATE}
    fi

    # Modify krb -----------------------------------------------------------------------------
    ## sed -i -e "s|^\s*default_realm = .*|\tdefault_realm = ${SMB_REALM}|" $SMB_KRB_CONF
    ##
    ## REG_SMB_REALM=$(echo $SMB_REALM | sed -e 's|\.|\\\.|g')
    ## if [ ! $(egrep -q "^\s*${REG_SMB_REALM}\s*=" $SMB_KRB_CONF; echo $?) = 0 ]; then
    ##     REALM_DEFINITIONS="\t${SMB_REALM} = {\n\t\tkdc = ldap\n\t\tadmin_server = ldap\n\t}"
    ##     sed -i -e "s|^\[realms\]|\[realms\]\n${REALM_DEFINITIONS}|" $SMB_KRB_CONF
    ## fi

    # samba-tool -----------------------------------------------------------------------------
    print_command_message "samba-tool domain provision --use-rfc2307 --realm=${SMB_REALM} --server-role=${SMB_SERVER_ROLE} --dns-backend=${SMB_DNS_BACKEND} --domain=${SMB_DOMAIN} --host-name=${SMB_HOST_NAME} --host-ip=${SMB_HOST_IP} --adminpass=${SMB_ADMIN_PASS} --option=\"interfaces=lo ${BLP_INTERFACE}\" --option=\"bind interfaces only=yes\""
    samba-tool domain provision --use-rfc2307           \
            --realm=${SMB_REALM}                        \
            --server-role=${SMB_SERVER_ROLE}            \
            --dns-backend=${SMB_DNS_BACKEND}            \
            --domain=${SMB_DOMAIN}                      \
            --host-name=${SMB_HOST_NAME}                \
            --host-ip=${SMB_HOST_IP}                    \
            --adminpass=${SMB_ADMIN_PASS}               \
            --option="interfaces=lo ${BLP_INTERFACE}"   \
            --option="bind interfaces only=yes"

    # TODO:
    # With interactive
    # samba-tool domain provision --use-rfc2307 --interactive --option="interfaces=lo eth0" --option="bind interfaces only=yes"

    # TODO: 
    # dns-backends are ...
    #     "BIND9_FLATFILE", "BIND9_DLZ", "SAMBA_INTERNAL", "NONE"
    # in /usr/lib/python2.7/dist-packages/samba/provision/sambadns.py on ubuntu 14.04
}

function build_samba_pdc() {
    # TODO: After restarted OS

    # chack status
    print_command_message "smbclient -L localhost -U%"
    smbclient -L localhost -U%

    print_command_mesasge "smbclient //localhost/netlogon -UAdministrator -c 'ls'"
    echo ${SMB_ADMIN_PASS} | smbclient //localhost/netlogon -UAdministrator -c 'ls'


    print_command_message "cat /etc/resolv.conf"
    cat /etc/resolv.conf

    print_command_message "host -t SRV _ldap._tcp.${BLP_DOMAIN}"
    host -t SRV _ldap._tcp.${BLP_DOMAIN}

    print_command_message "host -t SRV _ldap._tcp.${BLP_DOMAIN}"
    host -t SRV _ldap._tcp.${BLP_DOMAIN}

    print_command_message "host -t A ${BLP_FQDN}"
    host -t A ${BLP_FQDN}

    # Symlink to a working sample configuration created during provisioning.
    print_command_message "ln -sf /var/lib/samba/private/krb5.conf ${SMB_KRB_CONF}"
    ln -sf /var/lib/samba/private/krb5.conf ${SMB_KRB_CONF}

    # Create a ticket for administrator
    print_command_message "kinit administrator@${SMB_REALM}"
    echo "${SMB_ADMIN_PASS}" | kinit administrator@${SMB_REALM}

    print_command_message "klist"
    klist
}

main


############################################################
# TODO:
exit 0
############################################################

