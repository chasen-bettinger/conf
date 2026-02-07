# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
export SHELL=/bin/zsh

# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"

plugins=(git zsh-autosuggestions zsh-syntax-highlighting web-search)

source $ZSH/oh-my-zsh.sh
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# ALIASES
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
alias less='less -N'
alias rot13="tr 'A-Za-z' 'N-ZA-Mn-za-m'"
alias sa='source ~/.zshrc'
alias sb='vi ~/.zshrc'

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

# Exports
export EDITOR=vim
export PYENV_ROOT="$HOME/.pyenv"

# functions

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

eval "$(atuin init zsh)"

[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local
