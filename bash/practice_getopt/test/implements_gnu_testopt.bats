#!/usr/bin/env bats
load helpers "implements_gnu_getopt.sh"

@test '#implements_gnu_getopt should analyze getopses -- (no arguments)' {
    run getoptses --

    [[ "$output" == "" ]]
}

@test '#implements_gnu_getopt should analyze getopses -- "" (an argument that length of 0)' {
    run getoptses -- ""

    [[ "$output" == "-- ''" ]]
}

@test '#implements_gnu_getopt should analyze getopses -- "" "" (expected "-- '' ''")' {
    run getoptses -- "" ""

    [[ "$output" == "-- '' ''" ]]
}

@test '#implements_gnu_getopt should analyze getopses -o "a" -- -a (expected "-a")' {
    run getoptses -o "a" -- -a

    [[ "$output" == "-a" ]]
}

@test '#implements_gnu_getopt should analyze getopses -o "a" -- arg1 (expected "-- arg1")' {
    declare -a args=("arg1")
    run getoptses -o "a" -- "${args[@]}"

    [[ "$output" == "-- 'arg1'" ]]
}

@test '#implements_gnu_getopt should analyze getopses -o "a" -- -a arg1 (expected "-a -- arg1")' {
    declare -a args=("-a" "arg1")
    run getoptses -o "a" -- "${args[@]}"

    [[ "$output" == "-a -- 'arg1'" ]]
}

@test '#implements_gnu_getopt should analyze getopses -o "a" -- arg1 -a (expected "-a -- arg1")' {
    declare -a args=("arg1" "-a")
    run getoptses -o "a" -- "${args[@]}"

    [[ "$output" == "-a -- 'arg1'" ]]
}


@test '#implements_gnu_getopt should analyze getopses -o "ab" -- (expected "")' {
    declare -a args=()
    run getoptses -o "ab" -- "${args[@]}"

    [[ "$output" == "" ]]
}

@test '#implements_gnu_getopt should analyze getopses -o "ab" -- -a (expected "")' {
    declare -a args=("-a")
    run getoptses -o "ab" -- "${args[@]}"

    [[ "$output" == "-a" ]]
}

@test '#implements_gnu_getopt should analyze getopses -o "ab" -- -a -b (expected "-a -b")' {
    declare -a args=("-a" "-b")
    run getoptses -o "ab" -- "${args[@]}"

    [[ "$output" == "-a -b" ]]
}

@test '#implements_gnu_getopt should analyze getopses -o "ab" -- arg1 -a -b (expected "-a -b -- arg1")' {
    declare -a args=("arg1" "-a" "-b")
    run getoptses -o "ab" -- "${args[@]}"

    [[ "$output" == "-a -b -- 'arg1'" ]]
}

@test '#implements_gnu_getopt should analyze getopses -o "ab" -- -a arg1 -b (expected "-a -b -- arg1")' {
    declare -a args=("-a" "arg1" "-b")
    run getoptses -o "ab" -- "${args[@]}"

    [[ "$output" == "-a -b -- 'arg1'" ]]
}

@test '#implements_gnu_getopt should analyze getopses -o "ab" -- -a -b arg1 (expected "-a -b -- arg1")' {
    declare -a args=("-a" "-b" "arg1")
    run getoptses -o "ab" -- "${args[@]}"

    [[ "$output" == "-a -b -- 'arg1'" ]]
}




@test '#implements_gnu_getopt should analyze getopses -o "ab" -- -ab (expected "-a -b")' {
    declare -a args=("-ab")
    run getoptses -o "ab" -- "${args[@]}"

    [[ "$output" == "-a -b" ]]
}

@test '#implements_gnu_getopt should analyze getopses -o "ab" -- -ba (expected "-a -b")' {
    declare -a args=("-ba")
    run getoptses -o "ab" -- "${args[@]}"

    [[ "$output" == "-b -a" ]]
}

@test '#implements_gnu_getopt should analyze getopses -o "ab" -- -ba arg1 (expected "-a -b -- arg1")' {
    declare -a args=("-ba" "arg1")
    run getoptses -o "ab" -- "${args[@]}"

    [[ "$output" == "-b -a -- 'arg1'" ]]
}

