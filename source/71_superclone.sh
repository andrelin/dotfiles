#!/bin/bash
# set -e

# check_binary() {
#   if ! which "$1" > /dev/null; then
#     ( >&2 echo "$2" )
#     exit 1
#   fi
# }

# check_binary "jq" "$(cat <<EOF
# jq er ikke installert. avslutter...
# EOF
# )"

superclone(){
  if [ $# -eq 0 ] || [ "$1" == "-?" ] || [ "$1" == "--help" ] || [ "$1" == "-h" ]
    then
      echo "Bruk: $ `basename $0` <PROJECTNAME>"
      echo "f.eks $ `basename $0` FELLESJAVA"
      return 1
  fi

  echo -e "\nHenter alle repositories fra $1"
  curl -s https://git.spk.no/rest/api/1.0/projects/${1}/repos?limit=500 > repos.json

  for repo_name in `cat repos.json | jq -r '.values[] | select ( .archived==false) .slug'`
  do
    if [[ -d "${1}/$repo_name" ]]
    then
      echo -e "\n$repo_name" "eksisterer. Prøver å oppdatere..."
      git -C ${1}/$repo_name pull --autostash
    else
      echo -e "\nCloning" $repo_name
      git clone ssh://git@git.spk.no:7999/scm/${1}/$repo_name.git ./${1}/$repo_name
    fi
  done

  echo -e "\nFerdig!\nRydder opp og avslutter"
  rm ./repos.json
}
