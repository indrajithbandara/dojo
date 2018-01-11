#!/bin/bash

# Load common functions -------------------------------------------------------------
if [ -r ./lib/Functions.sh ]; then
    . ./lib/Functions.sh
else
    echo "A file ./lib/Functions.sh was not found. Finished..."
    exit 1
fi

if [ -r ./global.conf.sh ]; then
    . ./global.conf.sh
else
    echo "A file ./global.conf.sh was not found. Finished..."
    exit 1
fi

function main() {
    # Build openldap base and Samba PDC ------------------------------------------------------------
    if [ ! -f "./milestones/done_set_basic_env" ]; then
        set_basic_env && touch "./milestones/done_set_basic_env" \
                || die "Failed to function set_basic_env"
    fi

    exit 0

    install_dependencies
    build_openldap
    build_samba_pdc_backends_openldap
}

function set_basic_env() {
    # Adding path to script ---------------------------------------------------------
    print_command_message "Adding path to script"
    add_path_if_not_exist ${BLP_BASE_DIR}/py
    add_path_if_not_exist /usr/local/samba/bin
    add_path_if_not_exist /usr/local/samba/sbin
    echo ${PATH}

    # Add hosts if not existed ------------------------------------------------------
    cp -p /etc/hosts /etc/hosts.`date +%Y%m%d%H%M%S`
    AddHosts.py ${BLP_INTERFACE_IP} ${BLP_FQDN} /etc/hosts
}

function install_dependencies() {
    # install packages
    if [ "$LINUX_DISTRIBUTION" = "Fedora" ]; then
        # TODO:
        # dnf update

        # Install openldap packages and samba
        install_lacking_packages "openldap openldap-clients openldap-servers" "$LINUX_FAMILY"
        install_lacking_packages "libacl-devel libblkid-devel gnutls-devel readline-devel python-devel gdb pkgconfig libattr-devel krb5-workstation python-crypto" "$LINUX_FAMILY"
        install_lacking_packages "samba smbldap-tools" "$LINUX_FAMILY"

    elif [ "$LINUX_DISTRIBUTION" = "Ubuntu" ] || [ "$LINUX_DISTRIBUTION" = "Debian" ]; then
        # TODO:
        # apt-get update

        # Install openldap packages and samba
        install_lacking_packages "slapd ldap-utils libnss-ldap" "$LINUX_FAMILY"
        install_lacking_packages "acl attr autoconf bison build-essential
                                  debhelper dnsutils docbook-xml docbook-xsl flex gdb krb5-user
                                  libacl1-dev libaio-dev libattr1-dev libblkid-dev libbsd-dev
                                  libcap-dev libcups2-dev libgnutls28-dev libjson-perl
                                  libldap2-dev libncurses5-dev libpam0g-dev libparse-yapp-perl
                                  libpopt-dev libreadline-dev perl perl-modules pkg-config
                                  python-all-dev python-dev python-dnspython python-crypto
                                  xsltproc zlib1g-dev" "$LINUX_FAMILY"
        install_lacking_packages "samba samba-doc smbldap-tools" "$LINUX_FAMILY"
    fi
}

