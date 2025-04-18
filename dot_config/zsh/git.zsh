# ---- Git ouput enhancements ----
# Git custom log and branch formats

LOG_HASH="%C(always,yellow)%h%C(always,reset)"
LOG_RELATIVE_TIME="%C(always,green)(%ar)%C(always,reset)"
LOG_AUTHOR="%C(always,blue)<%an>%C(always,reset)"
LOG_REFS="%C(always,red)%d%C(always,reset)"
LOG_SUBJECT="%s"

LOG_FORMAT="$LOG_HASH}$LOG_AUTHOR}$LOG_RELATIVE_TIME}$LOG_SUBJECT $LOG_REFS"

BRANCH_PREFIX="%(HEAD)"
BRANCH_REF="%(color:red)%(color:bold)%(refname:short)%(color:reset)"
BRANCH_HASH="%(color:yellow)%(objectname:short)%(color:reset)"
BRANCH_DATE="%(color:green)(%(committerdate:relative))%(color:reset)"
BRANCH_AUTHOR="%(color:blue)%(color:bold)<%(authorname)>%(color:reset)"
BRANCH_CONTENTS="%(contents:subject)"

BRANCH_FORMAT="}$BRANCH_PREFIX}$BRANCH_REF}$BRANCH_HASH}$BRANCH_DATE}$BRANCH_AUTHOR}$BRANCH_CONTENTS"

show_git_head() {
    pretty_git_log -1
    git show -p --pretty="tformat:"
}

pretty_git_log() {
    git log --since="12 months ago" --graph --pretty="tformat:${LOG_FORMAT}" $* | pretty_git_format | git_page_maybe
}

pretty_git_log_all() {
    git log --all --since="12 months ago" --graph --pretty="tformat:${LOG_FORMAT}" $* | pretty_git_format | git_page_maybe
}

pretty_git_branch() {
    git branch -v --color=always --format=${BRANCH_FORMAT} $* | pretty_git_format
}

pretty_git_branch_sorted() {
    git branch -v --color=always --format=${BRANCH_FORMAT} --sort=-committerdate $* | pretty_git_format
}

pretty_git_format() {
    sed -Ee 's/(^[^)]*) ago\)/\1)/' |
    sed -Ee 's/(^[^)]*), [[:digit:]]+ .*months?\)/\1)/' |
    sed -Ee 's/ seconds?\)/s\)/' |
    sed -Ee 's/ minutes?\)/m\)/' |
    sed -Ee 's/ hours?\)/h\)/' |
    sed -Ee 's/ days?\)/d\)/' |
    sed -Ee 's/ weeks?\)/w\)/' |
    sed -Ee 's/ months?\)/M\)/' |
    sed -Ee 's/<Jeff Tooke>/<me>/' |
    sed -Ee 's/<([^ >]+) [^>]*>/<\1>/' |
    column -s '}' -t
}

git_page_maybe() {
    if [ -n "${GIT_NO_PAGER}" ]; then
        cat
    else
        less --quit-if-one-screen --no-init --RAW-CONTROL-CHARS --chop-long-lines
    fi
}