declare-option line-specs git_diff_line_specs

declare-option -hidden -docstring \
"Path to git_gutter.sh script." \
str git_gutter_sh_source %sh{ echo "${kak_source%%.kak}.sh" }


# echo %sh{ "${kak_source%%.kak}.sh" }
hook buffer ModeChange pop:insert:.* %{ evaluate-commands %sh{ . "${kak_opt_git_gutter_sh_source}" } }

add-highlighter window/ flag-lines LineNumbers git_diff_line_specs

