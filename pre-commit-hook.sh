#!/bin/bash

# Determine the operating system
os_name=$(uname -s)

function run_linux_commands {
    if ! command -v jq &> /dev/null; then
        if command -v apt-get &> /dev/null; then
            sudo apt-get update && sudo apt-get install -y jq
        elif command -v yum &> /dev/null
        then
            sudo yum install -y jq
        else
            echo "Unsupported package manager. Please install jq manually."
            exit 1
        fi
    fi

    if ! command -v gitleaks &> /dev/null; then
        echo "gitleaks could not be found. Installing gitleaks..."
        curl -sL https://api.github.com/repos/gitleaks/gitleaks/releases/latest | \
        jq -r '.assets[].browser_download_url' | \
        grep -i $(uname -s) | \
        grep -i $(uname -m | sed  "s/86_//") | \
        xargs -I {} curl -sL {} -o gitleaks.tar.gz

        if [[ -f "gitleaks.tar.gz" ]]; then
            tar -xzf gitleaks.tar.gz
            sudo mv gitleaks /usr/local/bin/
            echo "gitleaks installed successfully."
        else
            echo "Failed to download gitleaks."
            exit 1
        fi
    else
        echo "gitleaks is already installed."
    fi
}

# Function for macOS
function run_macos_commands {
    echo "Running commands for macOS"
    if command -v brew &> /dev/null
    then
       if ! command -v gitleaks &> /dev/null; then
          brew install gitleaks
       else
          echo "gitleaks is already installed."
       fi
    else
       echo "Homebrew is not installed. Please install Homebrew to proceed."
#      /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
       exit 1
    fi
}

# Function to create the pre-commit hook
function create_pre_commit_hook {
    hook_file=".git/hooks/pre-commit"

    if [[ -f "$hook_file" ]]; then
        echo "pre-commit hook already exists. Skipping creation."
    else
        cat << 'EOF' > "$hook_file"
#!/bin/bash

# Check if the gitleaks hook is enabled in the git config
gitleaks_enabled=$(git config --get hooks.gitleaks)

if [[ "$gitleaks_enabled" != "true" ]]; then
    echo "gitleaks hook is not enabled. To enable, run: git config hooks.gitleaks true"
    exit 0
fi

# Check if gitleaks is installed
if ! command -v gitleaks &> /dev/null; then
    echo "gitleaks is not installed. Please install gitleaks to proceed."
    exit 1
fi

# Run gitleaks and check for leaks
echo "Running gitleaks..."
gitleaks detect --source .

if [ $? -ne 0 ]; then
    echo "gitleaks detected leaks. Please fix the issues before committing."
    exit 1
fi

echo "No leaks detected by gitleaks. Proceeding with commit."
EOF
        chmod +x "$hook_file"
        echo "pre-commit hook created successfully."
    fi
}

# Check the OS and call the appropriate function
case "$os_name" in
    Darwin)
        run_macos_commands
        ;;
    Linux)
        run_linux_commands
        ;;
    *)
        echo "Unsupported operating system: $os_name"
        ;;
esac

create_pre_commit_hook
