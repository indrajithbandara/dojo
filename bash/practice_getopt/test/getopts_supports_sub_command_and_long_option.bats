#!/usr/bin/env bats
load helpers "getopts_supports_sub_command_and_long_option.sh"

#function setup() {}
#function teardown() {}

@test '#getopts_supports_sub_command_and_long_option should ayalyze "command subcommand"' {
    run main subcommand

    declare -a outputs; IFS=$'\n' outputs=($output)
    [[ "$status" -eq 0 ]]
    [[ "${outputs[0]}" == "subcommand" ]]
}

@test '#getopts_supports_sub_command_and_long_option should ayalyze "command" (error)' {
    run main

    declare -a outputs; IFS=$'\n' outputs=($output)
    [[ "$status" -eq 1 ]]
    [[ "${outputs[0]}" == "There is no subcommand" ]]
}

@test '#getopts_supports_sub_command_and_long_option should ayalyze "command -H (without subcommand)" (error)' {
    run main -H

    declare -a outputs; IFS=$'\n' outputs=($output)
    [[ "$status" -eq 1 ]]
    [[ "${outputs[0]}" == "-H, --help" ]]
    [[ "${outputs[1]}" == "There is no subcommand" ]]
}

@test '#getopts_supports_sub_command_and_long_option should ayalyze "command subcommand"' {
    run main subcommand

    declare -a outputs; IFS=$'\n' outputs=($output)
    [[ "$status" -eq 0 ]]
    [[ "${outputs[0]}" == "subcommand" ]]
}

@test '#getopts_supports_sub_command_and_long_option should ayalyze "command -H subcommand"' {
    run main -H subcommand

    declare -a outputs; IFS=$'\n' outputs=($output)
    [[ "$status" -eq 0 ]]
    [[ "${outputs[0]}" == "-H, --help" ]]
    [[ "${outputs[1]}" == "subcommand" ]]
}

@test '#getopts_supports_sub_command_and_long_option should ayalyze "command -d subcommand"' {
    run main -d subcommand

    declare -a outputs; IFS=$'\n' outputs=($output)
    [[ "$status" -eq 0 ]]
    [[ "${outputs[0]}" == "-d" ]]
    [[ "${outputs[1]}" == "subcommand" ]]
}

@test '#getopts_supports_sub_command_and_long_option should ayalyze "command -C <path> subcommand"' {
    run main -C arg_of_workdir subcommand

    declare -a outputs; IFS=$'\n' outputs=($output)
    [[ "$status" -eq 0 ]]
    [[ "${outputs[0]}" == "-C, --workdir arg_of_workdir" ]]
    [[ "${outputs[1]}" == "subcommand" ]]
}

@test '#getopts_supports_sub_command_and_long_option should ayalyze "command -C -d subcommand" (error due to no argument of -C)' {
    run main -C -d subcommand

    declare -a outputs; IFS=$'\n' outputs=($output)
    [[ "$status" -eq 1 ]]
    [[ "${#outputs[@]}" -eq 1 ]]
    [[ "${outputs[0]}" == "There is no value of option \"-C, --workdir\"" ]]
}

@test '#getopts_supports_sub_command_and_long_option should ayalyze "command --version subcommand"' {
    run main --version subcommand

    declare -a outputs; IFS=$'\n' outputs=($output)
    [[ "$status" -eq 0 ]]
    [[ "${#outputs[@]}" -eq 2 ]]
    [[ "${outputs[0]}" == "--version" ]]
    [[ "${outputs[1]}" == "subcommand" ]]
}

@test '#getopts_supports_sub_command_and_long_option should ayalyze "command --help -d --version --workdir path subcommand"' {
    run main --help -d --version --workdir path subcommand

    declare -a outputs; IFS=$'\n' outputs=($output)
    [[ "$status" -eq 0 ]]
    [[ "${#outputs[@]}" -eq 5 ]]
    [[ "${outputs[0]}" == "-H, --help" ]]
    [[ "${outputs[1]}" == "-d" ]]
    [[ "${outputs[2]}" == "--version" ]]
    [[ "${outputs[3]}" == "-C, --workdir path" ]]
    [[ "${outputs[4]}" == "subcommand" ]]
}

@test '#getopts_supports_sub_command_and_long_option should ayalyze unknown short option of main command' {
    run main -z

    declare -a outputs; IFS=$'\n' outputs=($output)
    [[ "$status" -eq 1 ]]
    [[ "${#outputs[@]}" -eq 1 ]]
    [[ "${outputs[0]}" == "Unknown short option of main command" ]]
}

