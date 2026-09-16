# ==========================================
# Environment
# ==========================================

export ZSH="$HOME/.oh-my-zsh"
export OPENSSL_CONF=/dev/null

# PATH
export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$HOME/.spicetify:$PATH"

# ==========================================
# Powerlevel10k Instant Prompt
# (Harmless if the cache exists. Can be removed if you delete p10k.)
# ==========================================

if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# ==========================================
# Oh My Zsh
# ==========================================

ZSH_THEME=""

plugins=(
  git
  zsh-autosuggestions
  zsh-syntax-highlighting
)

source "$ZSH/oh-my-zsh.sh"

# ==========================================
# Starship Prompt
# ==========================================

eval "$(starship init zsh)"

# ==========================================
# Aliases
# ==========================================

alias ff='fastfetch'
alias wa='gtk-launch chrome-hnpfjngllnobngcgfapefoaidbinmjnm-Default'
alias ca='source "$HOME/anaconda3/bin/activate" && conda activate base'

# ==========================================
# Startup
# ==========================================

fastfetch

# Antigravity battery optimization
alias antigravity="antigravity --disable-features=WebRtcHWDecoding,WebRtcHWEncoding --disable-gpu-memory-buffer-video-frames"

# MySQL service
alias mysql-start='sudo systemctl start mysqld'
alias mysql-stop='sudo systemctl stop mysqld'
alias mysql-restart='sudo systemctl restart mysqld'
alias mysql-status='systemctl status mysqld'

# Connect to MySQL
alias mysql-root='mysql -u root -p'