@test '#implements_gnu_getopt should analyze getopses -o "ab" -- arg1 -ab (expected "-a -b -- arg1")' {
    declare -a args=("-ba" "arg1")
    run getoptses -o "ab" -- "${args[@]}"

    [[ "$output" == "-b -a -- 'arg1'" ]]
}

@test '#implements_gnu_getopt should analyze getopses -o "ba" -- -a -b (expected "-a -b")' {
    declare -a args=("-a" "-b")
    run getoptses -o "ba" -- "${args[@]}"

    [[ "$output" == "-a -b" ]]
}

@test '#implements_gnu_getopt should analyze getopses -o "ba" -- -ab (expected "-a -b")' {
    declare -a args=("-ab")
    run getoptses -o "ba" -- "${args[@]}"

    [[ "$output" == "-a -b" ]]
}

@test '#implements_gnu_getopt should analyze getopses -o "ba" -- -ba (expected "-b -a")' {
    declare -a args=("-ba")
    run getoptses -o "ba" -- "${args[@]}"

    [[ "$output" == "-b -a" ]]
}

@test '#implements_gnu_getopt should analyze getopses -o "a:" -- (expected "")' {
    declare -a args=("")
    run getoptses -o "a:" --

    [[ "$output" == "" ]]
}

@test '#implements_gnu_getopt should analyze getopses -o "a:" -- -a val_a (expected "-a val_a")' {
    declare -a args=("-a" "val_a")
    run getoptses -o "a:" -- "${args[@]}"

    [[ "$output" == "-a 'val_a'" ]]
}

@test '#implements_gnu_getopt should analyze getopses -o "a:" -- arg1 -a val_a (expected "-a val_a -- arg1")' {
    declare -a args=("arg1" "-a" "val_a")
    run getoptses -o "a:" -- "${args[@]}"

    [[ "$output" == "-a 'val_a' -- 'arg1'" ]]
}

@test '#implements_gnu_getopt should analyze getopses -o "a:" -- -a val_a arg1 (expected "-a val_a -- arg1")' {
    declare -a args=("-a" "val_a" "arg1")
    run getoptses -o "a:" -- "${args[@]}"

    [[ "$output" == "-a 'val_a' -- 'arg1'" ]]
}





@test '#implements_gnu_getopt should analyze getopses -o "a:b:" --  (expected "")' {
    run getoptses -o "a:b:" --

    [[ "$output" == "" ]]
}

@test '#implements_gnu_getopt should analyze getopses -o "a:b:" -- -a val_a -b val_b (expected "-a val_a -b val_b")' {
    declare -a args=("-a" "val_a" "-b" "val_b")
    run getoptses -o "a:b:" -- "${args[@]}"

    [[ "$output" == "-a 'val_a' -b 'val_b'" ]]
}

@test '#implements_gnu_getopt should analyze getopses -o "a:b:" -- -a val_a (expected "-a val_a")' {
    declare -a args=("-a" "val_a")
    run getoptses -o "a:b:" -- "${args[@]}"

    [[ "$output" == "-a 'val_a'" ]]
}

@test '#implements_gnu_getopt should analyze getopses -o "a:b:" -- -a val_a (expected "-b val_b")' {
    declare -a args=("-a" "val_a")
    run getoptses -o "a:b:" -- "${args[@]}"

    [[ "$output" == "-a 'val_a'" ]]
}

@test '#implements_gnu_getopt should analyze getopses -o "b:a:" -- -b val_b -a val_a (expected "-b val_b -a val_a")' {
    declare -a args=("-b" "val_b" "-a" "val_a")
    run getoptses -o "b:a:" -- "${args[@]}"

    [[ "$output" == "-b 'val_b' -a 'val_a'" ]]
}

@test '#implements_gnu_getopt should analyze getopses -o "b:a:" -- -a val_a (expected "-a val_a")' {
    declare -a args=("-a" "val_a")
    run getoptses -o "b:a:" -- "${args[@]}"

    [[ "$output" == "-a 'val_a'" ]]
}

