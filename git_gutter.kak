declare-option line-specs git_diff_line_specs
declare-option str gitgutter_buffer

declare-option -hidden -docstring \
"Path to git_gutter.sh script." \
str git_gutter_sh_source %sh{ echo "${kak_source%%.kak}.sh" }

hook global ModeChange pop:insert:.* gitdiff

# # echo %sh{ "${kak_source%%.kak}.sh" }
# hook global ModeChange pop:insert:.* %{ echo \ # %{
#     # set-option buffer temp_filename %sh{ mktemp -t git_gutter.XXXXXX }
#     # write! %opt{temp_filename}
#     # evaluate-commands %sh{ . "${kak_opt_git_gutter_sh_source}" } }
#     %sh{ . "${kak_opt_git_gutter_sh_source}" } 
# }

define-command gitdiff %{
    set-option buffer gitgutter_buffer %sh{ mktemp -t gitgutter.buffer.XXXXXX }
    write! -force %opt{gitgutter_buffer}
    evaluate-commands %sh{
    . "$kak_opt_git_gutter_sh_source"
    git_diff "${kak_opt_gitgutter_buffer}" "${kak_buffile}"
    }
}

add-highlighter global/ flag-lines LineNumbers git_diff_line_specs

