# Formatted, colorful JSON in terminals
function pjsn () {
    curl $@ | python -mjson.tool | pygmentize -g
}

function pyclean {
    find . | grep -E "(__pycache__|\.pyc$|\.egg-info$)"  | xargs rm -rf
}
