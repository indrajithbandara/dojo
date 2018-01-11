#!/bin/bash

if [ -f ./global.conf.sh ]; then
    . ./global.conf.sh
else
    echo "A file ./global.conf.sh was not found. Finished..."
    exit 1
fi

egrep ".*$REG_MY_FQDN$" /etc/hosts > /dev/null
if [ $? -ne 0 ]; then
    echo "${BLP_LDAP_HOST_IP} ${BLP_FQDN}" >> /etc/hosts
fi

# Load common functions -------------------------------------------------------------
. ./lib/Functions.sh

function main() {

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

    # Build openldap base ---------------------------------------------------------------
    if [ "$BLP_SHUTDOWN_STATUS" = "" ]
            && !([ "$BLP_USE_WINDOWS_DOMAIN" = "true" ] && [ "$LINUX_DISTRIBUTION" = "Ubuntu" ]); then
        build_openldap
    fi

    # Build samba pdc -------------------------------------------------------------------
    if [ "${BLP_USE_WINDOWS_DOMAIN}" = "true" ]; then
        build_samba_pdc
    fi
}

function build_samba_pdc() {

    # Register new groups if Unix groups conformity with Domain group are lacked.
    # Adding path to script
    print_command_message 'add_path_if_not_exist "${BLP_BASE_DIR}/perl"'
    add_path_if_not_exist "${BLP_BASE_DIR}/perl"
    print_command_message 'add_path_if_not_exist "/usr/local/samba/bin"'
    add_path_if_not_exist "/usr/local/samba/bin"
    print_command_message 'add_path_if_not_exist "/usr/local/samba/sbin"'
    add_path_if_not_exist "/usr/local/samba/sbin"

    print_command_message 'echo ${PATH}'
    echo ${PATH}

    if [ "$LINUX_DISTRIBUTION" = "Fedora" ]; then
        print_command_message "./lib/SambaRedHat.sh ..."
        ./lib/SambaRedHat.sh "$BLP_BASE_DIR" "$BLP_BASE_SCRIPT"
    elif [ "$LINUX_DISTRIBUTION" = "Ubuntu" ]; then
        print_command_message "./lib/SambaDebian.sh ..."
        ./lib/SambaDebian.sh "$BLP_BASE_DIR" "$BLP_BASE_SCRIPT"
    fi
}

