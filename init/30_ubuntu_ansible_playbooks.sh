# Ubuntu-only stuff. Abort if not Ubuntu.
is_ubuntu || return 1

ansible-playbook -K $DOTFILES/ansible/playbooks/main.yaml