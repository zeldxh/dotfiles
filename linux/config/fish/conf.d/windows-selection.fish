# Windows-style command-line selection: Ctrl+A selects all, Shift+arrows/Home/End select,
# typing replaces the selection, Backspace/Delete remove it, Ctrl+Shift+C (Alacritty sends Alt+Shift+C) copies it.
status is-interactive; or return

set -g fish_color_selection --background=383838

function __sel_active
    test -n "$(commandline --selection-start)"
end

function __sel_extend
    __sel_active; or commandline -f begin-selection
    commandline -f $argv
end

function __sel_move
    __sel_active; and commandline -f end-selection
    commandline -f $argv
end

function __sel_delete
    if __sel_active
        commandline -f kill-selection end-selection
    else
        commandline -f $argv
    end
end

function __sel_all
    commandline -f end-selection beginning-of-buffer begin-selection end-of-buffer
end

function __sel_copy
    __sel_active; and commandline --current-selection | fish_clipboard_copy
end

for mode in default insert
    bind -M $mode \e\[1\;2D '__sel_extend backward-char'
    bind -M $mode \e\[1\;2C '__sel_extend forward-char'
    bind -M $mode \e\[1\;2H '__sel_extend beginning-of-line'
    bind -M $mode \e\[1\;2F '__sel_extend end-of-line'
    bind -M $mode \e\[1\;6D '__sel_extend backward-word'
    bind -M $mode \e\[1\;6C '__sel_extend forward-word'
    bind -M $mode \ca __sel_all
    bind -M $mode \e\[D '__sel_move backward-char'
    bind -M $mode \e\[C '__sel_move forward-char'
    bind -M $mode \e\[H '__sel_move beginning-of-line'
    bind -M $mode \e\[F '__sel_move end-of-line'
    bind -M $mode \x7f '__sel_delete backward-delete-char'
    bind -M $mode \e\[3~ '__sel_delete delete-char'
    bind -M $mode \eC __sel_copy

    # Typing over a selection replaces it (kill-selection is a no-op when nothing is selected)
    for i in (seq 32 126)
        set -l c (printf "%b" (printf "\\\\x%02x" $i))
        bind -M $mode -- $c kill-selection end-selection self-insert
    end
    for c in á é í ó ú ñ ü Á É Í Ó Ú Ñ ¿ ¡
        bind -M $mode -- $c kill-selection end-selection self-insert
    end
end
