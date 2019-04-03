# Commands

## How to use

### Zsh commands

#### Prerequisites
1. Install zsh
2. Install fzf

#### Usage
- Place the command in `~/.zsh/<filename>`
- Add the following line to your zsh profile (default: `~/.zshrc`)
```bash
test -e "${HOME}/<filename>" && source "${HOME}/<filename>"
``` 
Do this for every command you'd like to add.

#### Command usage

### `tagcommand.zsh`
Use this in a git repository to view all commits to master and be able to tag them easily.

