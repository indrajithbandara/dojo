
function print_command_message() {
    echo "============================================================"
    echo $1
    echo "============================================================"
    sync
}

function cmd() {
    ONE_COMMAND=$1
    print_command_message "${ONE_COMMAND}"
    ${ONE_COMMAND}
}

function cmde() {
    ONE_COMMAND=$1
    print_command_message "${ONE_COMMAND}"
    eval "${ONE_COMMAND}"
}

function die() {
    echo "Error: $1" >&2
    exit 1
}

# install packages
# @param list: package list delimited spaces
function install_lacking_packages() {
    PACKAGES=$1
    LINUX_FAMILY=$2
    INSTALL_RESULT=0

    REQUIRED_PACKAGE=""
    for PACKAGE in $PACKAGES; do
        if [ "$LINUX_FAMILY" = "RedHat" ]; then
            rpm -q $PACKAGE > /dev/null 2>&1
            INSTALL_RESULT=$?
        elif [ "$LINUX_FAMILY" = "Debian" ]; then

            # This section checks for one of dpkg --list result like below.
            # This pattern returns result 0 but status of installation is "uninstalled"
            #
            ## Desired=Unknown/Install/Remove/Purge/Hold
            ## | Status=Not/Inst/Conf-files/Unpacked/halF-conf/Half-inst/trig-aWait/Trig-pend
            ## |/ Err?=(none)/Reinst-required (Status,Err: uppercase=bad)
            ## ||/ Name                    Version          Architecture     Description
            ## +++-=======================-================-================-====================================================
            ## un  samba                   <none>           <none>           (no description available)

            dpkg --list $PACKAGE | egrep -q "^un\s+${PACKAGE}" > /dev/null 2>&1
            # Reverse result
            if [ $? -ne 0 ]; then
                INSTALL_RESULT=0
            else
                INSTALL_RESULT=1
            fi
        fi

        if [ $INSTALL_RESULT -ne 0 ]; then
            # TODO: debug
            echo "------ ${PACKAGE}"
            REQUIRED_PACKAGE="$REQUIRED_PACKAGE $PACKAGE"
        fi
    done

    if [ ! "$REQUIRED_PACKAGE" = "" ]; then
        print_command_message "Installing packages $REQUIRED_PACKAGE"
        if [ "$LINUX_FAMILY" = "RedHat" ]; then
            dnf -y install $REQUIRED_PACKAGE
        elif [ "$LINUX_FAMILY" = "Debian" ]; then
            DEBIAN_FRONTEND=noninteractive apt-get -q -y install $REQUIRED_PACKAGE
        fi
    fi
}

# Get backend db chars like "{1}mdb"
function get_backend_chars() {
    for DB in mdb hdb; do
        for I in {0..4}; do
            ldapsearch -LLL -Y EXTERNAL -H ldapi:/// -D "cn=config" -b "olcDatabase={${I}}${DB},cn=config" > /dev/null 2>&1 && echo "{${I}}${DB}" && return 0
        done
    done
    return 1
}

# Get monitor char like "{1}monitor"
function get_monitor_chars() {
    for I in {0..4}; do
        ldapsearch -LLL -Y EXTERNAL -H ldapi:/// -D "cn=config" -b "olcDatabase={${I}}monitor,cn=config" > /dev/null 2>&1 && echo "{${I}}monitor" && return 0
    done
    return 1
}

# Chack existence of olcRootPW an olcDatabase backend
# A param must be given like "{1}mdb", "{1}hdb" and any other.
# TODO: Check more beautifully...
function exist_olc_root_pw() {
    local BACKEND=$1
    local RESULT_STRING=$(ldapsearch -LLL -Y EXTERNAL -H ldapi:/// -b "olcDatabase=${BACKEND},cn=config" "(olcDatabase=*)" olcRootPW 2> /dev/null)

    local RETURN_CODE=$?
    if [ ${RETURN_CODE} -ne 0 ]; then
        return ${RETURN_CODE}
    fi

    echo "${RESULT_STRING}" | egrep '^olcRootPW: .*$' > /dev/null 2>&1
    RETURN_CODE=$?
    if [ ${RETURN_CODE} -eq 0 ]; then
        return 0
    else
        return 255
    fi
}

# Add PATH values if it is not exist
function add_path_if_not_exist() {
    NEW_PATH=$1
    NEW_PATH=$(echo "$NEW_PATH" | sed -e 's|/$||')

    echo $PATH | sed -e 's|\:|\n|g' | sed -e 's|/$||' | while read LINE; do
        if [ "$LINE" = "$NEW_PATH" ]; then
            # Already existed
            return 255
        fi
    done

    export PATH="${PATH}:${NEW_PATH}"
    return 0
}

# Get IPv4 address from determined interface
function get_ip_address_from_interface() {
    TARGET_INTERFACE=$1

    CURRENT_INTERFACE=""
    IN_SECTION=0

    ip addr | while read LINE; do

        if [[ "$LINE" =~ ^[0-9]+: ]]; then

            COLUMN_2=$(echo $LINE | cut -d ' ' -f 2)
            CURRENT_INTERFACE=$(echo ${COLUMN_2} | sed -e "s|:$||")

            if [ "$CURRENT_INTERFACE" = "$BLP_INTERFACE" ]; then
                IN_SECTION=1
                continue
            fi
        fi

        if [ "$IN_SECTION" = "1" ]; then
            if [[ "$LINE" =~ ^\s*inet.* ]]; then
                # Fetch IP address
                IP_ADDR=$(echo "$LINE" | cut -d ' ' -f 2 | cut -d '/' -f 1)
                echo ${IP_ADDR}
                break
            fi
        fi
    done
}

function sync_groups_between_domain_and_unix() {
    net groupmap list | while read LINE; do
        AN_ELEMENT=$(echo $LINE | sed -e "s|^\(.*\)\s(S.*) \-> \(.*\+\)$|\1,\2|g")

        DOMAIN_GROUP=$(echo $AN_ELEMENT | cut -d',' -f 1)
        GROUP_ID=$(echo $AN_ELEMENT | cut -d',' -f 2)

        if [[ ! "$GROUP_ID" =~ ^[0-9]+$ ]]; then
            # If domain group is already mapped to unix group then continue.
            echo "Skipped: ${DOMAIN_GROUP} is already mapped to unix group $GROUP_ID"
            continue
        fi

        # Replace each spaces to underscores and
        # replace to lowercase and concat a prefix "smb_" on the head of the domain group
        SMB_DOMAIN_GROUP=$(echo ${DOMAIN_GROUP} | sed -e "s|\s|_|g")
        SMB_DOMAIN_GROUP="smb_${SMB_DOMAIN_GROUP,,}"

        echo "groupadd -g ${GROUP_ID} ${SMB_DOMAIN_GROUP} (for ${DOMAIN_GROUP})"
        groupadd -g ${GROUP_ID} ${SMB_DOMAIN_GROUP}
    done
}

