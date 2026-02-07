export SHELL=/bin/zsh

export ZSH="$HOME/.oh-my-zsh"
starship preset gruvbox-rainbow -o ~/.config/starship.toml

plugins=(git zsh-autosuggestions zsh-syntax-highlighting web-search)

source $ZSH/oh-my-zsh.sh

# ALIASES
alias gs='git status'
alias gpms='git pull origin main-stage'
alias gca='git commit -am'
alias gcap='git add -A && git commit -s && gph'
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
alias tf='terraform'
alias gsq='git reset --soft origin/HEAD'
alias gsq2='git reset --soft $(git merge-base master HEAD)'
alias grc='git rebase --continue'
alias gsp='git stash pop'
alias gst='git stash'
alias grbo='git checkout --ours . && ga . && git rebase --continue'
alias grbt='git checkout --theirs . && ga . && git rebase --continue'
alias k='kubectl'
alias app='kubectl -n app'
alias cfc='kubectl -n "cloudflare-controller"'
alias aw='kubectl -n argo-workflows'
alias kctx='kubectl config use-context'
alias aws-who='aws iam list-account-aliases --output json |  jq ".AccountAliases"'
alias rmk8saws='rm ~/.kube/config ~/.aws/credentials'
alias gitleaks_scan='gitleaks git --log-opts="--all" -f "json" -r "./gitleaks.json"'

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

function get-services() {
  local services=($(kubectl -n app get services -o name))
  local result=()
  for service in $services; do
    local service_name=$(echo $service | sed 's/service\///')
    service_name=$(echo $service_name | sed 's/svc-//')
    result+=($service_name)
  done
  echo "${result[@]}"
}

function print-services() {
  local services=($(get-services))
  for service in $services; do
    echo $service
  done
}

function find-string() {
 grep -ri $1 .
}

alias fstr='find-string'

eval "$(atuin init zsh)"
eval "$(starship init zsh)"

[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local