function build_openldap() {

    # install packages
    if [ "$LINUX_DISTRIBUTION" = "Fedora" ]; then
        install_lacking_packages "openldap openldap-clients openldap-servers" "$LINUX_FAMILY"

        # starting openldap
        print_command_message "systemctl start slapd"
        systemctl start slapd

        print_command_message "systemctl enable slapd"
        systemctl enable slapd

        # adding firewalld ldap
        print_command_message "firewall-cmd --permanent --zone=FedoraServer --query-service=ldap"
        firewall-cmd --permanent --zone=FedoraServer --add-service=ldap

        print_command_message "firewall-cmd --permanent --zone=FedoraServer --query-service=ldaps"
        firewall-cmd --permanent --zone=FedoraServer --add-service=ldaps

    elif [ "$LINUX_DISTRIBUTION" = "Ubuntu" ]; then

        # TODO: Un commented
        # apt-get update

        install_lacking_packages "slapd ldap-utils libnss-ldap" "$LINUX_FAMILY"
        # TODO: Don't enable slapd.
        #       If you enable it, the error will be occurred like below when the OS(in my case at Ubuntu 14.04.3 LTS) is restarted.
        #       - In the log.samba --------------------------------------------------------------------
        #       [2015/10/17 10:54:16.743321,  0] ../source4/ldap_server/ldap_server.c:821(add_socket)
        #         ldapsrv failed to bind to 0.0.0.0:389 - NT_STATUS_ADDRESS_ALREADY_ASSOCIATED
        #       ---------------------------------------------------------------------------------------
        #
        # # starting openldap
        # print_command_message "service slapd start"
        # service slapd start
        #
        # # TODO: Duplicated method in Ubuntu 14.04.3 LTS
        # print_command_message "update-rc.d slapd default"
        # update-rc.d slapd default

        service slapd start
        update-rc.d -f slapd remove

        # TODO: iptables
    fi

    # Get backend of OpenLDAP
    BLP_BACKEND=$(print_backend)

    # confirm current settings of slapd
    print_command_message "ldapsearch -LLL -Y EXTERNAL -H ldapi:/// -b \"cn=config\" \"(olcDatabase=*)\""
    ldapsearch -LLL -Y EXTERNAL -H ldapi:/// -b "cn=config" "(olcDatabase=*)"

    # confirm ldif to add olcRootPW
    print_command_message "cat ./lib/ldifs/starting_ldap/set_rootpw.ldif"
    cat ./lib/ldifs/starting_ldap/set_rootpw.ldif

    # adding new root password as "password"
    print_command_message "ldapadd -Y EXTERNAL -H ldapi:/// -f ./lib/ldifs/starting_ldap/set_rootpw.ldif"
    ldapadd -Y EXTERNAL -H ldapi:/// -f ./lib/ldifs/starting_ldap/set_rootpw.ldif

    # confirm slapd's root password
    print_command_message "ldapsearch -x -LLL -D \"cn=config\" -w password -b \"cn=config\" \"(olcDatabase=*)\""
    ldapsearch -x -LLL -D "cn=config" -w password -b "cn=config" "(olcDatabase=*)"

    # Adding schemes --------------------------------------------------------------------
    # TODO: Already exist in Ubuntu
    print_command_message "ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/cosine.ldif"
    ldapadd -Y EXTERNAL -H ldapi:/// -f ${BLP_ETC_LDAP_DIR}/schema/cosine.ldif 2> /dev/null || \
            ([ $? = 80 ] && echo "Some schemes are already existed.")

    # TODO: Already exist in Ubuntu
    print_command_message "ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/nis.ldif"
    ldapadd -Y EXTERNAL -H ldapi:/// -f ${BLP_ETC_LDAP_DIR}/schema/nis.ldif 2> /dev/null || \
            ([ $? = 80 ] && echo "Some schemes are already existed.")

    # TODO: Already exist in Ubuntu
    print_command_message "ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/inetorgperson.ldif"
    ldapadd -Y EXTERNAL -H ldapi:/// -f ${BLP_ETC_LDAP_DIR}/schema/inetorgperson.ldif 2> /dev/null || \
            ([ $? = 80 ] && echo "Some schemes are already existed.")

    # modifing root dn
    if [ "$BLP_BACKEND" = "mdb" ]; then

        print_command_message "cat ./lib/ldifs/starting_ldap/set_backends_rootdn.ldif"
        cat ./lib/ldifs/starting_ldap/set_backends_rootdn.ldif

        print_command_message "ldapmodify -x -D cn=config -w password2 -f ./lib/ldifs/starting_ldap/set_backends_rootdn.ldif"
        ldapmodify -x -D cn=config -w password -f ./lib/ldifs/starting_ldap/set_backends_rootdn.ldif
    elif [ "$BLP_BACKEND" = "hdb" ]; then

        print_command_message "cat ./lib/ldifs/starting_ldap/set_rootdn_hdb.ldif"
        cat ./lib/ldifs/starting_ldap/set_rootdn_hdb.ldif

        # TODO:
        # ldap_modify: Inappropriate matching (18)
        #         additional info: modify/add: olcRootPW: no equality matching rule
        print_command_message "ldapmodify -x -D cn=config -w password2 -f ./lib/ldifs/starting_ldap/set_rootdn_hdb.ldif"
        ldapmodify -x -D cn=config -w password -f ./lib/ldifs/starting_ldap/set_rootdn_hdb.ldif
    fi

    print_command_message "ldapsearch -x -LLL -D \"cn=config\" -w password -b \"cn=config\" \"(olcDatabase=*)\""
    ldapsearch -x -LLL -D "cn=config" -w password -b "cn=config" "(olcDatabase=*)"

    # Adding base dn
    print_command_message "cat ./lib/ldifs/starting_ldap/create_base.ldif"
    cat ./lib/ldifs/starting_ldap/create_base.ldif

    print_command_message "ldapadd -x -D \"cn=Manager,dc=mysite,dc=example,dc=com\" -w password2 -f ./lib/ldifs/starting_ldap/create_base.ldif"
    ldapadd -x -D "cn=Manager,dc=mysite,dc=example,dc=com" -w password2 -f ./lib/ldifs/starting_ldap/create_base.ldif

    # TODO: testing
    print_command_message "ldapsearch -x -D \"cn=Manager,dc=mysite,dc=example,dc=com\" -w password2 -b \"dc=mysite,dc=example,dc=com\""
    ldapsearch -x -D "cn=Manager,dc=mysite,dc=example,dc=com" -w password2 -b "dc=mysite,dc=example,dc=com"

    # Adding groups
    print_command_message "ldapadd -x -D \"cn=Manager,dc=mysite,dc=example.dc=com\" -w password2 -f ./lib/ldifs/starting_ldap/create_organizational_units.ldif"
    ldapadd -x -D "cn=Manager,dc=mysite,dc=example.dc=com" -w password2 -f ./lib/ldifs/starting_ldap/create_organizational_units.ldif

    print_command_message "ldapsearch -x -D \"cn=Manager,dc=mysite,dc=example,dc=com\" -w password2 -b \"dc=mysite,dc=example,dc=com\""
    ldapsearch -x -D "cn=Manager,dc=mysite,dc=example,dc=com" -w password2 -b "dc=mysite,dc=example,dc=com"

    # adding groups
    print_command_message "cat ./lib/ldifs/starting_ldap/create_groups.ldif"
    cat ./lib/ldifs/starting_ldap/create_groups.ldif

    print_command_message "ldapadd -x -w password2 -D \"cn=Manager,dc=mysite,dc=example,dc=com\" -f ./lib/ldifs/starting_ldap/create_groups.ldif"
    ldapadd -x -w password2 -D "cn=Manager,dc=mysite,dc=example,dc=com" -f ./lib/ldifs/starting_ldap/create_groups.ldif

    print_command_message "ldapsearch -x -LLL -H ldap:/// -b \"ou=Groups,dc=mysite,dc=example,dc=com\" \"(objectClass=*)\""
    ldapsearch -x -LLL -H ldap:/// -b "ou=Groups,dc=mysite,dc=example,dc=com" "(objectClass=*)"

    # adding users
    print_command_message "cat ./lib/ldifs/starting_ldap/create_users.ldif"
    cat ./lib/ldifs/starting_ldap/create_users.ldif

    print_command_message "ldapadd -x -w password2 -D \"cn=Manager,dc=mysite,dc=example,dc=com\" -f ./lib/ldifs/starting_ldap/create_users.ldif"
    ldapadd -x -w password2 -D "cn=Manager,dc=mysite,dc=example,dc=com" -f ./lib/ldifs/starting_ldap/create_users.ldif

    print_command_message "ldapsearch -x -LLL -H ldap:/// -b \"ou=Users,dc=mysite,dc=example,dc=com\" \"(objectClass=*)\""
    ldapsearch -x -LLL -H ldap:/// -b "ou=Users,dc=mysite,dc=example,dc=com" "(objectClass=*)"

    # TODO:
    # Setting LDAP ACL's
    ## print_command_message "cat ./lib/ldifs/starting_ldap/setting_acls.ldif"
    ## cat ./lib/ldifs/starting_ldap/setting_acls.ldif
    ## 
    ## print_command_message "ldapmodify -x -D cn=config -w password -f ./lib/ldifs/starting_ldap/setting_acls.ldif"
    ## ldapmodify -x -D cn=config -w password -f ./lib/ldifs/starting_ldap/setting_acls.ldif

    if [ "$BLP_BACKEND" = "mdb" ]; then
        # create indexes
        print_command_message "cat ./lib/ldifs/starting_ldap/create_indexes.ldif"
        cat ./lib/ldifs/starting_ldap/create_indexes.ldif

        print_command_message "ldapmodify -x -D cn=config -w password -f ./lib/ldifs/starting_ldap/create_indexes.ldif"
        ldapmodify -x -D cn=config -w password -f ./lib/ldifs/starting_ldap/create_indexes.ldif
    elif [ "$BLP_BACKEND" = "hdb" ]; then

        print_command_message "cat ./lib/ldifs/starting_ldap/create_indexes_hdb.ldif"
        cat ./lib/ldifs/starting_ldap/create_indexes_hdb.ldif

        print_command_message "ldapmodify -x -D cn=config -w password -f ./lib/ldifs/starting_ldap/create_indexes_hdb.ldif"
        ldapmodify -x -D cn=config -w password -f ./lib/ldifs/starting_ldap/create_indexes_hdb.ldif
    fi

    print_command_message "ldapsearch -x -LLL -D \"cn=config\" -w password -b \"cn=config\" \"(olcDatabase=*)\""
    ldapsearch -x -LLL -D "cn=config" -w password -b "cn=config" "(olcDatabase=*)"

    #############################################################################
    # Creating CA and TLS cert.
    # We will create what things are below
    #     CA's private key named "ca-key.pem"
    #     CA's certificate named "ca.pem"
    #     LDAP server's private key named ""
    #     LDAP server's certificate named ""
    #############################################################################
    # Creating srl

    if [ "$LINUX_DISTRIBUTION" = "Fedora" ]; then
        BLP_PKI_DIR="/etc/pki"
    elif [ "$LINUX_DISTRIBUTION" = "Ubuntu" ]; then
        BLP_PKI_DIR="/etc/ssl"
    fi

    if [ "${BLP_ENABLE_TLS}" = "true" ]; then
        echo "00" > ${BLP_PKI_DIR}/CA/certs/ca.srl

        print_command_message "[ -d ${BLP_PKI_DIR}/CA ]          || mkdir -p ${BLP_PKI_DIR}/CA/{private,newcerts,crl,certs}"
        [ -d ${BLP_PKI_DIR}/CA ]          || mkdir -p ${BLP_PKI_DIR}/CA/{private,newcerts,crl,certs}

        print_command_message "[ -d ${BLP_ETC_LDAP_DIR}/certs ]  || mkdir    ${BLP_ETC_LDAP_DIR}/certs"
        [ -d ${BLP_ETC_LDAP_DIR}/certs ]  || mkdir    ${BLP_ETC_LDAP_DIR}/certs

        if [ "${BLP_USE_TEST_CA}" = "true" ]; then
            echo "## Using test ca"
            print_command_message "cp ${BLP_BASE_DIR}/example/pki/${BLP_CA_FQDN}.cert.pem     ${BLP_PKI_DIR}/CA/certs/${BLP_CA_FQDN}.cert.pem"
            cp ${BLP_BASE_DIR}/example/pki/${BLP_CA_FQDN}.cert.pem     ${BLP_PKI_DIR}/CA/certs/${BLP_CA_FQDN}.cert.pem
            print_command_message "cp ${BLP_BASE_DIR}/example/pki/${BLP_CA_FQDN}.key.pem ${BLP_PKI_DIR}/CA/private"
            cp ${BLP_BASE_DIR}/example/pki/${BLP_CA_FQDN}.key.pem ${BLP_PKI_DIR}/CA/private

            print_command_message "cp ${BLP_BASE_DIR}/example/pki/${BLP_FQDN}.cert.pem ${BLP_ETC_LDAP_DIR}/certs"
            cp ${BLP_BASE_DIR}/example/pki/${BLP_FQDN}.cert.pem ${BLP_ETC_LDAP_DIR}/certs/
            print_command_message "cp ${BLP_BASE_DIR}/example/pki/${BLP_FQDN}.key.pem      ${BLP_ETC_LDAP_DIR}/certs"
            cp ${BLP_BASE_DIR}/example/pki/${BLP_FQDN}.key.pem      ${BLP_ETC_LDAP_DIR}/certs/
        else
            # TODO: testing

            # Creating CA private key and certificate
            cd ${BLP_PKI_DIR}/CA
            openssl genrsa -des3 -out ./private/${BLP_CA_FQDN}.key.pem 2048
            openssl req -new -x509 -days 365 -key ./private/${BLP_CA_FQDN}.key.pem -out ./certs/${BLP_CA_FQDN}.cert.pem \
                -subj "/C=JP/ST=Tokyo/L=Minatoku/O=Example Company/OU=Development/CN=${BLP_CA_FQDN}"

            # Creating server private key and certificate
            cd ${BLP_ETC_LDAP_DIR}/certs
            openssl genrsa -des3 -out ${BLP_FQDN}.key.pem 2048

            openssl req -new -key ${BLP_FQDN}.key.pem -out ${BLP_FQDN}.csr \
                -subj "/C=JP/ST=Tokyo/L=Hoge/O=Fuga Company/OU=Development/CN=${BLP_FQDN}"

            # Sign LDAP server's csr by using CA's private key to make LDAP server's certificate.
            openssl x509 -req -days 365 -in ${BLP_FQDN}.csr -CA ${BLP_PKI_DIR}/CA/certs/${BLP_CA_FQDN}.cert.pem \
                    -CAkey ${BLP_PKI_DIR}/CA/private/${BLP_CA_FQDN}.key.pem -out ${BLP_FQDN}.cert.pem

            # Decryept LDAP server's private key to be able to load it by OpenLDAP
            openssl rsa -in ${BLP_FQDN}.key.pem -out ${BLP_FQDN}.key.pem
        fi

        # Regist the CA cert, the server key and the server certificate on OpenLDAP
        cd ~/BuildingLDAP

        print_command_message "cat ./lib/ldifs/tls/set_tls.ldif"
        cat ./lib/ldifs/tls/set_tls.ldif

        print_command_message "ldapmodify -x -w password -D cn=config -f ./lib/ldifs/tls/set_tls.ldif"
        ldapmodify -x -w password -D cn=config -f ./lib/ldifs/tls/set_tls.ldif

        print_command_message "ldapsearch -x -LLL -D \"cn=config\" -w password -b \"cn=config\" \"(olcTLSCACertificateFile=*)\""
        ldapsearch -x -LLL -D "cn=config" -w password -b "cn=config" "(olcTLSCACertificateFile=*)"

        echo "Please copy CA's certificate ca.pem and edit the client's ldap.conf like below"
        echo "ex)"
        echo "  TLS_REQCERT   never"
        echo "  TLS_CACERT    ${BLP_PKI_DIR}/CA/certs/ca.pem"
        echo "  TLS_CACERTDIR ${BLP_PKI_DIR}/CA/certs"
    fi
}

main

############################################################
# TODO:
exit 0
############################################################