@test '#getopts_supports_sub_command_and_long_option should ayalyze unknown long option of main command' {
    run main --zone

    declare -a outputs; IFS=$'\n' outputs=($output)
    [[ "$status" -eq 1 ]]
    [[ "${#outputs[@]}" -eq 1 ]]
    [[ "${outputs[0]}" == "Unknown long option of main command" ]]
}

## options in subcommand

@test '#getopts_supports_sub_command_and_long_option should ayalyze "command subcommand -H"' {
    run main subcommand -H

    declare -a outputs; IFS=$'\n' outputs=($output)
    [[ "$status" -eq 0 ]]
    [[ "${#outputs[@]}" -eq 2 ]]
    [[ "${outputs[0]}" == "subcommand" ]]
    [[ "${outputs[1]}" == "-H, --help" ]]
}

@test '#getopts_supports_sub_command_and_long_option should ayalyze "command subcommand -i"' {
    run main subcommand -i

    declare -a outputs; IFS=$'\n' outputs=($output)
    [[ "$status" -eq 0 ]]
    [[ "${#outputs[@]}" -eq 2 ]]
    [[ "${outputs[0]}" == "subcommand" ]]
    [[ "${outputs[1]}" == "-i" ]]
}

@test '#getopts_supports_sub_command_and_long_option should ayalyze "command subcommand -f, --file filename"' {
    run main subcommand -f filename

    declare -a outputs; IFS=$'\n' outputs=($output)
    [[ "$status" -eq 0 ]]
    [[ "${#outputs[@]}" -eq 2 ]]
    [[ "${outputs[0]}" == "subcommand" ]]
    [[ "${outputs[1]}" == "-f, --file filename" ]]
}

@test '#getopts_supports_sub_command_and_long_option should ayalyze "command subcommand -f -H" (error due to no argument of -f)' {
    run main subcommand -f -H

    declare -a outputs; IFS=$'\n' outputs=($output)
    [[ "$status" -eq 1 ]]
    [[ "${#outputs[@]}" -eq 2 ]]
    [[ "${outputs[0]}" == "subcommand" ]]
    [[ "${outputs[1]}" == "There is no value of option \"-f, --file\"" ]]
}

@test '#getopts_supports_sub_command_and_long_option should ayalyze "command subcommand -f" (error due to no argument of -f)' {
    run main subcommand -f ""

    declare -a outputs; IFS=$'\n' outputs=($output)
    [[ "$status" -eq 1 ]]
    [[ "${#outputs[@]}" -eq 2 ]]
    [[ "${outputs[0]}" == "subcommand" ]]
    [[ "${outputs[1]}" == "There is no value of option \"-f, --file\"" ]]
}

@test '#getopts_supports_sub_command_and_long_option should ayalyze "command subcommand --help"' {
    run main subcommand --help

    declare -a outputs; IFS=$'\n' outputs=($output)
    [[ "$status" -eq 0 ]]
    [[ "${#outputs[@]}" -eq 2 ]]
    [[ "${outputs[0]}" == "subcommand" ]]
    [[ "${outputs[1]}" == "-H, --help" ]]
}

@test '#getopts_supports_sub_command_and_long_option should ayalyze "command subcommand --file path"' {
    run main subcommand --file filename

    declare -a outputs; IFS=$'\n' outputs=($output)
    [[ "$status" -eq 0 ]]
    [[ "${#outputs[@]}" -eq 2 ]]
    [[ "${outputs[0]}" == "subcommand" ]]
    [[ "${outputs[1]}" == "-f, --file filename" ]]
}

@test '#getopts_supports_sub_command_and_long_option should ayalyze "command subcommand --list"' {
    run main subcommand --list

    declare -a outputs; IFS=$'\n' outputs=($output)
    [[ "$status" -eq 0 ]]
    [[ "${#outputs[@]}" -eq 2 ]]
    [[ "${outputs[0]}" == "subcommand" ]]
    [[ "${outputs[1]}" == "--list" ]]
}

@test '#getopts_supports_sub_command_and_long_option should ayalyze unknown short option of sub command' {
    run main subcommand -z

    declare -a outputs; IFS=$'\n' outputs=($output)
    [[ "$status" -eq 1 ]]
    [[ "${#outputs[@]}" -eq 2 ]]
    [[ "${outputs[0]}" == "subcommand" ]]
    [[ "${outputs[1]}" == "Unknown subcommand-short-option -z" ]]
}

@test '#getopts_supports_sub_command_and_long_option should ayalyze unknown long option of sub command' {
    run main subcommand --zone

    declare -a outputs; IFS=$'\n' outputs=($output)
    [[ "$status" -eq 1 ]]
    [[ "${#outputs[@]}" -eq 2 ]]
    [[ "${outputs[0]}" == "subcommand" ]]
    [[ "${outputs[1]}" == "Unknown subcommand-long-option --zone" ]]
}

