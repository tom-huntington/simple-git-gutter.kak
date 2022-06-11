#!/bin/sh

is_added()
{
    from_count=$1
    to_count=$2
    [ $from_count -eq 0 ] && [ $to_count -gt 0 ]
}

is_removed()
{
    from_count=$1
    to_count=$2
    [ $from_count -gt 0 ] && [ $to_count -eq 0 ]
}

is_modified()
{
    from_count=$1
    to_count=$2
    [ $from_count -gt 0 ] && [ $to_count -gt 0 ] && [ $from_count -eq $to_count ]
 }

is_modified_and_added()
{
    from_count=$1
    to_count=$2
    [ $from_count -gt 0 ] && [ $to_count -gt 0 ] && [ $from_count -lt $to_count ]
 }

is_modified_and_removed()
{
    from_count=$1
    to_count=$2
    [ $from_count -gt 0 ] && [ $to_count -gt 0 ] && [ $from_count -gt $to_count ]
}

process_added()
{
    modifications=""
    from_count=$1
    to_line=$2
    to_count=$3
    index=0
    # echo "process_added: from_count=${from_count} to_line=${to_line} to_count=${to_count}"

    while [ $index -lt $to_count ]; do
        line_number=$((to_line+index))
        modifications="${modifications} ${line_number}|+ "
        index=$((index+1))
    done
    echo "$modifications"
}

process_removed()
{
    to_line=$1
    index=0
    # echo "process_removed: to_line=${to_line}"
    # return 0

    [ $to_line -eq 0 ] \
        && return 0

    echo "${to_line}|-"
}

process_modified_and_added()
{
    modifications=""
    from_count=$1
    to_line=$2
    to_count=$3
    index=0
    # echo "process_modified_and_added: from_count=${from_count} to_line=${to_line} to_count=${to_count}"

    while [ $index -lt $from_count ]; do
        line_number=$((to_line+index))
        modifications="${modifications}${line_number}|~ "
        index=$((index+1))
    done
    while [ $index -lt $to_count ]; do
        line_number=$((to_line+index))
        modifications="${modifications}${line_number}|+ "
        index=$((index+1))
    done
    echo "$modifications"
}

process_modified_and_removed()
{
    modifications=""
    to_line=$1
    to_count=$2
    index=0
    # echo "process_modified_and_removed: to_line=${to_line} to_count=${to_count}"

    while [ $index -lt $to_count ]; do
        line_number=$((to_line+index))
        modifications="${modifications}${line_number}|~ "
        index=$((index+1))
    done
    echo "$modifications"
}

process_hunk()
{
    from_line=$1
    from_count=$2
    to_line=$3
    to_count=$4
    # echo "process_hunk from_line=${from_line} from_count=${from_count} to_count=${to_count} to_line=${to_line}"
    # echo "processed_hunk -------------"
    
    is_added $from_count $to_count \
        && process_added $from_count $to_line $to_count \
        && return 0
    # echo "not is_added"
    is_removed $from_count $to_count \
        && process_removed $to_line \
        && return 0
    # echo "not is_removed"
    is_modified_and_added $from_count $to_count \
        && process_modified_and_added $from_count $to_line $to_count \
        && return 0
    # echo "not is_modified_and_added"
    is_modified_and_removed $from_count $to_count \
        && process_modified_and_removed $from_count $to_count \
        && return 0
    # echo "not is_modified_and_removed"

}

parse_diff_line()
{
    # echo "${2} $(echo $3 | sed 's/,/ /g')"
    # echo "10 10 2"
    echo "$1" | sed -rn 's/^@@ -([0-9]+),?([0-9]*) \+([0-9]+),?([0-9]*) @@.*/\1 \2 \3 \4/p' | sed 's/  / 1 /'
}

gitout="$(git --no-pager diff --no-ext-diff --no-color -U0 | grep '^@@ ')"

modified_lines=""
# echo "$gitout"

echo "${gitout}" | {
    while IFS='' read -r LINE <&0 || [ -n "${LINE}" ]; do
        # echo "line: ${LINE}"
        diff_array="$(parse_diff_line "${LINE}")"
        echo "from_line from_count to_line to_count"
        echo "$diff_array"
        additional_modified_lines=$(process_hunk $diff_array)
        modified_lines="${modified_lines}${additional_modified_lines}"
    done
    echo "set-option buffer git_diff_line_specs ${modified_lines}"
}