function build_openldap() {

    if [ "$LINUX_DISTRIBUTION" = "Fedora" ]; then
        # starting openldap
        systemctl start slapd
        systemctl enable slapd

        # Open ports for ldap and Samba
        print_command_message "firewall-cmd --permanent --zone=FedoraServer --query-service=ldap"
        firewall-cmd --permanent --zone=FedoraServer --add-port=137/udp
        firewall-cmd --permanent --zone=FedoraServer --add-port=138/udp
        firewall-cmd --permanent --zone=FedoraServer --add-port=445/tcp
        firewall-cmd --permanent --zone=FedoraServer --add-port=389/tcp
        firewall-cmd --permanent --zone=FedoraServer --add-port=636/tcp
        systemctl reload firewalld.service

    elif [ "$LINUX_DISTRIBUTION" = "Ubuntu" ] || [ "$LINUX_DISTRIBUTION" = "Debian" ]; then

        # TODO: To use update-rc.d is duplicated method in Ubuntu 14.04.3 LTS.
        #       If you use it, the error will be occurred like below.
        #       - In the log.samba --------------------------------------------------------------------
        #       [2015/10/17 10:54:16.743321,  0] ../source4/ldap_server/ldap_server.c:821(add_socket)
        #         ldapsrv failed to bind to 0.0.0.0:389 - NT_STATUS_ADDRESS_ALREADY_ASSOCIATED
        #       ---------------------------------------------------------------------------------------
        service slapd start
        update-rc.d slapd defaults
    fi

    # confirm current settings of slapd
    ldapsearch -LLL -Y EXTERNAL -H ldapi:/// -b "cn=config" "(olcDatabase=*)"

    # adding new root password as "password"
    # TODO: not tested yes on Fedora etc...
    ROOT_PW=$(slappasswd -s ${BLP_CONFIG_ROOT_PW})
    sed -i -e "s|%%ROOT_PW%%|${ROOT_PW}|g"                   ./lib/ldifs/starting_ldap/set_config_rootpw.ldif
    sed -i -e "s|%%CONFIG_ROOT_DN%%|${BLP_CONFIG_ROOT_DN}|g" ./lib/ldifs/starting_ldap/set_config_rootpw.ldif
    ldapcompare -Y EXTERNAL -H ldapi:/// "olcDatabase={0}config,cn=config" "olcRootDN:" > /dev/null 2>&1
    COMPARE_RESULT=$?
    if [ $COMPARE_RESULT -eq 5 ]; then
        # Compare false -> exist olcRootDN
        sed -i -e "s|%%ROOT_DN_OPERATION%%|replace|g" ./lib/ldifs/starting_ldap/set_config_rootpw.ldif
    else
        # Undefined(16) or other result -> not exist olcRootDN
        sed -i -e "s|%%ROOT_DN_OPERATION%%|add|g" ./lib/ldifs/starting_ldap/set_config_rootpw.ldif
    fi
    ldapadd -Y EXTERNAL -H ldapi:/// -f ./lib/ldifs/starting_ldap/set_config_rootpw.ldif

    # confirm slapd's root password
    ldapsearch -LLL -D "${BLP_CONFIG_ROOT_DN}" -w ${BLP_CONFIG_ROOT_PW} -b "olcDatabase={0}config,cn=config" "(olcDatabase=*)"

    # Adding schemes --------------------------------------------------------------------
    ldapadd -Y EXTERNAL -H ldapi:/// -f ${BLP_ETC_LDAP_DIR}/schema/cosine.ldif 2> /dev/null || \
            ([ $? = 80 ] && echo "Some schemes are already existed.")
    ldapadd -Y EXTERNAL -H ldapi:/// -f ${BLP_ETC_LDAP_DIR}/schema/nis.ldif 2> /dev/null || \
        ([ $? = 80 ] && echo "Some schemes are already existed.")
    ldapadd -Y EXTERNAL -H ldapi:/// -f ${BLP_ETC_LDAP_DIR}/schema/inetorgperson.ldif 2> /dev/null || \
            ([ $? = 80 ] && echo "Some schemes are already existed.")

    # Get monitor dn
    MONITOR_DB=$(get_monitor_chars)
    if [ ! "${MONITOR_DB}" = "" ]; then
        # Set monitor ACL
        sed -i -e "s|%%MONITOR_DB%%|${MONITOR_DB}|g"     ./lib/ldifs/starting_ldap/set_monitor_acl.ldif
        sed -i -e "s|%%CN_MANAGER%%|${BLP_CN_MANAGER}|g" ./lib/ldifs/starting_ldap/set_monitor_acl.ldif
        ldapmodify -Y EXTERNAL -H ldapi:/// -f           ./lib/ldifs/starting_ldap/set_monitor_acl.ldif
    fi

    # Replacing backends and domain components...
    # Replacing backends such like "{1}mdb" or "{1}hdb" etc...
    # And replacing domain component such like "dc=mysite,dc=example,dc=com"

    # Get backend of OpenLDAP
    BLP_BACKEND=$(get_backend_chars)
    if [ "${BLP_BACKEND}" = "" ]; then
        echo "Failed to get backends in your OpenLDAP. Terminating..."
        exit 1
    fi

    BACKEND_PW=$(slappasswd -s ${BLP_BACKEND_PW})
    exist_olc_root_pw ${BLP_BACKEND}
    EXISTANCE_ROOT_PW=$?

    sed -i -e "s|%%BLP_BACKEND%%|${BLP_BACKEND}|g"               ./lib/ldifs/starting_ldap/set_backends_rootdn.ldif
    sed -i -e "s|%%DOMAIN_COMPONENT%%|${BLP_DOMAIN_COMPONENT}|g" ./lib/ldifs/starting_ldap/set_backends_rootdn.ldif
    sed -i -e "s|%%CN_MANAGER%%|${BLP_CN_MANAGER}|g"             ./lib/ldifs/starting_ldap/set_backends_rootdn.ldif
    if [ ${EXISTANCE_ROOT_PW} -eq 0 ]; then
        sed -i -e "s|%%ROOT_PW_OPERATION%%|replace|g"            ./lib/ldifs/starting_ldap/set_backends_rootdn.ldif
    else
        sed -i -e "s|%%ROOT_PW_OPERATION%%|add|g"                ./lib/ldifs/starting_ldap/set_backends_rootdn.ldif
    fi
    sed -i -e "s|%%BACKEND_PW%%|${BACKEND_PW}|g"                 ./lib/ldifs/starting_ldap/set_backends_rootdn.ldif

    print_command_message "ldapmodify -Y EXTERNAL -H ldapi:/// -f ./lib/ldifs/starting_ldap/set_backends_rootdn.ldif"
    ldapmodify -Y EXTERNAL -H ldapi:/// -f ./lib/ldifs/starting_ldap/set_backends_rootdn.ldif

    # Create base
    sed -i -e "s|%%DOMAIN_COMPONENT%%|${BLP_DOMAIN_COMPONENT}|g" ./lib/ldifs/starting_ldap/create_base.ldif
    sed -i -e "s|%%DOMAIN%%|${SMB_DOMAIN,,}|g"                   ./lib/ldifs/starting_ldap/create_base.ldif
    sed -i -e "s|%%ORGANIZATION%%|${BLP_ORGANIZATION}|g"         ./lib/ldifs/starting_ldap/create_base.ldif

    print_command_message "ldapadd -x -D \"${BLP_CN_MANAGER}\" -w ${BLP_BACKEND_PW} -f ./lib/ldifs/starting_ldap/create_base.ldif"
    ldapadd -x -D "${BLP_CN_MANAGER}" -w ${BLP_BACKEND_PW} -f ./lib/ldifs/starting_ldap/create_base.ldif
}

