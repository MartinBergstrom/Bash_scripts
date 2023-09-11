#!/usr/bin/env bash

GREEN='\033[0;32m'
LIGHT_GREEN='\033[0;92m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
LIGHT_RED='\033[0;91m'
LCYAN='\033[0;36m'
BLCYAN='\033[1;36m'
RESET='\033[0m'

BOLD='\033[1m'

CWD=$(pwd)

CHECK_GIT_BRANCH_REGEXP='^On branch (.*)$'
CHECK_GIT_BRANCH_REGEXP_ONLY_MASTER_MAIN='^On branch (master|main)$'
GIT_PULL_REBASE_ALREADY_UP_TO_DATE_REGEXP='up to date\.$'
GIT_PULL_REBASE_UPDATED_REGEXP='^Updating.*'

REPOS_UPDATED=0
REPOS_NOT_UPDATED=0
REPOS_ALREADY_UP_TO_DATE=0

ONLY_UPDATE_IF_MASTER_MAIN=true

if [[ $* == *-a* ]]; then
    ONLY_UPDATE_IF_MASTER_MAIN=false
fi


function validate_git_branch {
    local output=$(git status 2>&1 | head -n 1)
    if [[ ! "$output" =~ ${CHECK_GIT_BRANCH_REGEXP} ]]; then
        echo -e "Repo: ${RED}$(pwd)${RESET} not on any branch, ${YELLOW}detached HEAD?${RESET}"
        ((REPOS_NOT_UPDATED++))
        return 1
    fi
    branch_name="${BASH_REMATCH[1]}"
    if [[ "$ONLY_UPDATE_IF_MASTER_MAIN" == "true" && ! "$output" =~ ${CHECK_GIT_BRANCH_REGEXP_ONLY_MASTER_MAIN} ]]; then
        echo -e "Repo: ${RED}$(pwd)${RESET} on branch ${YELLOW}${branch_name}${RESET}, will not update"
        ((REPOS_NOT_UPDATED++))
        return 1
    fi
    return 0
}

function git_pull_rebase {
    local output=$(git pull --rebase 2>&1 | head -n 1)
    if [[ "$output" =~ ${GIT_PULL_REBASE_ALREADY_UP_TO_DATE_REGEXP} ]]; then
        echo -e "Repo: ${GREEN}$(pwd)${RESET} already up to date"
        ((REPOS_ALREADY_UP_TO_DATE=$REPOS_ALREADY_UP_TO_DATE+1))
    elif [[ "$output" =~ ${GIT_PULL_REBASE_UPDATED_REGEXP} ]]; then
        echo -e "Updated repo: ${LIGHT_GREEN}$(pwd)${RESET}"
        ((REPOS_UPDATED=$REPOS_UPDATED+1))
    else
        echo -e "${RED}Error${RESET} when running git pull --rebase on ${LIGHT_RED}$(pwd)${RESET}"
        git rebase --abort > /dev/null 2>&1
    fi
}


printf "${LCYAN}Updating all git repos in current dir and subddirs${RESET}"
if [[ "$ONLY_UPDATE_IF_MASTER_MAIN" == "true" ]]; then
    printf ", if on ${BOLD}master/main${RESET} branch.\n"
    printf "Use ${BOLD}-a${RESET} flag to update on any branch.\n\n"
else
    printf ", on ${BOLD}any${RESET} branch...${RESET}\n\n"
fi

find . -type d -name .git -prune | sed -e 's/.git//g' | ( while read line;
do
    cd $CWD/$line
    if git diff-index --quiet HEAD; then
        if validate_git_branch; then
            git_pull_rebase
        fi
    else
        echo -e "Local changes found in repo: ${RED}$(pwd)${RESET}"
        ((REPOS_NOT_UPDATED=$REPOS_NOT_UPDATED+1))
    fi
done
echo -e "\n${BLCYAN}--- Finished ---${RESET} Repos updated: ${LIGHT_GREEN}$REPOS_UPDATED${RESET}, "\
"Not updated: ${RED}${REPOS_NOT_UPDATED}${RESET}, Already up to date: ${GREEN}$REPOS_ALREADY_UP_TO_DATE${RESET}"
)
