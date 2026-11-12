# ==============================================================================
# BriskOS Bash Configuration
# Night Glass Design System & Aeroline Smart Shell Prompt
# ==============================================================================

# If not running interactively, do not do anything
[[ $- != *i* ]] && return

# Ensure complete PATH
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:${PATH}"

# Enable 24-bit TrueColor
export COLORTERM=truecolor

# History settings
HISTCONTROL=ignoreboth
HISTSIZE=5000
HISTFILESIZE=10000
shopt -s histappend
shopt -s checkwinsize

# Automatically execute Brisk Cockpit on interactive terminal startup
if [[ $- == *i* && -x /usr/local/bin/brisk-cockpit ]]; then
    /usr/local/bin/brisk-cockpit
fi

# ------------------------------------------------------------------------------
# Aeroline 2-Line Smart Prompt Engine
# ------------------------------------------------------------------------------
_aeroline_now_ms() {
    if [[ -n "${EPOCHREALTIME:-}" ]]; then
        local sec="${EPOCHREALTIME%%.*}"
        local micro="${EPOCHREALTIME#*.}"
        local ms="${micro:0:3}"
        echo "$(( sec * 1000 + 10#$ms ))"
    else
        echo "$(( $(date +%s) * 1000 ))"
    fi
}

_aeroline_preexec() {
    # Guard against multiple triggerings within sub-commands
    [[ -n "${_AEROLINE_RUNNING:-}" ]] && return
    _AEROLINE_RUNNING=1
    _AEROLINE_START_TIME=$(_aeroline_now_ms)
}

# Trap DEBUG signal to capture command start time
trap '_aeroline_preexec' DEBUG

_aeroline_prompt_command() {
    local exit_code=$?

    # Command Execution Duration calculation
    local duration="0ms"
    if [[ -n "${_AEROLINE_START_TIME:-}" && -n "${_AEROLINE_RUNNING:-}" ]]; then
        local end_time
        end_time=$(_aeroline_now_ms)
        local elapsed=$(( end_time - _AEROLINE_START_TIME ))
        if (( elapsed < 0 )); then elapsed=0; fi

        if (( elapsed < 1000 )); then
            duration="${elapsed}ms"
        elif (( elapsed < 60000 )); then
            local sec=$(( elapsed / 1000 ))
            local rem_ms=$(( (elapsed % 1000) / 100 ))
            duration="${sec}.${rem_ms}s"
        else
            local min=$(( elapsed / 60000 ))
            local sec=$(( (elapsed % 60000) / 1000 ))
            duration="${min}m ${sec}s"
        fi
    fi
    _AEROLINE_RUNNING=""
    _AEROLINE_START_TIME=""

    # Dynamic Git branch and status detection
    local git_segment=""
    if command -v git >/dev/null 2>&1; then
        local branch
        branch=$(git symbolic-ref --short HEAD 2>/dev/null || git rev-parse --short HEAD 2>/dev/null)
        if [[ -n "$branch" ]]; then
            local status_sym status_col
            if git diff --quiet --ignore-submodules HEAD 2>/dev/null && \
               [[ -z "$(git ls-files --others --exclude-standard 2>/dev/null | head -n 1)" ]]; then
                status_sym="✓"
                status_col="\[\033[38;2;74;222;128;1m\]" # Emerald Green
            else
                status_sym="✗"
                status_col="\[\033[38;2;251;191;36;1m\]" # Amber / Warning
            fi
            git_segment=" \[\033[38;2;71;85;105m\]── \[\033[38;2;71;85;105m\](\[\033[38;2;148;163;184m\]git: \[\033[38;2;241;245;249;1m\]${branch} ${status_col}${status_sym}\[\033[38;2;71;85;105m\])\[\033[0m\]"
        fi
    fi

    # Palette colors (Night Glass TrueColor ANSI)
    local c_border="\[\033[38;2;71;85;105m\]"      # Slate-600
    local c_bracket="\[\033[38;2;100;116;139m\]"   # Slate-500
    local c_path="\[\033[38;2;56;189;248;1m\]"     # Ice Cyan bold
    local c_conn="\[\033[38;2;71;85;105m\]"        # Slate-600
    local c_time_ico="\[\033[38;2;203;213;225m\]"  # Slate-300
    local c_time_val="\[\033[38;2;148;163;184m\]"  # Slate-400
    local c_cyan="\[\033[38;2;56;189;248;1m\]"      # Ice Cyan
    local c_reset="\[\033[0m\]"

    # Line 1: ┌─ [~/path] ── (git: branch status) ── [⏱ duration]
    # Line 2: └─❯ (with Ice Cyan prompt symbol)
    PS1="${c_border}┌─ ${c_bracket}[${c_path}\w${c_bracket}]${c_reset}${git_segment} ${c_conn}── ${c_bracket}[${c_time_ico}⏱ ${c_time_val}${duration}${c_bracket}]${c_reset}\n${c_border}└─${c_cyan}❯${c_reset} "
}

PROMPT_COMMAND="_aeroline_prompt_command"

# ------------------------------------------------------------------------------
# Aliases & Utilities
# ------------------------------------------------------------------------------
# 'clear' and 'cls': clears screen and cleanly reprints compact /usr/local/bin/brisk-cockpit --compact
_brisk_clear() {
    command -v /usr/bin/clear >/dev/null 2>&1 && /usr/bin/clear || printf "\033[2J\033[H"
    if [[ -x /usr/local/bin/brisk-cockpit ]]; then
        /usr/local/bin/brisk-cockpit --compact
    fi
}
alias clear='_brisk_clear'
alias cls='_brisk_clear'

# Common helpful shortcuts
alias ls='ls --color=auto'
alias ll='ls -la --color=auto'
alias la='ls -A --color=auto'
alias l='ls -CF --color=auto'
alias grep='grep --color=auto'
alias diff='diff --color=auto'
