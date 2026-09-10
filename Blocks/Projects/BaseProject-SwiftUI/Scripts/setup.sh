#!/bin/bash 

if (( $EUID == 0 )); then
  echo "Please don't run this whole script as root/sudo."
  exit
fi

# Will check if command has been setup on shell profile
# will set it if not
#
# $1 -> command
# $2 -> command name
add_command_shell_profile () {
    COMMAND=$1
    COMMAND_NAME=$2

    if [ -f ~/.zshrc ]; then
        # check if command init has been set up or hasn't
        if grep -q "$COMMAND" "$HOME/.zshrc"; then
            echo "✅ $COMMAND_NAME has been set up for zsh"
        else
            echo "✅ Set up $COMMAND_NAME for zsh"
            echo "" >> ~/.zshrc
            echo "$COMMAND" >> ~/.zshrc
        fi
    
    elif [ -f ~/.zprofile ]; then
        # check if command init has been set up or hasn't
        if grep -q "$COMMAND" "$HOME/.zprofile"; then
            echo "✅ $COMMAND_NAME has been set up for zshell"
        else
            echo "✅ Set up $COMMAND_NAME for zshell"
            echo "" >> ~/.zprofile
            echo "$COMMAND" >> ~/.zprofile
        fi
        
    elif [ -f  ~/.bash_profile ]; then
        # check if command init has been set up or hasn't
        if grep -q "$COMMAND" "$HOME/.bash_profile"; then
            echo "✅ $COMMAND_NAME has been set up for bash"
        else
            echo "✅ Set up $COMMAND_NAME for bash"
            echo "" >> ~/.bash_profile
            echo "$COMMAND" >> ~/.bash_profile
        fi

        # because every mac used bash as default, will also create zshrc file to accomodate the possibility of using zsh
        touch ~/.zshrc
        echo "$COMMAND" >> ~/.zshrc
    else
        # initiate zshrc for first time
        if [ -x "$(which zsh 2>/dev/null)" ]; then
            touch ~/.zshrc
            echo "$COMMAND" >> ~/.zshrc
            echo "✅ Set up $COMMAND_NAME for zsh"
        # initiate bash_profile for first time
        elif [ -x "$(which bash 2>/dev/null)" ]; then
            touch ~/.bash_profile
            echo "$COMMAND" >> ~/.bash_profile
            echo "✅ Set up $COMMAND_NAME for bash"
        # unidentified shell
        else
            echo '💥 Unidentified shell'
            exit 1
        fi
    fi
}

BREW_PREFIX_PATH=""
if [ $(arch) == "arm64" ]; then
    echo "✅ Device is using Apple Silicon"
    BREW_PREFIX_PATH="/opt/homebrew/bin"
else
    echo "✅ Device is using Intel"
    BREW_PREFIX_PATH="/usr/local/bin"
fi

# Homebrew
which -s brew

if [[ $? != 0 ]] ; then
    # Install Homebrew
    echo '✅ Installing Homebrew'

    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    
    if [ $(arch) == "arm64" ]; then
        git -C "/opt/homebrew/Library/Taps/homebrew/homebrew-core" fetch --unshallow
    else
        git -C "/usr/local/Homebrew/Library/Taps/homebrew/homebrew-core" fetch --unshallow
    fi
  
    # setup additional shell
    COMMAND='eval "$(/opt/homebrew/bin/brew shellenv)"';
    add_command_shell_profile "$COMMAND" "homebrew"
    eval "$(/opt/homebrew/bin/brew shellenv)"
    
    brew update
else
    echo '✅ Homebrew has been installed'

    # call the command to apply it to current session if not already
    eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# Tuist
if which tuist > /dev/null; then
    echo "✅ Tuist is already installed"
else
    echo "✅ Installing Tuist"
  
    brew tap tuist/tuist

    brew install --formula tuist

    echo "🎉 Tuist installation is complete!"
fi

# Init Git
if [ -d .git ]; then
    echo '✅ Git has been initialized'
else
    echo '✅ Initializing Git'
    git init 2>&1 | grep -v '^hint:'
    echo '✅ Using main branch as default branch'
    git branch -M main
fi

if ! git rev-parse HEAD >/dev/null 2>&1; then
    echo "💥 No commits found, creating initial commit"
    git add .
    git commit -m "Initial commit"
fi

# Pre-commit
if which pre-commit > /dev/null; then
    echo '✅ pre-commit has been installed'
else
    brew install pre-commit
fi
pre-commit install

# Swiftlint
if which swiftlint > /dev/null; then
    echo '✅ Swiftlint has been installed'
else
    brew install swiftlint
fi

# Swiftformat
if which swiftformat > /dev/null; then
    echo '✅ Swiftformat has been installed'
else
    brew install swiftformat
fi

# Xcode Templates
mkdir -p ~/Library/Developer/Xcode/Templates/File\ Templates

SCRIPT_FILE=$(readlink -f "$0")
SCRIPT_PATH=$(dirname "$SCRIPT_FILE")
SOURCE_PATH="$SCRIPT_PATH/../"
TEMPLATES_PATH="${SOURCE_PATH}/.XcodeFileTemplates"

TARGET_PATH=~/Library/Developer/Xcode/Templates/File\ Templates/__PROJECT_NAME__

if [ -d "$TARGET_PATH" ]; then
    echo '✅ Xcode templates has been added'
else
    ln -s "$TEMPLATES_PATH" "$TARGET_PATH"
    echo '✅ Xcode templates been added'
fi

# Ends
echo '🎉 Done!'