@test '#implements_gnu_getopt should analyze getopses -o "b:a:" -- -b val_b (expected "-b val_b")' {
    declare -a args=("-b" "val_b")
    run getoptses -o "b:a:" -- "${args[@]}"

    [[ "$output" == "-b 'val_b'" ]]
}

@test '#implements_gnu_getopt should analyze getopses -o "a:b:" -- -a val_a -b val_b arg1 (expected "-a val_a -b val_b -- arg1")' {
    declare -a args=("-a" "val_a" "-b" "val_b" "arg1")
    run getoptses -o "a:b:" -- "${args[@]}"

    [[ "$output" == "-a 'val_a' -b 'val_b' -- 'arg1'" ]]
}

@test '#implements_gnu_getopt should analyze getopses -o "a:b:" -- -b val_b -a val_a arg1 (expected "-a val_a -b val_b -- arg1")' {
    declare -a args=("-b" "val_b" "-a" "val_a" "arg1")
    run getoptses -o "a:b:" -- "${args[@]}"

    [[ "$output" == "-b 'val_b' -a 'val_a' -- 'arg1'" ]]
}

@test '#implements_gnu_getopt should analyze getopses -o "a:b:" -- -a val_a arg1 -b val_b (expected "-a val_a -b val_b -- arg1")' {
    declare -a args=("-a" "val_a" "arg1" "-b" "val_b")
    run getoptses -o "a:b:" -- "${args[@]}"

    [[ "$output" == "-a 'val_a' -b 'val_b' -- 'arg1'" ]]
}

@test '#implements_gnu_getopt should analyze getopses -o "a:b:" -- -b val_b arg1 -a val_a (expected "-b val_b -a val_a -- arg1")' {
    declare -a args=("-b" "val_b" "arg1" "-a" "val_a")
    run getoptses -o "a:b:" -- "${args[@]}"

    [[ "$output" == "-b 'val_b' -a 'val_a' -- 'arg1'" ]]
}

@test '#implements_gnu_getopt should analyze getopses -o "a:b:" -- arg1 -a val_a -b val_b (expected "-a val_a -b val_b -- arg1")' {
    declare -a args=("arg1" "-a" "val_a" "-b" "val_b")
    run getoptses -o "a:b:" -- "${args[@]}"

    [[ "$output" == "-a 'val_a' -b 'val_b' -- 'arg1'" ]]
}

@test '#implements_gnu_getopt should analyze getopses -o "a:b:" -- arg1 -b val_b -a val_a (expected "-b val_b -a val_a -- arg1")' {
    declare -a args=("arg1" "-b" "val_b" "-a" "val_a")
    run getoptses -o "a:b:" -- "${args[@]}"

    [[ "$output" == "-b 'val_b' -a 'val_a' -- 'arg1'" ]]
}

# option that has no value and option that has a value

@test '#implements_gnu_getopt should analyze getopses -o "ab:" -- -a -b val_b (expected "-a -b val_b")' {
    declare -a args=("-a" "-b" "val_b")
    run getoptses -o "ab:" -- "${args[@]}"

    [[ "$output" == "-a -b 'val_b'" ]]
}

@test '#implements_gnu_getopt should analyze getopses -o "ab:" -- -b val_b -a (expected "-a -b val_b")' {
    declare -a args=("-b" "val_b" "-a")
    run getoptses -o "ab:" -- "${args[@]}"

    [[ "$output" == "-b 'val_b' -a" ]]
}

@test '#implements_gnu_getopt should analyze getopses -o "ab:" -- -a -b val_b arg1 (expected "-a -b val_b -- arg1")' {
    declare -a args=("-a" "-b" "val_b" "arg1")
    run getoptses -o "ab:" -- "${args[@]}"

    [[ "$output" == "-a -b 'val_b' -- 'arg1'" ]]
}

@test '#implements_gnu_getopt should analyze getopses -o "ab:" -- -a arg1 -b val_b (expected "-a -b val_b -- arg1")' {
    declare -a args=("-a" "arg1" "-b" "val_b")
    run getoptses -o "ab:" -- "${args[@]}"

    [[ "$output" == "-a -b 'val_b' -- 'arg1'" ]]
}

