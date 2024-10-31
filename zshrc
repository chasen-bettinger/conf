# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH

# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time oh-my-zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="robbyrussell"

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in ~/.oh-my-zsh/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment the following line to disable bi-weekly auto-update checks.
# DISABLE_AUTO_UPDATE="true"

# Uncomment the following line to automatically update without prompting.
# DISABLE_UPDATE_PROMPT="true"

# Uncomment the following line to change how often to auto-update (in days).
# export UPDATE_ZSH_DAYS=13

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS=true

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in ~/.oh-my-zsh/plugins/*
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(git)

source $ZSH/oh-my-zsh.sh

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='mvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"

alias gs='git status'
alias gpms='git pull origin main-stage'
alias gca='git commit -am'
alias gc='git commit'
alias gph='git push'
alias gphnb='git push -u origin'
alias gpl='git pull'
alias gco='git checkout'
alias climy='winpty mysql.exe -u root -ppassword'
alias gdee='git diff \*ee'
alias gnb='git checkout -b'
alias ga='git add'
alias gcl='git clean -f'
alias gitcheck='git remote show origin'
alias gcon='cat .git/config'
alias unstage='git reset --soft HEAD~1'
alias gcpc='git cherry-pick --continue'
alias cc='coffee -c'
alias cwme='cc -w .'
alias deps='npm run refresh-deps'

# RESET DATABASES
alias resetmy='sudo docker container exec -i dev_db_1 mysql -u root -ppassword tib_dev_9101 < dump.sql'
alias resetmycq='sudo docker container exec -i api_db_1 psql -U postgres cquentia < ./dump.psql'
alias resetpg='sudo docker container exec -it api_db_1 psql -U postgres -d visionaire -f load.sql'
alias resetconnect='sudo docker container exec -it api_db_1 psql -U postgres -d dco_dev_9503 -f .reset_psql'
alias connect_pg='psql --no-password --user $XXX_PSQL_USER --host $XXX_PSQL_HOST --port $XXX_PSQL_PORT --echo-all < .reset_psql'

# DOCKER
alias dconls='docker container ls'
alias dcompd='docker-compose down'
alias dcompu='docker-compose up'
alias dim="docker image ls"
alias dimrm='docker rmi -f $(docker images | grep "<none>" | awk "{print \$3}")'

function killport() {
    if [ "$1" != "" ]
    then
        lsof -t -i tcp:$1 | xargs kill
    else
        lsof -t -i tcp:9101 | xargs kill
    fi
}

function loopd() {
    for d in */ ; do
        echo "$d"
    done
}

function loopf() {
    for f in *.* ; do
        echo "$f"
    done
}

function unix_time() {
    if [ "$1" != "" ]
    then
        let "short_date=$1/1000"
        integer date_as_integer=${short_date%%.*}
        date -r $date_as_integer
    fi
}


# tabtab source for packages
# uninstall by removing these lines
[[ -f ~/.config/tabtab/__tabtab.zsh ]] && . ~/.config/tabtab/__tabtab.zsh || true
