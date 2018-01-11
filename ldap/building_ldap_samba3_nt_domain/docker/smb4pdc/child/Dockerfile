FROM debian:jessie

ARG SMB_REALM
ARG SMB_DNS_BACKEND
ARG SMB_DOMAIN
ARG SMB_HOSTNAME
ARG SMB_ADMIN_PASS

# Debian jessie's repository in Japan
RUN echo "deb http://ftp.jp.debian.org/debian/ jessie main contrib non-free" > /etc/apt/sources.list

RUN apt-get update
RUN DEBIAN_FRONTEND=noninteractive apt-get -q -y install                \
       slapd ldap-utils libnss-ldap                                     \
       samba samba-doc smbldap-tools smbclient                          \
       acl attr autoconf bison build-essential                          \
       debhelper dnsutils docbook-xml docbook-xsl flex gdb krb5-user    \
       libacl1-dev libaio-dev libattr1-dev libblkid-dev libbsd-dev      \
       libcap-dev libcups2-dev libgnutls28-dev libjson-perl             \
       libldap2-dev libncurses5-dev libpam0g-dev libparse-yapp-perl     \
       libpopt-dev libreadline-dev perl perl-modules pkg-config         \
       python-all-dev python-dev python-dnspython python-crypto         \
       xsltproc zlib1g-dev

ENV PATH /usr/local/samba/bin:/usr/local/samba/sbin:${PATH}

RUN cp -ip /etc/samba/smb.conf /etc/samba/smb.conf.org && rm /etc/samba/smb.conf
RUN cp -ip /etc/krb5.conf /etc/krb5.conf.org

RUN samba-tool domain provision --use-rfc2307   \
        --realm=${SMB_REALM}                    \
        --server-role=dc                        \
        --dns-backend=${SMB_DNS_BACKEND}        \
        --domain=${SMB_DOMAIN}                  \
        --host-name=${SMB_HOSTNAME}             \
        --adminpass=${SMB_ADMIN_PASS}

EXPOSE 53 88 135 137 138 139 389 464 3268 5353
ENTRYPOINT ["/usr/sbin/samba", "-i"]