@test '#implements_gnu_getopt should analyze getopses -o "ab:" -- arg1 -a -b val_b (expected "-a -b val_b -- arg1")' {
    declare -a args=("arg1" "-a" "-b" "val_b")
    run getoptses -o "ab:" -- "${args[@]}"

    [[ "$output" == "-a -b 'val_b' -- 'arg1'" ]]
}

# long options -------------------------------------------------

@test '#implements_gnu_getopt should analyze getopses --longoptions "long-a" -- (expected "")' {
    run getoptses --longoptions "long-a" --

    [[ "$output" == "" ]]
}

@test '#implements_gnu_getopt should analyze getopses --longoptions "long-a" -- --long-a (expected "--long-a")' {
    declare -a args=("--long-a")
    run getoptses --longoptions "long-a" -- "${args[@]}"

    [[ "$output" == "--long-a" ]]
}

@test '#implements_gnu_getopt should analyze getopses --longoptions "long-a" -- arg1 (expected "-- arg1")' {
    declare -a args=("arg1")
    run getoptses --longoptions "long-a" -- "${args[@]}"

    [[ "$output" == "-- 'arg1'" ]]
}

@test '#implements_gnu_getopt should analyze getopses --longoptions "long-a" -- --long-a arg1 (expected "--long-a -- arg1")' {
    declare -a args=("--long-a" "arg1")
    run getoptses --longoptions "long-a" -- "${args[@]}"

    [[ "$output" == "--long-a -- 'arg1'" ]]
}

@test '#implements_gnu_getopt should analyze getopses --longoptions "long-a" -- arg1 --long-a (expected "--long-a -- arg1")' {
    declare -a args=("arg1" "--long-a")
    run getoptses --longoptions "long-a" -- "${args[@]}"

    [[ "$output" == "--long-a -- 'arg1'" ]]
}

@test '#implements_gnu_getopt should analyze getopses --longoptions "long-a:" -- (expected "")' {
    run getoptses --longoptions "long-a:" --

    [[ "$output" == "" ]]
}

@test '#implements_gnu_getopt should analyze getopses --longoptions "long-a:" -- --long-a val_a (expected "--long-a val_a")' {
    declare -a args=("--long-a" "val_a")
    run getoptses --longoptions "long-a:" -- "${args[@]}"

    [[ "$output" == "--long-a 'val_a'" ]]
}

@test '#implements_gnu_getopt should analyze getopses --longoptions "long-a:" -- --long-a val_a arg1 (expected "--long-a val_a -- arg1")' {
    declare -a args=("--long-a" "val_a" "arg1")
    run getoptses --longoptions "long-a:" -- "${args[@]}"

    [[ "$output" == "--long-a 'val_a' -- 'arg1'" ]]
}

@test '#implements_gnu_getopt should analyze getopses --longoptions "long-a:" -- arg1 --long-a val_a (expected "--long-a val_a -- arg1")' {
    declare -a args=("--long-a" "val_a" "arg1")
    run getoptses --longoptions "long-a:" -- "${args[@]}"

    [[ "$output" == "--long-a 'val_a' -- 'arg1'" ]]
}

# double long option tha has no value

@test '#implements_gnu_getopt should analyze getopses --longoptions "long-a,long-b" -- (expected "--long-a --long-b")' {
    run getoptses --longoptions "long-a,long-b" --

    [[ "$output" == "" ]]
}

@test '#implements_gnu_getopt should analyze getopses --longoptions "long-a,long-b" -- --long-a (expected "--long-a")' {
    declare -a args=("--long-a")
    run getoptses --longoptions "long-a,long-b" -- "${args[@]}"

    [[ "$output" == "--long-a" ]]
}

@test '#implements_gnu_getopt should analyze getopses --longoptions "long-a,long-b" -- --long-b (expected "--long-b")' {
    declare -a args=("--long-b")
    run getoptses --longoptions "long-a,long-b" -- "${args[@]}"

    [[ "$output" == "--long-b" ]]
}



