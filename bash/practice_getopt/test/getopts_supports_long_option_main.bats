#!/usr/bin/env bats
load helpers "getopts_supports_long_option.sh"

#function setup() {}
#function teardown() {}

@test '#getopts_supports_long_option should analyze -f' {
    run main -f arg_of_from

    declare -a outputs; IFS=$'\n' outputs=($output)
    [[ "$status" -eq 0 ]]
    [[ "${outputs[0]}" == "-f, --from arg_of_from" ]]
}

@test '#getopts_supports_long_option should analyze -f with arg "one"' {
    run main -f arg_of_from one

    declare -a outputs; IFS=$'\n' outputs=($output)
    [[ "$status" -eq 0 ]]
    [[ "${outputs[0]}" == "-f, --from arg_of_from" ]]
    [[ "${outputs[1]}" == "args: one" ]]
}

@test '#getopts_supports_long_option should analyze -f with arg "one" and "two"' {
    run main -f arg_of_from one two

    declare -a outputs; IFS=$'\n' outputs=($output)
    [[ "$status" -eq 0 ]]
    [[ "${outputs[0]}" == "-f, --from arg_of_from" ]]
    [[ "${outputs[1]}" == "args: one" ]]
    [[ "${outputs[2]}" == "args: two" ]]
}

@test '#getopts_supports_long_option should analyze -f with arg "one two"' {
    run main -f arg_of_from "one two"

    declare -a outputs; IFS=$'\n' outputs=($output)
    [[ "$status" -eq 0 ]]
    [[ "${outputs[0]}" == "-f, --from arg_of_from" ]]
    [[ "${outputs[1]}" == "args: one two" ]]
}

@test '#getopts_supports_long_option should analyze -from' {
    run main --from arg_of_from

    declare -a outputs; IFS=$'\n' outputs=($output)
    [[ "$status" -eq 0 ]]
    [[ "${outputs[0]}" == "-f, --from arg_of_from" ]]
}

@test '#getopts_supports_long_option should analyze -from with arg "one"' {
    run main --from arg_of_from one

    declare -a outputs; IFS=$'\n' outputs=($output)
    [[ "$status" -eq 0 ]]
    [[ "${outputs[0]}" == "-f, --from arg_of_from" ]]
    [[ "${outputs[1]}" == "args: one" ]]
}

@test '#getopts_supports_long_option should analyze -from with arg "one" and "two"' {
    run main --from arg_of_from one two

    declare -a outputs; IFS=$'\n' outputs=($output)
    [[ "$status" -eq 0 ]]
    [[ "${outputs[0]}" == "-f, --from arg_of_from" ]]
    [[ "${outputs[1]}" == "args: one" ]]
}

@test '#getopts_supports_long_option should analyze -from with arg "one" and "two"' {
    run main --from arg_of_from one two

    declare -a outputs; IFS=$'\n' outputs=($output)
    [[ "$status" -eq 0 ]]
    [[ "${outputs[0]}" == "-f, --from arg_of_from" ]]
    [[ "${outputs[1]}" == "args: one" ]]
    [[ "${outputs[2]}" == "args: two" ]]
}

@test '#getopts_supports_long_option should analyze -from with arg "one two"' {
    run main --from arg_of_from "one two"

    declare -a outputs; IFS=$'\n' outputs=($output)
    [[ "$status" -eq 0 ]]
    [[ "${outputs[0]}" == "-f, --from arg_of_from" ]]
    [[ "${outputs[1]}" == "args: one two" ]]
}

@test '#getopts_supports_long_option should analyze -from with arg "one two"' {
    run main --from arg_of_from "one two"

    declare -a outputs; IFS=$'\n' outputs=($output)
    [[ "$status" -eq 0 ]]
    [[ "${outputs[0]}" == "-f, --from arg_of_from" ]]
    [[ "${outputs[1]}" == "args: one two" ]]
}

@test '#getopts_supports_long_option should analyze -y' {
    run main -y

    declare -a outputs; IFS=$'\n' outputs=($output)
    [[ "$status" -eq 0 ]]
    [[ "${outputs[0]}" == "-y, --yes" ]]
}

@test '#getopts_supports_long_option should analyze --yes' {
    run main --yes

    declare -a outputs; IFS=$'\n' outputs=($output)
    [[ "$status" -eq 0 ]]
    [[ "${outputs[0]}" == "-y, --yes" ]]
}

@test '#getopts_supports_long_option should analyze -V' {
    run main -V

    declare -a outputs; IFS=$'\n' outputs=($output)
    [[ "$status" -eq 0 ]]
    [[ "${outputs[0]}" == "-V" ]]
}

@test '#getopts_supports_long_option should analyze --vorbose' {
    run main --vorbose

    declare -a outputs; IFS=$'\n' outputs=($output)
    [[ "$status" -eq 0 ]]
    [[ "${outputs[0]}" == "--vorbose" ]]
}

@test '#getopts_supports_long_option should analyze -f and -V' {
    run main -f arg_of_from -V

    declare -a outputs; IFS=$'\n' outputs=($output)
    [[ "$status" -eq 0 ]]
    [[ "${outputs[0]}" == "-f, --from arg_of_from" ]]
    [[ "${outputs[1]}" == "-V" ]]
}

