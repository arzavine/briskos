# ==============================================================================
# BriskOS Bash Configuration
# Morning Breeze Dark Slate Terminal & Clean 1-Line Shell Prompt
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
# Clean 1-Line Prompt Engine (universal glyphs, zero missing-font icons)
# Format: user@host ~/path (branch ✓) ›
# ------------------------------------------------------------------------------
_brisk_prompt_command() {
    local exit_code=$?

    local git_segment=""
    if command -v git >/dev/null 2>&1; then
        local branch
        branch=$(git symbolic-ref --short HEAD 2>/dev/null || git rev-parse --short HEAD 2>/dev/null || true)
        if [[ -n "$branch" ]]; then
            local status_sym status_col
            if [[ -z "$(git status --porcelain --ignore-submodules=dirty 2>/dev/null | head -n 1)" ]]; then
                status_sym="✓"
                status_col="\[\033[38;2;74;222;128;1m\]"   # Emerald #4ade80
            else
                status_sym="*"
                status_col="\[\033[38;2;251;191;36;1m\]"   # Amber #fbbf24
            fi
            git_segment=" \[\033[38;2;148;163;184m\](\[\033[38;2;241;245;249m\]${branch} ${status_col}${status_sym}\[\033[38;2;148;163;184m\])\[\033[0m\]"
        fi
    fi

    local c_host="\[\033[38;2;148;163;184m\]"        # Slate #94a3b8
    local c_path="\[\033[38;2;56;189;248;1m\]"       # Cerulean Sky #38bdf8
    local c_chev="\[\033[38;2;56;189;248;1m\]"       # Cerulean Sky #38bdf8
    if (( exit_code != 0 )); then
        c_chev="\[\033[38;2;248;113;113;1m\]"        # Coral Red #f87171 on error
    fi
    local c_reset="\[\033[0m\]"

    PS1="${c_host}\u@\h${c_reset} ${c_path}\w${c_reset}${git_segment} ${c_chev}›${c_reset} "
}

PROMPT_COMMAND="_brisk_prompt_command"

# ------------------------------------------------------------------------------
# Aliases & Utilities
# ------------------------------------------------------------------------------
# 'clear' and 'cls': clears screen and prints compact Brisk Cockpit summary
_brisk_clear() {
    if [[ -x /usr/bin/clear ]]; then
        /usr/bin/clear
    else
        printf "\033[3J\033[2J\033[H"
    fi
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