@test '#implements_gnu_getopt should analyze getopses --longoptions "long-a,long-b" -- --long-a --long-b (expected "--long-a --long-b")' {
    declare -a args=("--long-a" "--long-b")
    run getoptses --longoptions "long-a,long-b" -- "${args[@]}"

    [[ "$output" == "--long-a --long-b" ]]
}

@test '#implements_gnu_getopt should analyze getopses --longoptions "long-b,long-a" -- --long-a --long-b (expected "--long-a --long-b")' {
    declare -a args=("--long-a" "--long-b")
    run getoptses --longoptions "long-b,long-a" -- "${args[@]}"

    [[ "$output" == "--long-a --long-b" ]]
}

@test '#implements_gnu_getopt should analyze getopses --longoptions "long-a,long-b" -- --long-b --long-a (expected "--long-b --long-a")' {
    declare -a args=("--long-b" "--long-a")
    run getoptses --longoptions "long-a,long-b" -- "${args[@]}"

    [[ "$output" == "--long-b --long-a" ]]
}

@test '#implements_gnu_getopt should analyze getopses --longoptions "long-a,long-b" -- --long-a --long-b arg1 (expected "--long-a --long-b -- arg1")' {
    declare -a args=("--long-a" "--long-b" "arg1")
    run getoptses --longoptions "long-a,long-b" -- "${args[@]}"

    [[ "$output" == "--long-a --long-b -- 'arg1'" ]]
}

@test '#implements_gnu_getopt should analyze getopses --longoptions "long-a,long-b" -- --long-a arg1 --long-b (expected "--long-a --long-b -- arg1")' {
    declare -a args=("--long-a" "arg1" "--long-b")
    run getoptses --longoptions "long-a,long-b" -- "${args[@]}"

    [[ "$output" == "--long-a --long-b -- 'arg1'" ]]
}

@test '#implements_gnu_getopt should analyze getopses --longoptions "long-a,long-b" -- arg1 --long-a --long-b (expected "--long-a --long-b -- arg1")' {
    declare -a args=("arg1" "--long-a" "--long-b")
    run getoptses --longoptions "long-a,long-b" -- "${args[@]}"

    [[ "$output" == "--long-a --long-b -- 'arg1'" ]]
}

@test '#implements_gnu_getopt should analyze getopses --longoptions "long-b,long-a" -- --long-a --long-b arg1 (expected "--long-a --long-b -- arg1")' {
    declare -a args=("--long-a" "--long-b" "arg1")
    run getoptses --longoptions "long-b,long-a" -- "${args[@]}"

    [[ "$output" == "--long-a --long-b -- 'arg1'" ]]
}

@test '#implements_gnu_getopt should analyze getopses --longoptions "long-b,long-a" -- --long-a arg1 --long-b (expected "--long-a --long-b -- arg1")' {
    declare -a args=("--long-a" "arg1" "--long-b")
    run getoptses --longoptions "long-b,long-a" -- "${args[@]}"

    [[ "$output" == "--long-a --long-b -- 'arg1'" ]]
}

@test '#implements_gnu_getopt should analyze getopses --longoptions "long-b,long-a" -- arg1 --long-a --long-b (expected "--long-a --long-b -- arg1")' {
    declare -a args=("arg1" "--long-a" "--long-b")
    run getoptses --longoptions "long-b,long-a" -- "${args[@]}"

    [[ "$output" == "--long-a --long-b -- 'arg1'" ]]
}

# long options that has values -------------------------------------------------

@test '#implements_gnu_getopt should analyze getopses --longoptions "long-a:,long-b:" -- (expected "")' {
    run getoptses --longoptions "long-b,long-a" --

    [[ "$output" == "" ]]
}

@test '#implements_gnu_getopt should analyze getopses --longoptions "long-a:,long-b:" -- --long-a val_a --long-b val_b (expected "--long-a val_a --long-b val_b")' {
    declare -a args=("--long-a" "val_a" "--long-b" "val_b")
    run getoptses --longoptions "long-a:,long-b:" -- "${args[@]}"

    [[ "$output" == "--long-a 'val_a' --long-b 'val_b'" ]]
}

