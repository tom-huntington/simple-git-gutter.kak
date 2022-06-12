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
        modifications="${modifications}${line_number}|{variable}┃ "
        index=$((index+1))
    done
    echo "$modifications"
}

process_removed()
{
    # from_line=$1
    to_line=$1
    index=0
    # echo "process_removed: to_line=${to_line}"
    # return 0

    [ $to_line -eq 0 ] \
        && return 0

    echo "$((${to_line}+1))|{value}┃ "
}

process_modified()
{
    modifications=""
    to_line=$1
    to_count=$2
    index=0
    # echo "process_added: from_count=${from_count} to_line=${to_line} to_count=${to_count}"

    while [ $index -lt $to_count ]; do
        line_number=$((to_line+index))
        modifications="${modifications}${line_number}|{function}┃ "
        index=$((index+1))
    done
    echo "$modifications"
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
        modifications="${modifications}${line_number}|{function}┃ "
        index=$((index+1))
    done
    while [ $index -lt $to_count ]; do
        line_number=$((to_line+index))
        modifications="${modifications}${line_number}|{variable}┃ "
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
        modifications="${modifications}${line_number}|{function}┃ "
        index=$((index+1))
    done
    echo "${modifications}$((to_line+index))|{value}┃ "
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
    # echo "passed is_added"
    is_removed $from_count $to_count \
        && process_removed $to_line \
        && return 0
    # echo "passed is_removed"
    is_modified $from_count $to_count \
        && process_modified $to_line $to_count \
        && return 0
    is_modified_and_added $from_count $to_count \
        && process_modified_and_added $from_count $to_line $to_count \
        && return 0
    # echo "passed is_modified_and_added"
    is_modified_and_removed $from_count $to_count \
        && process_modified_and_removed $to_line $to_count \
        && return 0
    # echo "not is_modified_and_removed"

}

parse_diff_line()
{
    # echo "${2} $(echo $3 | sed 's/,/ /g')"
    # echo "10 10 2"
    echo "$1" | sed -rn 's/^@@ -([0-9]+),?([0-9]*) \+([0-9]+),?([0-9]*) @@.*/\1 \2 \3 \4 /p' | sed 's/  / 1 /g'
}

diff_temp_files()
{
    gitout="$(git --no-pager diff --no-ext-diff --no-color -U0 ${temp_head} ${temp_buffer} | grep '^@@ ')"
    # modified_lines=""
    # echo "$gitout"
    # echo "echo temp_head=${temp_head} end filename=${temp_buffer} end" # set-option buffer git_diff_line_specs %val{timestamp} ${modified_lines}"
    cat "$gitout" > gitdiffout.txt
    

    echo "${gitout}" | {
        while IFS='' read -r LINE <&0 || [ -n "${LINE}" ]; do
            # echo "line: ${LINE}
            diff_array="$(parse_diff_line "${LINE}")"
            # echo "from_line from_count to_line to_count"
            # echo "$diff_array"
            additional_modified_lines=$(process_hunk $diff_array)
            modified_lines="${modified_lines}${additional_modified_lines}"
        done
        # echo "$gitout"
        echo "set-option buffer git_diff_line_specs %val{timestamp} ${modified_lines}"
        # echo "isas echo buffile=${kak_buffile} end filename=${kak_opt_gitgutter_temp_buffer} end" # set-option buffer git_diff_line_specs %val{timestamp} ${modified_lines}"
    }
}

git_diff()
{
    temp_buffer="$1"
    buffile="$2"
    temp_head=$(mktemp -t gitgutter.head.XXXXXX)
    repo_relative_file="HEAD:$(git ls-files --full-name $buffile)"
    git --no-pager show $repo_relative_file > "$temp_head" \
        && diff_temp_files

    cat "$temp_head" > gitshow.txt
    cat "$temp_buffer" > buffer.txt

    rm -f "$temp_head" "$temp_buffer"
}