function build_samba_pdc_backends_openldap() {

    # Adding path to script ---------------------------------------------------------
    ## print_command_message "Adding path to script"
    ## add_path_if_not_exist ${BLP_BASE_DIR}/py
    ## add_path_if_not_exist /usr/local/samba/bin
    ## add_path_if_not_exist /usr/local/samba/sbin
    ## echo ${PATH}

    # Add hosts if not existed ------------------------------------------------------
    cp -p /etc/hosts /etc/hosts.`date +%Y%m%d%H%M%S`
    AddHosts.py ${BLP_INTERFACE_IP} ${BLP_FQDN} /etc/hosts

    # Add samba schemes -------------------------------------------------------------
    # Usually "/usr/share/doc/samba/LDAP/samba.ldif"
    SAMBA_LDIF=$(find /usr/share/doc/samba -type f -regextype posix-extended -regex '.*/samba.ldif(.gz)?$')
    FILE_COUNT=$(echo "$SAMBA_LDIF" | wc -l)
    if [ "$SAMBA_LDIF" = "" ] || [ $FILE_COUNT -gt 1 ]; then
        echo "Found multi samba.ldif files or missing it in \"/usr/share/doc/samba\". Finished..."
        exit 1
    fi
    if [[ "${SAMBA_LDIF}" =~ ^.*\.gz$ ]]; then
        gunzip -c ${SAMBA_LDIF} | ldapadd -Y EXTERNAL -H ldapi:///
    else
        cat ${SAMBA_LDIF}       | ldapadd -Y EXTERNAL -H ldapi:///
    fi

    # Create base indexes
    sed -i -e "s|%%BLP_BACKEND%%|${BLP_BACKEND}|g"                       ./lib/ldifs/starting_ldap/create_indexes.ldif
    print_command_message "ldapmodify -x -D \"${BLP_CONFIG_ROOT_DN}\" -w ${BLP_CONFIG_ROOT_PW} -f ./lib/ldifs/starting_ldap/create_indexes.ldif"
    ldapmodify -x -D "${BLP_CONFIG_ROOT_DN}" -w ${BLP_CONFIG_ROOT_PW} -f ./lib/ldifs/starting_ldap/create_indexes.ldif

    # Create samba indexes
    sed -i -e "s|%%BLP_BACKEND%%|${BLP_BACKEND}|g"                       ./lib/ldifs/smbldap/create_indexes.ldif
    print_command_message "ldapmodify -x -D \"${BLP_CONFIG_ROOT_DN}\" -w ${BLP_CONFIG_ROOT_PW} -f ./lib/ldifs/smbldap/create_indexes.ldif"
    ldapmodify -x -D "${BLP_CONFIG_ROOT_DN}" -w ${BLP_CONFIG_ROOT_PW} -f ./lib/ldifs/smbldap/create_indexes.ldif

    # Prepareing smbldap.conf and smbldap_bind.conf
    BACKUP_DATE=$(date +%Y%m%d%H%M%S)

    # Restore smbldap_bind.conf if not exist ----------------------------------------
    if [ ! -f "${SMB_LDAP_BIND_CONF}" ]; then
        if [ ! -r "${SMB_LDAP_BIND_CONF_EXAMPLE}" ]; then
            echo    "Cannot arrange a file smbldap_bind.conf."
            echo -n "Neither \${SMB_LDAP_BIND_CONF} = ${SMB_LDAP_BIND_CONF} nor "
            echo    "\${SMB_LDAP_BIND_CONF_EXAMPLE} = ${SMB_LDAP_BIND_CONF_EXAMPLE} is already exist."
            touch ${SMB_LDAP_BIND_CONF}
        else
            if [[ "${SMB_LDAP_BIND_CONF_EXAMPLE}" =~ ^.*\.gz$ ]]; then
                gunzip -c ${SMB_LDAP_BIND_CONF_EXAMPLE} > ${SMB_LDAP_BIND_CONF}
            else
                cat ${SMB_LDAP_BIND_CONF_EXAMPLE} > ${SMB_LDAP_BIND_CONF}
            fi
            chown root:root ${SMB_LDAP_BIND_CONF}
            chmod 600 ${SMB_LDAP_BIND_CONF}
        fi
    fi
    \cp -f ${SMB_LDAP_BIND_CONF} ${SMB_LDAP_BIND_CONF}.${BACKUP_DATE}

    # Restore smbldap.conf if not exist ---------------------------------------------
    if [ ! -f "${SMB_LDAP_CONF}" ]; then
        if [ ! -r "${SMB_LDAP_CONF_EXAMPLE}" ]; then
            echo    "Cannot arrange a file smbldap.conf."
            echo -n "Neither \${SMB_LDAP_CONF} = ${SMB_LDAP_CONF} nor "
            echo    "\${SMB_LDAP_CONF_EXAMPLE} = ${SMB_LDAP_CONF_EXAMPLE} is already exist."
            touch ${SMB_LDAP_CONF}
        else
            # Example file is existed
            if [[ "${SMB_LDAP_CONF_EXAMPLE}" =~ ^.*\.gz$ ]]; then
                gunzip -c ${SMB_LDAP_CONF_EXAMPLE} > ${SMB_LDAP_CONF}
            else
                cat ${SMB_LDAP_CONF_EXAMPLE} > ${SMB_LDAP_CONF}
            fi
        fi
        chown root:root ${SMB_LDAP_CONF}
        chmod 644 ${SMB_LDAP_CONF}
    fi
    \cp -f ${SMB_LDAP_CONF} ${SMB_LDAP_CONF}.${BACKUP_DATE}

    # Restore smb.conf
    if [ -r ${SMB_CONF} ]; then
        cp ${SMB_CONF} ${SMB_CONF}.${BACKUP_DATE}
    else
        echo "Cannot find ${SMB_CONF}. Exited."
        exit 1
    fi

    # Settings for smbldap_bind.conf ---------------------------------------------------------
    print_command_message "Settings for ${SMB_LDAP_BIND_CONF}"
    ReplaceSmbLDAPConf.py -o comment-out -f ${SMB_LDAP_BIND_CONF} -k slaveDN
    ReplaceSmbLDAPConf.py -o comment-out -f ${SMB_LDAP_BIND_CONF} -k slavePw
    ReplaceSmbLDAPConf.py -o override-or-append -f ${SMB_LDAP_BIND_CONF} -k masterDN -v "\"${BLP_CN_MANAGER}\""
    ReplaceSmbLDAPConf.py -o override-or-append -f ${SMB_LDAP_BIND_CONF} -k masterPw -v "\"${BLP_BACKEND_PW}\""

    # Settings for smb.conf ------------------------------------------------------------------
    if [ "${LINUX_DISTRIBUTION}" = "Fedora" ]; then
        print_command_message "cp -f /usr/share/doc/smbldap-tools/smb.conf.example $SMB_CONF"
        \cp -f /usr/share/doc/smbldap-tools/smb.conf.example $SMB_CONF
    elif [ "${LINUX_DISTRIBUTION}" = "Debian" ] || [ "${LINUX_DISTRIBUTION}" = "Ubuntu" ]; then
        # TODO: I haven't found good samba's example file yet for others distributions.
        true > $SMB_CONF
    fi

    # Directive global
    ReplaceSmbConf.py -f $SMB_CONF -o override-or-append -d 'global' -k 'workgroup' -v "${SMB_DOMAIN^^}"
    ReplaceSmbConf.py -f $SMB_CONF -o override-or-append -d 'global' -k 'netbios name' -v "${BLP_HOSTNAME^^}"

    ## ReplaceSmbConf.py -f $SMB_CONF -o override-or-append -d 'global' -k 'dns proxy' -v "no"
    ## ReplaceSmbConf.py -f $SMB_CONF -o override-or-append -d 'global' -k 'panic action' -v "/usr/share/samba/panic-action %d"
    ## ReplaceSmbConf.py -f $SMB_CONF -o override-or-append -d 'global' -k 'obey pam restrictions' -v "yes"
    ## ReplaceSmbConf.py -f $SMB_CONF -o override-or-append -d 'global' -k 'unix password sync' -v "yes"
    ## ReplaceSmbConf.py -f $SMB_CONF -o override-or-append -d 'global' -k 'passwd program' -v '/usr/bin/passwd %u'
    ## ReplaceSmbConf.py -f $SMB_CONF -o override-or-append -d 'global' -k 'passwd chat' -v '*Enter\snew\s*\spassword:* %n\n *Retype\snew\s*\spassword:* %n\n *password\supdated\ssuccessfully* .'
    ## ReplaceSmbConf.py -f $SMB_CONF -o override-or-append -d 'global' -k 'pam password change' -v "yes"
    ## ReplaceSmbConf.py -f $SMB_CONF -o override-or-append -d 'global' -k 'map to guest' -v "bad user"
    ## ReplaceSmbConf.py -f $SMB_CONF -o override-or-append -d 'global' -k 'usershare allow guests' -v "yes"

    ReplaceSmbConf.py -f $SMB_CONF -o override-or-append -d 'global' -k 'server role' -v "auto"
    ReplaceSmbConf.py -f $SMB_CONF -o override-or-append -d 'global' -k 'deadtime' -v '10'

    ReplaceSmbConf.py -f $SMB_CONF -o override-or-append -d 'global' -k 'log level' -v '1'
    ReplaceSmbConf.py -f $SMB_CONF -o override-or-append -d 'global' -k 'log file' -v '/var/log/samba/log.%m'
    ReplaceSmbConf.py -f $SMB_CONF -o override-or-append -d 'global' -k 'max log size' -v '5000'
    ReplaceSmbConf.py -f $SMB_CONF -o override-or-append -d 'global' -k 'debug pid' -v 'yes'
    ReplaceSmbConf.py -f $SMB_CONF -o override-or-append -d 'global' -k 'debug uid' -v 'yes'
    ReplaceSmbConf.py -f $SMB_CONF -o override-or-append -d 'global' -k 'syslog' -v '3'
    ReplaceSmbConf.py -f $SMB_CONF -o override-or-append -d 'global' -k 'utmp' -v 'yes'

    ReplaceSmbConf.py -f $SMB_CONF -o override-or-append -d 'global' -k 'security' -v 'user'
    ReplaceSmbConf.py -f $SMB_CONF -o override-or-append -d 'global' -k 'domain logons' -v 'yes'
    ReplaceSmbConf.py -f $SMB_CONF -o override-or-append -d 'global' -k 'os level' -v '64'
    ReplaceSmbConf.py -f $SMB_CONF -o override-or-append -d 'global' -k 'logon path' -v ''
    ReplaceSmbConf.py -f $SMB_CONF -o override-or-append -d 'global' -k 'logon home' -v ''
    ReplaceSmbConf.py -f $SMB_CONF -o override-or-append -d 'global' -k 'logon drive' -v ''
    ReplaceSmbConf.py -f $SMB_CONF -o override-or-append -d 'global' -k 'logon script' -v ''

    if [ "$BLP_ENABLE_TLS" = "true" ]; then
        ReplaceSmbConf.py -f $SMB_CONF -o override-or-append -d 'global' -k 'passdb backend' -v "ldapsam:\"ldaps://${BLP_FQDN}/\""
        ReplaceSmbConf.py -f $SMB_CONF -o override-or-append -d 'global' -k 'ldap ssl' -v 'start tls'
    else
        ReplaceSmbConf.py -f $SMB_CONF -o override-or-append -d 'global' -k 'passdb backend' -v "ldapsam:\"ldap://${BLP_FQDN}/\""
        ReplaceSmbConf.py -f $SMB_CONF -o override-or-append -d 'global' -k 'ldap ssl' -v 'off'
    fi
    ReplaceSmbConf.py -f $SMB_CONF -o override-or-append -d 'global' -k 'ldap admin dn' -v "${BLP_CN_MANAGER}"
    ReplaceSmbConf.py -f $SMB_CONF -o override-or-append -d 'global' -k 'ldap delete dn' -v 'no'

    if [ "${SMB_LDAP_SYNC_METHOD}" = true ]; then
        ReplaceSmbConf.py -f $SMB_CONF -o override-or-append -d 'global' -k 'ldap password sync' -v 'yes'
    else
        ReplaceSmbConf.py -f $SMB_CONF -o override-or-append -d 'global' -k 'ldap password sync' -v 'no'
        ReplaceSmbConf.py -f $SMB_CONF -o override-or-append -d 'global' -k 'unix password sync' -v 'yes'
        ReplaceSmbConf.py -f $SMB_CONF -o override-or-append -d 'global' -k 'passwd program' -v "/usr/sbin/smbldap-passwd -u '%u'"
        ReplaceSmbConf.py -f $SMB_CONF -o override-or-append -d 'global' -k 'passwd chat' -v '"Changing *\nNew password*" %n\n "*Retype new password*" %n\n"'
    fi

    ReplaceSmbConf.py -f $SMB_CONF -o override-or-append -d 'global' -k 'ldap suffix' -v "${BLP_DOMAIN_COMPONENT}"
    ReplaceSmbConf.py -f $SMB_CONF -o override-or-append -d 'global' -k 'ldap user suffix' -v 'ou=Users'
    ReplaceSmbConf.py -f $SMB_CONF -o override-or-append -d 'global' -k 'ldap group suffix' -v 'ou=Groups'
    ReplaceSmbConf.py -f $SMB_CONF -o override-or-append -d 'global' -k 'ldap machine suffix' -v 'ou=Computers'
    ReplaceSmbConf.py -f $SMB_CONF -o override-or-append -d 'global' -k 'ldap idmap suffix' -v 'ou=Idmap'

    ReplaceSmbConf.py -f $SMB_CONF -o override-or-append -d 'global' -k 'add user script' -v "/usr/sbin/smbldap-useradd -m '%u' -t 1"
    ReplaceSmbConf.py -f $SMB_CONF -o override-or-append -d 'global' -k 'rename user script' -v "/usr/sbin/smbldap-usermod -r '%unew' '%uold'"
    ReplaceSmbConf.py -f $SMB_CONF -o override-or-append -d 'global' -k 'delete user script' -v "/usr/sbin/smbldap-userdel '%u'"
    ReplaceSmbConf.py -f $SMB_CONF -o override-or-append -d 'global' -k 'set primary group script' -v "/usr/sbin/smbldap-usermod -g '%g' '%u'"
    ReplaceSmbConf.py -f $SMB_CONF -o override-or-append -d 'global' -k 'add group script' -v "/usr/sbin/smbldap-groupadd -p '%g'"
    ReplaceSmbConf.py -f $SMB_CONF -o override-or-append -d 'global' -k 'delete group script' -v "/usr/sbin/smbldap-groupdel '%g'"
    ReplaceSmbConf.py -f $SMB_CONF -o override-or-append -d 'global' -k 'add user to group script' -v "/usr/sbin/smbldap-groupmod -m '%u' '%g'"
    ReplaceSmbConf.py -f $SMB_CONF -o override-or-append -d 'global' -k 'delete user from group script' -v "/usr/sbin/smbldap-groupmod -x '%u' '%g'"
    ReplaceSmbConf.py -f $SMB_CONF -o override-or-append -d 'global' -k 'add machine script' -v "/usr/sbin/smbldap-useradd -w '%u' -t 1"

    ReplaceSmbConf.py -f $SMB_CONF -o override-or-append -d 'global' -k 'nt acl support' -v "yes"
    ReplaceSmbConf.py -f $SMB_CONF -o override-or-append -d 'global' -k 'socket options' -v "TCP_NODELAY SO_RCVBUF=8192 SO_SNDBUF=8192 SO_KEEPALIVE"

    # Directive homes
    ## ReplaceSmbConf.py -f $SMB_CONF -o override-or-append -d 'homes' -k 'comment' -v "Home Directories"
    ## ReplaceSmbConf.py -f $SMB_CONF -o override-or-append -d 'homes' -k 'browseable' -v "no"
    ## ReplaceSmbConf.py -f $SMB_CONF -o override-or-append -d 'homes' -k 'read only' -v "yes"
    ## ReplaceSmbConf.py -f $SMB_CONF -o override-or-append -d 'homes' -k 'create mask' -v "0700"
    ## ReplaceSmbConf.py -f $SMB_CONF -o override-or-append -d 'homes' -k 'directory mask' -v "0700"
    ## ReplaceSmbConf.py -f $SMB_CONF -o override-or-append -d 'homes' -k 'valid users' -v "%S"

    # Directive printers
    ## ReplaceSmbConf.py -f $SMB_CONF -o override-or-append -d 'printers' -k 'comment' -v "All Printers"
    ## ReplaceSmbConf.py -f $SMB_CONF -o override-or-append -d 'printers' -k 'browseable' -v "no"
    ## ReplaceSmbConf.py -f $SMB_CONF -o override-or-append -d 'printers' -k 'path' -v "/var/spool/samba"
    ## ReplaceSmbConf.py -f $SMB_CONF -o override-or-append -d 'printers' -k 'printable' -v "yes"
    ## ReplaceSmbConf.py -f $SMB_CONF -o override-or-append -d 'printers' -k 'guest ok' -v "no"
    ## ReplaceSmbConf.py -f $SMB_CONF -o override-or-append -d 'printers' -k 'read only' -v "yes"
    ## ReplaceSmbConf.py -f $SMB_CONF -o override-or-append -d 'printers' -k 'create mask' -v "0700"

    # Directive print$
    ## ReplaceSmbConf.py -f $SMB_CONF -o override-or-append -d 'print$' -k 'comment' -v "Printer Drivers"
    ## ReplaceSmbConf.py -f $SMB_CONF -o override-or-append -d 'print$' -k 'path' -v "/var/lib/samba/printers"
    ## ReplaceSmbConf.py -f $SMB_CONF -o override-or-append -d 'print$' -k 'browseable' -v "yes"
    ## ReplaceSmbConf.py -f $SMB_CONF -o override-or-append -d 'print$' -k 'read only' -v "yes"
    ## ReplaceSmbConf.py -f $SMB_CONF -o override-or-append -d 'print$' -k 'guest ok' -v "no"

    # Directive NETLOGON
    ReplaceSmbConf.py -f $SMB_CONF -o override-or-append -d 'NETLOGON' -k 'path' -v "/var/lib/samba/netlogon"
    ReplaceSmbConf.py -f $SMB_CONF -o override-or-append -d 'NETLOGON' -k 'browseable' -v "no"
    ReplaceSmbConf.py -f $SMB_CONF -o override-or-append -d 'NETLOGON' -k 'share modes' -v "no"

    # Directive PROFILES
    ReplaceSmbConf.py -f $SMB_CONF -o override-or-append -d 'PROFILES' -k 'path' -v "/var/lib/samba/profiles"
    ReplaceSmbConf.py -f $SMB_CONF -o override-or-append -d 'PROFILES' -k 'browseable' -v "no"
    ReplaceSmbConf.py -f $SMB_CONF -o override-or-append -d 'PROFILES' -k 'writeable' -v "yes"
    ReplaceSmbConf.py -f $SMB_CONF -o override-or-append -d 'PROFILES' -k 'create mask' -v "0611"
    ReplaceSmbConf.py -f $SMB_CONF -o override-or-append -d 'PROFILES' -k 'directory mask' -v "0700"
    ReplaceSmbConf.py -f $SMB_CONF -o override-or-append -d 'PROFILES' -k 'profile acls' -v "yes"
    ReplaceSmbConf.py -f $SMB_CONF -o override-or-append -d 'PROFILES' -k 'csc policy' -v "disable"
    ReplaceSmbConf.py -f $SMB_CONF -o override-or-append -d 'PROFILES' -k 'map system' -v "yes"
    ReplaceSmbConf.py -f $SMB_CONF -o override-or-append -d 'PROFILES' -k 'map hidden' -v "yes"

    # Settings for smbldap.conf ---------------------------------------------------------
    # Get localsid
    LOCAL_SID=$(net getlocalsid | sed -e 's|SID for domain [^\s]\+ is: ||')
    print_command_message "net getlocalsid -> $LOCAL_SID"

    print_command_message "Settings for ${SMB_LDAP_CONF}"

    # Delete comment-out for alignment
    sed -i -e '0,/^#\+\s*SID=/s/^#\+\s*SID=/SID=/' ${SMB_LDAP_CONF}
    sed -i -e '0,/^#\+\s*sambaDomain=/s/^#\+\s*sambaDomain=/sambaDomain=/' ${SMB_LDAP_CONF}

    ## SID is edited just before smbldap-populate
    ReplaceSmbLDAPConf.py -o override-or-append -f ${SMB_LDAP_CONF} -k SID -v "\"${LOCAL_SID}\""
    ReplaceSmbLDAPConf.py -o override-or-append -f ${SMB_LDAP_CONF} -k sambaDomain -v "\"${SMB_DOMAIN}\""

    ReplaceSmbLDAPConf.py -o comment-out -f ${SMB_LDAP_CONF} -k slaveLDAP
    if [ "${BLP_ENABLE_TLS}" = "true" ]; then
        # clientcert and clientkey are not supported
        ReplaceSmbLDAPConf.py -o override-or-append -f ${SMB_LDAP_CONF} -k masterLDAP -v "\"ldaps://${BLP_FQDN}/\""
        ReplaceSmbLDAPConf.py -o override-or-append -f ${SMB_LDAP_CONF} -k ldapTLS -v "\"1\""
        ReplaceSmbLDAPConf.py -o override-or-append -f ${SMB_LDAP_CONF} -k verify -v "\"require\""
        ReplaceSmbLDAPConf.py -o override-or-append -f ${SMB_LDAP_CONF} -k cafile -v "\"${BLP_CA_PEM_FILE}\""
        ReplaceSmbLDAPConf.py -o comment-out -f ${SMB_LDAP_CONF} -k clientcert
        ReplaceSmbLDAPConf.py -o comment-out -f ${SMB_LDAP_CONF} -k clientkey
    else
        ReplaceSmbLDAPConf.py -o override-or-append -f ${SMB_LDAP_CONF} -k masterLDAP -v "\"ldap://${BLP_FQDN}/\""
        ReplaceSmbLDAPConf.py -o override-or-append -f ${SMB_LDAP_CONF} -k ldapTLS -v "\"0\""
        ReplaceSmbLDAPConf.py -o override-or-append -f ${SMB_LDAP_CONF} -k verify -v "\"none\""
    fi

    ReplaceSmbLDAPConf.py -o override-or-append -f ${SMB_LDAP_CONF} -k suffix -v "\"${BLP_DOMAIN_COMPONENT}\""
    ReplaceSmbLDAPConf.py -o override-or-append -f ${SMB_LDAP_CONF} -k usersdn -v "\"ou=Users,\${suffix}\""
    ReplaceSmbLDAPConf.py -o override-or-append -f ${SMB_LDAP_CONF} -k computersdn -v "\"ou=Computers,\${suffix}\""
    ReplaceSmbLDAPConf.py -o override-or-append -f ${SMB_LDAP_CONF} -k groupsdn -v "\"ou=Groups,\${suffix}\""
    ReplaceSmbLDAPConf.py -o override-or-append -f ${SMB_LDAP_CONF} -k idmapdn -v "\"ou=Idmap,\${suffix}\""
    ReplaceSmbLDAPConf.py -o override-or-append -f ${SMB_LDAP_CONF} -k sambaUnixIdPooldn -v "\"sambaDomainName=\${sambaDomain},\${suffix}\""
    ReplaceSmbLDAPConf.py -o override-or-append -f ${SMB_LDAP_CONF} -k scope -v "\"sub\""
    ReplaceSmbLDAPConf.py -o override-or-append -f ${SMB_LDAP_CONF} -k password_hash -v "\"SSHA\""
    ReplaceSmbLDAPConf.py -o override-or-append -f ${SMB_LDAP_CONF} -k password_crypt_salt_format -v "\"%s\""
    ReplaceSmbLDAPConf.py -o override-or-append -f ${SMB_LDAP_CONF} -k userLoginShell -v "\"/bin/bash\""
    ReplaceSmbLDAPConf.py -o override-or-append -f ${SMB_LDAP_CONF} -k userHome -v "\"/home/%U\""
    ReplaceSmbLDAPConf.py -o override-or-append -f ${SMB_LDAP_CONF} -k userHomeDirectoryMode -v "\"700\""
    ReplaceSmbLDAPConf.py -o override-or-append -f ${SMB_LDAP_CONF} -k userGecos -v "\"System User\""
    ReplaceSmbLDAPConf.py -o override-or-append -f ${SMB_LDAP_CONF} -k defaultUserGid -v "\"513\""
    ReplaceSmbLDAPConf.py -o override-or-append -f ${SMB_LDAP_CONF} -k defaultComputerGid -v "\"515\""
    ReplaceSmbLDAPConf.py -o override-or-append -f ${SMB_LDAP_CONF} -k skeletonDir -v "\"/etc/skel\""
    ReplaceSmbLDAPConf.py -o override-or-append -f ${SMB_LDAP_CONF} -k shadowAccount -v "\"1\""
    ReplaceSmbLDAPConf.py -o override-or-append -f ${SMB_LDAP_CONF} -k defaultMaxPasswordAge -v "\"45\""

    ReplaceSmbLDAPConf.py -o override-or-append -f ${SMB_LDAP_CONF} -k userSmbHome -v "\"\\\\PDC-SRV\\%U\""
    ReplaceSmbLDAPConf.py -o override-or-append -f ${SMB_LDAP_CONF} -k userProfile -v "\"\\\\PDC-SRV\\profiles\\%U\""
    ReplaceSmbLDAPConf.py -o override-or-append -f ${SMB_LDAP_CONF} -k userHomeDrive -v "\"H:\""
    ReplaceSmbLDAPConf.py -o override-or-append -f ${SMB_LDAP_CONF} -k userScript -v "\"logon.bat\""
    ReplaceSmbLDAPConf.py -o override-or-append -f ${SMB_LDAP_CONF} -k mailDomain -v "\"${BLP_DOMAIN}\""

    ReplaceSmbLDAPConf.py -o override-or-append -f ${SMB_LDAP_CONF} -k with_smbpasswd -v "\"0\""
    ReplaceSmbLDAPConf.py -o override-or-append -f ${SMB_LDAP_CONF} -k smbpasswd -v "\"/usr/bin/smbpasswd\""
    ReplaceSmbLDAPConf.py -o override-or-append -f ${SMB_LDAP_CONF} -k with_slappasswd -v "\"0\""
    ReplaceSmbLDAPConf.py -o override-or-append -f ${SMB_LDAP_CONF} -k slappasswd -v "\"/usr/sbin/slappasswd\""

    # Change permissions ---------------------------------------------------------------------
    print_command_message "Change permissions of $SMB_LDAP_CONF and $SMB_LDAP_BIND_CONF"
    chmod 644 $SMB_LDAP_CONF
    chmod 600 $SMB_LDAP_BIND_CONF


    ## LOCAL_SID=$(net getlocalsid | sed -e 's|SID for domain [^\s]\+ is: ||')
    ## print_command_message "net getlocalsid -> $LOCAL_SID"
    ## ReplaceSmbLDAPConf.py -o override-or-append -f ${SMB_LDAP_CONF} -k SID -v "\"${LOCAL_SID}\""

    print_command_message "\"smbpasswd -w ${BLP_BACKEND_PW}\" # Password for ${BLP_CN_MANAGER}"
    smbpasswd -w ${BLP_BACKEND_PW}

    ######
    # TODO: Execute below commands after...
    #   * /etc/hosts file is editted correctly
    #   * Registered "dn=cn=Manager,dc=your,dc=domain,dc=com"
    #   * Registered password of "cn=Manager,dc=your,dc=domain,dc=com"
    print_command_message 'smbldap-populate'
    yes ${BLP_SMB_DOMAIN_ROOT_PW} | smbldap-populate 1>&2
    echo

    # Start samba ----------------------------------------------------------------------------
    print_command_message "Restart smbd"
    if [ "$LINUX_DISTRIBUTION" = "Fedora" ]; then
        systemctl restart smb.service
        systemctl enable smb.service
    elif [ "$LINUX_DISTRIBUTION" = "Debian" ]; then
        service smbd restart
        update-rc.d smbd defaults
    fi

    # Start nmb
    print_command_message "Restart nmbd"
    if [ "$LINUX_DISTRIBUTION" = "Fedora" ]; then
        systemctl restart nmb.service
        systemctl enable nmb.service
    elif [ "$LINUX_DISTRIBUTION" = "Debian" ]; then
        service nmbd restart
        update-rc.d nmbd defaults
    fi

    print_command_message 'sync_groups_between_domain_and_unix'
    sync_groups_between_domain_and_unix

    # reference-> http://www.unixmen.com/setup-samba-domain-controller-with-openldap-backend-in-ubuntu-13-04/
    # 1.
    #   useradd <username>
    # 2.
    #   smbldap-useradd -a -G 'Domain Users' -m -s /bin/bash -d /home/user2 -F "" -P user1
    # 3.
    #  net sam rights grant user1 SeMachineAccountPrivilege
    #

    # Add first Computer ---------------------------------------------------------------------
    if [[ "${SMB_DOMAIN_COMPUTER}" =~ ^.*\$$ ]]; then
        print_command_message "Adding a ${SMB_DOMAIN_COMPUTER} as Samba Domain Computers"
        useradd -M -g smb_domain_computers -s /bin/false ${SMB_DOMAIN_COMPUTER}

        if [ ! "${SMB_FDA_USER_NAME}" = "" ] && [ ! "${SMB_FDA_USER_PASSWORD}" = "" ]; then
            # Add First Domain Admins ----------------------------------------------------------------
            print_command_message "Adding a user \"${SMB_FDA_USER_NAME}\""
            useradd -M ${SMB_FDA_USER_NAME}
            yes ${SMB_FDA_USER_PASSWORD} | smbldap-useradd -a -G 'Domain Admins' -m -s /bin/bash -d /home/${SMB_FDA_USER_NAME} -F "" -P ${SMB_FDA_USER_NAME}
            echo
            smbpasswd -e ${SMB_FDA_USER_NAME}
            net sam rights grant ${SMB_FDA_USER_NAME} SeMachineAccountPrivilege
        fi

        if [ ! "${SMB_FDU_USER_NAME}" = "" ] && [ ! "${SMB_FDU_USER_PASSWORD}" = "" ]; then
            # Add First Domain Users ----------------------------------------------------------------
            print_command_message "Adding a user \"${SMB_FDU_USER_NAME}\""
            useradd -M ${SMB_FDU_USER_NAME}
            yes ${SMB_FDU_USER_PASSWORD} | smbldap-useradd -a -G 'Domain Users' -m -s /bin/bash -d /home/${SMB_FDU_USER_NAME} -F "" -P ${SMB_FDU_USER_NAME}
            smbpasswd -e ${SMB_FDU_USER_NAME}
            net sam rights grant ${SMB_FDU_USER_NAME} SeMachineAccountPrivilege
        fi
    fi
}

main