@test '#getopts_supports_long_option should analyze -f and -V and arg' {
    run main -f arg_of_from -V one

    declare -a outputs; IFS=$'\n' outputs=($output)
    [[ "$status" -eq 0 ]]
    [[ "${outputs[0]}" == "-f, --from arg_of_from" ]]
    [[ "${outputs[1]}" == "-V" ]]
    [[ "${outputs[2]}" == "args: one" ]]
}

@test '#getopts_supports_long_option should analyze -V and -f' {
    run main -V -f arg_of_from

    declare -a outputs; IFS=$'\n' outputs=($output)
    [[ "$status" -eq 0 ]]
    [[ "${outputs[0]}" == "-V" ]]
    [[ "${outputs[1]}" == "-f, --from arg_of_from" ]]
}

@test '#getopts_supports_long_option should analyze -V and -f and arg' {
    run main -V -f arg_of_from one

    declare -a outputs; IFS=$'\n' outputs=($output)
    [[ "$status" -eq 0 ]]
    [[ "${outputs[0]}" == "-V" ]]
    [[ "${outputs[1]}" == "-f, --from arg_of_from" ]]
    [[ "${outputs[2]}" == "args: one" ]]
}

@test '#getopts_supports_long_option should error with unknown short option' {
    run main -z

    declare -a outputs; IFS=$'\n' outputs=($output)
    [[ "$status" -eq 1 ]]
    [[ "${outputs[0]}" == "Unknown short option -z" ]]
}

@test '#getopts_supports_long_option should error with unknown short option and argument' {
    run main -z foo

    declare -a outputs; IFS=$'\n' outputs=($output)
    [[ "$status" -eq 1 ]]
    [[ "${outputs[0]}" == "Unknown short option -z" ]]
}

@test '#getopts_supports_long_option should error with unknown short option and known short option' {
    run main -z -f arg_of_from

    declare -a outputs; IFS=$'\n' outputs=($output)
    [[ "$status" -eq 1 ]]
    [[ "${outputs[0]}" == "Unknown short option -z" ]]
}

@test '#getopts_supports_long_option should error with known short option and unknown short option' {
    run main -f arg_of_from -z

    declare -a outputs; IFS=$'\n' outputs=($output)
    [[ "$status" -eq 1 ]]
    [[ "${outputs[0]}" == "-f, --from arg_of_from" ]]
    [[ "${outputs[1]}" == "Unknown short option -z" ]]
}

@test '#getopts_supports_long_option should error with unknown short option and known long option' {
    run main -z --from arg_of_from

    declare -a outputs; IFS=$'\n' outputs=($output)
    [[ "$status" -eq 1 ]]
    [[ "${outputs[0]}" == "Unknown short option -z" ]]
}

@test '#getopts_supports_long_option should error with known long option and unknown short option' {
    run main --from arg_of_from -z

    declare -a outputs; IFS=$'\n' outputs=($output)
    [[ "$status" -eq 1 ]]
    [[ "${outputs[0]}" == "-f, --from arg_of_from" ]]
    [[ "${outputs[1]}" == "Unknown short option -z" ]]
}

@test '#getopts_supports_long_option should error with unknown long option' {
    run main --zone

    declare -a outputs; IFS=$'\n' outputs=($output)
    [[ "$status" -eq 1 ]]
    [[ "${outputs[0]}" == "Unknown long option --zone" ]]
}

@test '#getopts_supports_long_option should error with unknown long option and an argument' {
    run main --zone one

    declare -a outputs; IFS=$'\n' outputs=($output)
    [[ "$status" -eq 1 ]]
    [[ "${outputs[0]}" == "Unknown long option --zone" ]]
}

@test '#getopts_supports_long_option should error with unknown long option and 2 arguments' {
    run main --zone one two

    declare -a outputs; IFS=$'\n' outputs=($output)
    [[ "$status" -eq 1 ]]
    [[ "${#outputs[@]}" -eq 1 ]]
    [[ "${outputs[0]}" == "Unknown long option --zone" ]]
}

@test '#getopts_supports_long_option should error with unknown long option and known short option' {
    run main --zone -f arg_of_from

    declare -a outputs; IFS=$'\n' outputs=($output)
    [[ "$status" -eq 1 ]]
    [[ "${#outputs[@]}" -eq 1 ]]
    [[ "${outputs[0]}" == "Unknown long option --zone" ]]
}

@test '#getopts_supports_long_option should error with known short option and unknown long option' {
    run main --zone -f arg_of_from

    declare -a outputs; IFS=$'\n' outputs=($output)
    [[ "$status" -eq 1 ]]
    [[ "${#outputs[@]}" -eq 1 ]]
    [[ "${outputs[0]}" == "Unknown long option --zone" ]]
}

@test '#getopts_supports_long_option should error with unknown long option and known long option' {
    run main --zone --from arg_of_from

    declare -a outputs; IFS=$'\n' outputs=($output)
    [[ "$status" -eq 1 ]]
    [[ "${#outputs[@]}" -eq 1 ]]
    [[ "${outputs[0]}" == "Unknown long option --zone" ]]
}

@test '#getopts_supports_long_option should error with known long option and unknown long option' {
    run main --from arg_of_from --zone

    declare -a outputs; IFS=$'\n' outputs=($output)
    [[ "$status" -eq 1 ]]
    [[ "${#outputs[@]}" -eq 2 ]]
    [[ "${outputs[0]}" == "-f, --from arg_of_from" ]]
    [[ "${outputs[1]}" == "Unknown long option --zone" ]]
}

