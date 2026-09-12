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
alias gc='git commit -s'
alias gph='git push'
alias gphnb='git push -u origin'
alias gpl='git pull'
alias gco='git checkout'
alias ma='gco main && gpl'
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
alias gwl='git worktree list'
alias gwp='git worktree prune'
alias k='kubectl'
alias app='kubectl -n app'
alias cfc='kubectl -n "cloudflare-controller"'
alias aw='kubectl -n argo-workflows'
alias kctx='kubectl config use-context'
alias aws-who='aws iam list-account-aliases --output json |  jq ".AccountAliases"'
alias rmk8saws='rm ~/.kube/config ~/.aws/credentials'
alias gitleaks_scan='gitleaks detect --log-opts="--all" -f "json" -r "./gitleaks.json"'
alias os='openspec'
alias grep='rg'
alias os='openspec'
alias tidyjson="pbpaste | jq '.' | pbcopy"

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

function git-revert-push() {
  local target="${1:-HEAD}"

  local branch
  branch=$(git symbolic-ref --short HEAD 2>&1) || { echo "not on a branch: $branch" >&2; return 1; }
  if [ "$branch" = "main" ] || [ "$branch" = "master" ]; then
    echo "refusing to revert directly on $branch; make a branch first" >&2
    return 1
  fi

  if [ -n "$(git status --porcelain)" ]; then
    echo "working tree is dirty; commit or stash first" >&2
    return 1
  fi

  local sha
  sha=$(git rev-parse --short --verify "${target}^{commit}" 2>&1) || { echo "not a commit: $target" >&2; return 1; }

  echo "revert on $branch: $sha $(git log -1 --format=%s "$sha")"
  printf 'push the revert to origin/%s? [y/N] ' "$branch"
  local reply
  read -r reply
  case "$reply" in
    y|Y) ;;
    *) echo "stopped; nothing changed"; return 1 ;;
  esac

  # abort on conflict so the tree is left exactly as it was found
  if ! git revert --no-edit "$sha"; then
    git revert --abort 2>/dev/null
    echo "revert conflicts with later work; nothing changed. resolve by hand:" >&2
    echo "  git revert $sha" >&2
    return 1
  fi
  git push origin "$branch"
}

function find-string() {
 rg -ri $1 .
}

alias fstr='find-string'

eval "$(atuin init zsh)"
eval "$(starship init zsh)"

atuin sync || true

echo "Sourcing local zshrc..."
[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local
echo "Sourcing local zshrc complete..."

# ponytail: once-a-day claude update, guarded by a date-stamped file
_clc_stamp="$HOME/.cache/claude-update-check"
if [[ "$(cat "$_clc_stamp" 2>/dev/null)" != "$(date +%Y-%m-%d)" ]]; then
  echo "Updating claude code to latest..."
  claude update || true
  mkdir -p "$(dirname "$_clc_stamp")" && date +%Y-%m-%d > "$_clc_stamp"
fi

# bun completions
[ -s "/Users/chasen/.bun/_bun" ] && source "/Users/chasen/.bun/_bun"
