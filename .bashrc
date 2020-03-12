alias r='rm -Rf'
alias gad='git add -A'
alias gac='git add -A && git commit -m '
alias gush='git push origin '
alias proj='cd ~/projects'
alias desk='cd ~/Desktop'
alias redisStart='redis-server /usr/local/etc/redis.conf'
alias la='ls -a'

alias runparprox='desk && cd parProxy && node server.js'
alias tomap="proj && cd SCMaps"
alias installMapFR='tomap && cd SCMaps.Frontend && npm install'
alias runmap='tomap && (trap "kill -" SIGINT; npm run start --prefix SCMaps.FrontEnd & dotnet run --project SCMaps.Api/)'
alias runmapi='installMapFR && runmap'

alias gacp='gitAddCommitAndPush'
alias lastb='lastGitBranches'
alias start='openChromeWithUrls && runMapsStuff'
myInitials='ak'
alias stage='stageBranch'

function openChromeWithUrls(){
    `open -a /Applications/Google\ Chrome.app https://mail.google.com/mail/u/0/ https://calendar.google.com/calendar/r http://localhost:3000/ https://localhost:5001/index.html https://dev1.servicechannel.com/sc/wo/Workorders/list` 

}
function runMapsStuff(){

    osascript -e '
tell application "iTerm"
    tell current window
        tell current session
            split vertically with default profile
            write text "cd ~/projects/SCMaps"
            write text "cd SCMaps.Api/"
            write text "dotnet run"
        end tell
        tell last session of last tab
            write text "cd ~/projects/SCMaps"
            write text "cd SCMaps.FrontEnd/"
            write text "npm run start"
            split horizontally with default profile
        end tell
    end tell
end tell
'
}

