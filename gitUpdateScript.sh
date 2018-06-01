#!/usr/bin/env bash

GREEN='\033[0;32m'
RED='\033[0;31m'
LCYAN='\033[1;36m'
ORANGE='\033[0;33m'
RESET='\033[0m'

CWD=$(pwd)
 
CHECK_GIT_BRANCH_REGEXP='^On branch .*'

REPOS_UPDATED=0
REPOST_NOT_UPDATED=0

function validateGitBranch {
    local output=$(git status 2>&1 | head -n 1)
    if [[ "$output" =~ ${CHECK_GIT_BRANCH_REGEXP} ]]; then
        return 0
    else
        echo -e "Repo: ${ORANGE}$(pwd)${RESET} not on any branch, detached HEAD?"
        ((REPOS_NOT_UPDATED=$REPOS_NOT_UPDATED+1))
        return 1
    fi
}


printf "${LCYAN}Updating all git repos in current dir and subdirs..${RESET}\n"
find . -type d -name .git -prune | sed -e 's/.git//g' | ( while read line;
do
    cd $line
    if git diff-index --quiet HEAD; then
        if validateGitBranch; then
            echo -e "Updating repo: ${GREEN}$(pwd)${RESET}"
            git pull --rebase > /dev/null 2>&1
            if [ $? -ne 0 ]; then
                echo -e "${RED}Error${RESET} when running git pull --rebase on ${RED}$(pwd)${RESET}"
                git rebase --abort > /dev/null 2>&1
                continue
            fi
            ((REPOS_UPDATED=$REPOS_UPDATED+1))
        fi
    else
        echo -e "Local changes found in repo: ${ORANGE}$(pwd)${RESET}"
        ((REPOS_NOT_UPDATED=$REPOS_NOT_UPDATED+1))
    fi
    cd $CWD
done
echo "update: $REPOS_UPDATED"
echo -e "${LCYAN}--- Finished ---${RESET}. Repos updated: ${GREEN}$REPOS_UPDATED${RESET}, Not updated: ${RED}${REPOS_NOT_UPDATED}${RESET}"
)