@test '#implements_gnu_getopt should analyze getopses --longoptions "long-b:,long-a:" -- --long-a val_a --long-b val_b (expected "--long-a val_a --long-b val_b")' {
    declare -a args=("--long-a" "val_a" "--long-b" "val_b")
    run getoptses --longoptions "long-b:,long-a:" -- "${args[@]}"

    [[ "$output" == "--long-a 'val_a' --long-b 'val_b'" ]]
}

@test '#implements_gnu_getopt should analyze getopses --longoptions "long-a:,long-b:" -- --long-b val_b --long-a val_a (expected "--long-b val_b --long-a val_a")' {
    declare -a args=("--long-b" "val_b" "--long-a" "val_a")
    run getoptses --longoptions "long-a:,long-b:" -- "${args[@]}"

    [[ "$output" == "--long-b 'val_b' --long-a 'val_a'" ]]
}

@test '#implements_gnu_getopt should analyze getopses --longoptions "long-a:,long-b:" -- --long-a val_a --long-b val_b arg1 (expected "--long-a val_a --long-b val_b -- arg1")' {
    declare -a args=("--long-a" "val_a" "--long-b" "val_b" "arg1")
    run getoptses --longoptions "long-a:,long-b:" -- "${args[@]}"

    [[ "$output" == "--long-a 'val_a' --long-b 'val_b' -- 'arg1'" ]]
}

@test '#implements_gnu_getopt should analyze getopses --longoptions "long-a:,long-b:" -- --long-a val_a arg1 --long-b val_b (expected "--long-a val_a --long-b val_b -- arg1")' {
    declare -a args=("--long-a" "val_a" "arg1" "--long-b" "val_b")
    run getoptses --longoptions "long-a:,long-b:" -- "${args[@]}"

    [[ "$output" == "--long-a 'val_a' --long-b 'val_b' -- 'arg1'" ]]
}

@test '#implements_gnu_getopt should analyze getopses --longoptions "long-a:,long-b:" -- arg1 --long-a val_a --long-b val_b (expected "--long-a val_a --long-b val_b -- arg1")' {
    declare -a args=("arg1" "--long-a" "val_a" "--long-b" "val_b")
    run getoptses --longoptions "long-a:,long-b:" -- "${args[@]}"

    [[ "$output" == "--long-a 'val_a' --long-b 'val_b' -- 'arg1'" ]]
}

@test '#implements_gnu_getopt should analyze getopses --longoptions "long-a:,long-b:" -- --long-a val_a arg1 (expected "--long-a val_a -- arg1")' {
    declare -a args=("--long-a" "val_a" "arg1")
    run getoptses --longoptions "long-a:,long-b:" -- "${args[@]}"

    [[ "$output" == "--long-a 'val_a' -- 'arg1'" ]]
}

@test '#implements_gnu_getopt should analyze getopses --longoptions "long-a:,long-b:" -- arg1 --long-a val_a (expected "--long-a val_a -- arg1")' {
    declare -a args=("arg1" "--long-a" "val_a")
    run getoptses --longoptions "long-a:,long-b:" -- "${args[@]}"

    [[ "$output" == "--long-a 'val_a' -- 'arg1'" ]]
}

@test '#implements_gnu_getopt should analyze getopses --longoptions "long-a:,long-b:" -- --long-b val_b arg1 (expected "--long-a val_a -- arg1")' {
    declare -a args=("--long-b" "val_b" "arg1")
    run getoptses --longoptions "long-a:,long-b:" -- "${args[@]}"

    [[ "$output" == "--long-b 'val_b' -- 'arg1'" ]]
}

@test '#implements_gnu_getopt should analyze getopses --longoptions "long-a:,long-b:" -- arg1 --long-b val_b (expected "--long-a val_a -- arg1")' {
    declare -a args=("arg1" "--long-b" "val_b")
    run getoptses --longoptions "long-a:,long-b:" -- "${args[@]}"

    [[ "$output" == "--long-b 'val_b' -- 'arg1'" ]]
}





