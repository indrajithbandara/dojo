
# ####################################################################################
# Create parent container
sudo docker build -t="tsutomu/smb4pdc" .
sudo docker run --privileged \
        -p 53:53 -p 88:88 -p 135:135 -p 137:137 -p 138:138 -p 139:139           \
        -p 389:389 -p 464:464 -p 3268:3268 -p 5353:5353 --name "smb4pdc"        \
        -e SMB_AUTHOR_NAME="tsutomu"        -e SMB_REALM="MYSITE.EXAMPLE.COM"   \
        -e SMB_DNS_BACKEND="SAMBA_INTERNAL" -e SMB_DOMAIN="MYSITE"              \
        -e SMB_HOSTNAME="LDAP"              -e SMB_ADMIN_PASS="p@ssword3"       \
        -t -i tsutomu/smb4pdc

# ####################################################################################
# Create child container with manually
export SMB_AUTHOR_NAME="tsutomu"
export SMB_REALM="MYSITE.EXAMPLE.COM"
export SMB_DNS_BACKEND="SAMBA_INTERNAL"
export SMB_DOMAIN="MYSITE"
export SMB_HOSTNAME="LDAP"
export SMB_ADMIN_PASS="p@ssword3"


sudo altdocker build \
        --build-arg SMB_REALM="$SMB_REALM"              \
        --build-arg SMB_DNS_BACKEND="$SMB_DNS_BACKEND"  \
        --build-arg SMB_DOMAIN="$SMB_DOMAIN"            \
        --build-arg SMB_HOSTNAME="$SMB_HOSTNAME"        \
        --build-arg SMB_ADMIN_PASS="$SMB_ADMIN_PASS"    \
        -t="${SMB_AUTHOR_NAME}/inner_smb4pdc" .

sudo altdocker run --name "inner_smb4pdc" \
        -p 53:53 -p 88:88 -p 135:135 -p 137:137 -p 138:138 -p 139:139       \
        -p 389:389 -p 464:464 -p 3268:3268 -p 5353:5353                     \
        -t -i ${SMB_AUTHOR_NAME}/inner_smb4pdc

sudo altdocker run --name "inner_smb4pdc" \
        -p 53:53/tcp -p 53:53/udp           \
        -t -i ${SMB_AUTHOR_NAME}/inner_smb4pdc
        -p 88:88/tcp -p 88:88/udp           \
        -p 135:135                          \
        -t -i ${SMB_AUTHOR_NAME}/inner_smb4pdc

## These error messages are outputted when execute samba-tool on aufs storage driver.
......
Setting up sam.ldb users and groups
Setting up self join
process_usershare_file: share name unknown service (snum == -1) contains invalid characters (any of %<>*?|/\+=;:",)
ERROR(<class 'samba.provision.ProvisioningError'>): Provision failed - ProvisioningError: Your filesystem or build does not support posix ACLs, which s3fs requires.  Try the mounting the filesystem with the 'acl' option.
  File "/usr/lib/python2.7/dist-packages/samba/netcmd/domain.py", line 401, in run
    use_rfc2307=use_rfc2307, skip_sysvolacl=False)
  File "/usr/lib/python2.7/dist-packages/samba/provision/__init__.py", line 2160, in provision
    skip_sysvolacl=skip_sysvolacl)
  File "/usr/lib/python2.7/dist-packages/samba/provision/__init__.py", line 1799, in provision_fill
    names.domaindn, lp, use_ntvfs)
  File "/usr/lib/python2.7/dist-packages/samba/provision/__init__.py", line 1551, in setsysvolacl
    raise ProvisioningError("Your filesystem or build does not support posix ACLs, which s3fs requires.  "