function lastGitBranches(){
    numBranches=$1
    toSwitchTo=$2
    branches=(`git reflog | egrep -io "moving from ([^[:space:]]+)" | awk '{ print $3 }' | awk ' !x[$0]++' | egrep -v '^[a-f0-9]{40}$' | head -n${numBranches} | tail -r`)
    total=${#branches[*]}
    if [ -z "$toSwitchTo" ]
    then
        for (( i=0; i<$(( $total )); i++ ))
        do 
            pos=$(( $total - $i ))
            branch="${branches[$i]}"
            echo "$pos - $branch"
        done
    else
        pos=$(( $total - $toSwitchTo ))
        branch=${branches[$pos]}
        echo "switching to $branch"
        git checkout $branch
    fi
}
function stageBranch(){
    mergeTo=$1
    currentBranch=$(git branch | grep \* | cut -d ' ' -f2 )
    stageBranchName="${currentBranch}.${mergeTo}"
    echo "will perform:"
    echo "git checkout ${mergeTo}"
    echo "git checkout -b ${stageBranchName}"
    echo "git merge ${currentBranch} -m 'staging merge'"
    echo "-----"
    git checkout ${mergeTo}
    git checkout -b ${stageBranchName}
    git pull
    git merge ${currentBranch} -m 'staging merge'
}

alias chout='newNamedBranch'
function newNamedBranch(){
    branchName=$1
    echo git checkout -b "${myInitials}.${branchName}"
    git checkout -b "${myInitials}.${branchName}"
}
function gitAddCommitAndPush(){
    commitMessage=$1
    #get branch name
    branch=$(git symbolic-ref --short -q HEAD)
    #to lower case
    branch=$(echo "$branch" | tr '[:upper:]' '[:lower:]')

    if [ $branch = 'master' ]
    then
        echo "too dangerous for master branch"
    else
        # check its my branch through branch name initials
        #split by .
        arrIN=(${branch//./ })
        # get and tolower() initials
        branchInitials=${arrIN[0]}
        branchInitials=$(echo "$branchInitials" | tr '[:upper:]' '[:lower:]')

        if [ $branchInitials != $myInitials ]
        then
            echo "to dangerous for other peoples branches"
        else
            git add -A 
            git commit -m "'$commitMessage'"
            git push origin HEAD
        fi
    fi

}
export -f gitAddCommitAndPush

alias branch='displayBranchesByIndexNumberOrSwitchBranchByIndex'
function displayBranchesByIndexNumberOrSwitchBranchByIndex(){
    branchIndexToSwitchToProvided=false;
    regexSearchProvided=false;
    searchRegex=""
    showRemote=false;
    branches="";
    firstArg="";
    numRe='^[0-9]+$';
    autoSwitchIfSingleResult=true
    OPTIND=1
    foundOptions=$((0))
    while getopts ":ras:" opt
    do
        case $opt in
            r)
                showRemote=true;
                foundOptions=$(($foundOptions+1))
                ;;            
            s)
                searchRegex=$OPTARG;
                showRemote=true;
                regexSearchProvided=true;
                foundOptions=$(($foundOptions+2))
                ;;
            a)
                autoSwitchIfSingleResult=false
                foundOptions=$(($foundOptions+1))
                ;;
            \?)
                echo "Invalid option: -$OPTARG" >&2
                return 1
                ;;
            :)
                echo "Invalid option: $OPTARG requires an argument" 1>&2
                return 1
                ;;
        esac
    done
    shift $foundOptions
    firstArg=$1;

    
    if [ -n $firstArg ] && [[ "$firstArg" =~ $numRe ]]
    then
        branchIndexToSwitchToProvided=true;
        shift
    fi



    if [ "$branchIndexToSwitchToProvided" == false ]
    then
        #update branch list if branch index number hasnt been provided
        echo 'git fetching';
        git fetch;
    fi

    #get all branch names
    if [ "$regexSearchProvided" == true ]
    then
        branches=$(git branch -a --list -i ${searchRegex} |sort --ignore-case|uniq);
    else
        if [ "$showRemote" == true ]
        then
            branches=$(git branch -a |sort --ignore-case|uniq);
        else
            branches=$(git branch | sort --ignore-case|uniq);
        fi
    fi


    # split by '\n'
    IFS=$'\n' read -rd '' -a branches <<<"$branches";

    #debug print
    # echo "firstArg ${firstArg} branchIndexToSwitchToProvided ${branchIndexToSwitchToProvided} branchLength ${#branches[@]} autoSwitchIfSingleResult ${autoSwitchIfSingleResult}   regexSearchProvided ${regexSearchProvided}"

    #if autoswitch and branch length === 0 remotes aside, then switch to that branch
    if [ "$autoSwitchIfSingleResult" == true ] && [ ${#branches[@]} -lt 3 ]
    then
        shouldSwitch=false;
        branchToSwitchTo="";
        if [ "${#branches[@]}" = "2" ]
        then
            #incase its remote branch split it by '/' and and take the last element
            callableBranchNamea=""
            IFS='/' read -ra callableBranchNamea <<< "${branches[0]}";
            length=${#callableBranchNamea[@]};                             
            lastPosition=$(($length - 1));
            callableBranchNamea=${callableBranchNamea[$lastPosition]};

            callableBranchNameb="";
            IFS='/' read -ra callableBranchNameb <<< "${branches[1]}";
            length=${#callableBranchNameb[@]};                                
            lastPosition=$(($length - 1));     
            currentBranch=false;
            callableBranchNameb=${callableBranchNameb[$lastPosition]};
            if [[ $callableBranchNameb =~ "*" ]] || [[ $callableBranchNamea =~ "*" ]]
            then
                currentBranch=true
            fi
            if [ "$currentBranch" = false ] && [ $callableBranchNameb == $callableBranchNamea ]
            then
                shouldSwitch=true;
                branchToSwitchTo=$callableBranchNamea;
            fi
        else
            if [ "${#branches[@]}" = "1" ]
            then
                shouldSwitch=true;
                #incase its remote branch split it by '/' and and take the last element
                IFS='/' read -ra branchToSwitchTo <<< "${branches[0]}";
                length=${#branchToSwitchTo[@]};                             
                lastPosition=$(($length - 1));
                branchToSwitchTo=${branchToSwitchTo[$lastPosition]};
            fi
        fi
        if [ "$shouldSwitch" = true ]
        then
            if [[ $callableBranchName =~ "*" ]]
            then
                echo "$callableBranchName is the current branch"
            else
                echo "checkout $branchToSwitchTo"
                git checkout $branchToSwitchTo
                return 1;
            fi
        fi
    fi


    #if branch-to-switch-to exists and is integer then switch to branch
    # else output branches and their index'
    if [ "$branchIndexToSwitchToProvided" == true ]
    then
        #incase its remote branch split it by '/' and and take the last element
        callableBranchName=""
        IFS='/' read -ra callableBranchName <<< "${branches[$firstArg]}"
        length=${#callableBranchName[@]}                                        
        lastPosition=$(($length - 1))            
        callableBranchName=${callableBranchName[$lastPosition]}

        if [[ $callableBranchName =~ "*" ]]
        then
            echo "$callableBranchName is the current branch"
        else
            echo "checkout $callableBranchName"
            git checkout $callableBranchName
        fi

    else
        count=0
        for var in "${branches[@]}"
        do
            echo "$count - ${var}"
            count=$(($count+1))
        done
    fi
}
export -f displayBranchesByIndexNumberOrSwitchBranchByIndex
