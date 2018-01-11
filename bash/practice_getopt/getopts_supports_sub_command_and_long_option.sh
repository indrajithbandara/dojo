#!/bin/bash
OPTSPEC_FOR_MAIN_COMMAND=":HdC:-:"
OPTSPEC_FOR_SUB_COMMAND=":Hif:-:"

# Options of main-command
#   command [-H|--help] [-d] [--version] [-C <path>|--workdir <path>]
# Options of sub-command
#   command-subcommand [-H|--help] [-i] [--list] [-F <path>|--file <path>]


function main() {
    local workdir_arg

    # Parse options of main command
    while getopts "$OPTSPEC_FOR_MAIN_COMMAND" optchar; do
        case "${optchar}" in
        H )
            OPTARG="help"
            ;;&
        d )
            echo "-d"
            ;;
        C )
            workdir_arg="${OPTARG}"
            OPTARG="workdir"
            ;;&
        - | H | C )
            case "$OPTARG" in
            help )
                echo "-H, --help"
                ;;
            version )
                echo "--version"
                ;;
            workdir )
                [[ -z "$workdir_arg" ]] && { workdir_arg="${!OPTIND}"; OPTIND=$(( $OPTIND + 1 )); }
                [[ -z "$workdir_arg" ]] || [[ "${workdir_arg:0:1}" == "-" ]] && {
                    # Chack with "[[ -z $workdir_arg ]]" if you want to prohibit specifying string which length is 0"
                    echo "There is no value of option \"-C, --workdir\"" >&2
                    return 1
                }
                echo "-C, --workdir ${workdir_arg}"
                ;;
            - )
                shift; break
                ;;
            * )
                [[ "$OPTERR" == "1" ]] || [[ "${OPTSPEC:0:1}" == ":" ]] \
                        && echo "Unknown long option of main command" >&2 && return 1
                ;;
            esac
            ;;
        ? )
            [[ "$OPTERR" == "1" ]] || [[ "${OPTSPEC:0:1}" == ":" ]] \
                    && echo "Unknown short option of main command" >&2 && return 1
            ;;
        esac
    done
    shift $((OPTIND-1))

    # Parse subcommand and its options
    local subcmd="$1"
    shift

    [[ -z "$subcmd" ]] && {
        echo "There is no subcommand"
        return 1
    }

    local file_arg

    case "$subcmd" in
    subcommand )
        echo "subcommand"
        while getopts "$OPTSPEC_FOR_SUB_COMMAND" optchar; do
            case "${optchar}" in
            H )
                OPTARG="help"
                ;;&
            i )
                echo "-i"
                ;;
            f )
                file_arg="${OPTARG}"
                OPTARG="file"
                ;;&
            - | H | f )
                case "${OPTARG}" in
                help )
                    echo "-H, --help"
                    ;;
                file )
                    [[ -z "$file_arg" ]] && { file_arg="${!OPTIND}"; OPTIND=$(( $OPTIND + 1 )); }
                    [[ -z "$file_arg" ]] || [[ "${file_arg:0:1}" == "-" ]] && {
                        echo "There is no value of option \"-f, --file\"" 2>&1
                        return 1
                    }
                    echo "-f, --file ${file_arg}"
                    ;;
                list )
                    echo "--list"
                    ;;
                * )
                    [[ "$OPTERR" == "1" ]] || [[ "${OPTSPEC:0:1}" == ":" ]] \
                            && echo "Unknown subcommand-long-option --${OPTARG}" >&2 && return 1
                    ;;
                esac
                ;;
            ? )
                [[ "$OPTERR" == "1" ]] || [[ "${OPTSPEC:0:1}" == ":" ]] \
                        && echo "Unknown subcommand-short-option -${OPTARG}" >&2 && return 1
                ;;
            esac
        done
        ;;
#   # Parse subcommand_2 and its options
#   subcommand_2 )
#       while getopts "$OPTSPEC_FOR_SUB_COMMAND_2" optchar; do
#           case "${optchar}" in
#           ......
#           esac
#       done
#   ;;
    * )
        echo "Unknown sub-command" >&2 return 2
        ;;
    esac
    shift $((OPTIND-1))

    for e in "$@"; do
        echo "args: $e"
    done
}

if [[ "${#BASH_SOURCE[@]}" -eq 1 ]]; then
    main "$@"
fi

