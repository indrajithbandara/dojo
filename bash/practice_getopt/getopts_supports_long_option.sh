#!/bin/bash
OPTSPEC=":f:yV-:"

function main() {
    local from_arg

    while getopts "$OPTSPEC" optchar; do
        case "$optchar" in
        f )
            # optchar="-from"
            from_arg=${OPTARG}
            OPTARG="from"
            ;;&
        y )
            # The option that has short option and long one without args.
            OPTARG="yes"
            ;;&
        V )
            # Only short option must terminate with ";;"
            echo "-V"
            ;;
        - | f | y)
            # long options
            case "$OPTARG" in
            from )
                [[ -z "$from_arg" ]] && { from_arg="${!OPTIND}"; OPTIND=$(( $OPTIND + 1 )); }
                echo "-f, --from ${from_arg}"
                ;;
            yes )
                echo "-y, --yes"
                ;;
            vorbose )
                # Only long option
                echo "--vorbose"
                ;;
            * )
                # [[ "$OPTERR" == "1" ]] && [[ "${OPTSPEC:0:1}" != ":" ]] \
                [[ "$OPTERR" == "1" ]] || [[ "${OPTSPEC:0:1}" == ":" ]] \
                        && echo "Unknown long option --${OPTARG}" >&2 && return 1
                ;;
            esac
        ;;
        ? )
            [[ "$OPTERR" == "1" ]] || [[ "${OPTSPEC:0:1}" == ":" ]] \
                    && echo "Unknown short option -${OPTARG}" >&2 && return 1
            ;;
        esac
    done
    shift $((OPTIND-1))

    for e in "$@"; do
        echo "args: $e"
    done
}

if [[ "${#BASH_SOURCE[@]}" -eq 1 ]]; then
    main "$@"
fi

