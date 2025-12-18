#!/bin/bash

# Function to print output
print_status() {
    echo "[INFO] $1"
}

print_success() {
    echo "[SUCCESS] $1"
}

print_warning() {
    echo "[WARNING] $1"
}

print_error() {
    echo "[ERROR] $1"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to install packages
install_package() {
    local package=$1
    print_status "Installing $package..."
    
    if command_exists apt-get; then
        # Debian/Ubuntu
        sudo apt-get update && sudo apt-get install -y "$package"
    elif command_exists yum; then
        # CentOS/RHEL
        sudo yum install -y "$package"
    elif command_exists dnf; then
        # Fedora
        sudo dnf install -y "$package"
    elif command_exists brew; then
        # macOS
        brew install "$package"
    elif command_exists pacman; then
        # Arch Linux
        sudo pacman -Sy --noconfirm "$package"
    else
        print_error "Cannot determine package manager. Please install $package manually."
        return 1
    fi
}

# Function to install gnupg2
install_gnupg2() {
    print_status "Installing gnupg2..."
    
    if command_exists apt-get; then
        sudo apt-get update && sudo apt-get install -y gnupg2
    elif command_exists yum; then
        sudo yum install -y gnupg2
    elif command_exists dnf; then
        sudo dnf install -y gnupg2
    elif command_exists brew; then
        brew install gnupg2
    elif command_exists pacman; then
        sudo pacman -Sy --noconfirm gnupg2
    else
        print_error "Cannot determine package manager. Please install gnupg2 manually."
        return 1
    fi
}

# Function to install xxd
install_xxd() {
    print_status "Installing xxd..."
    
    if command_exists apt-get; then
        # On Debian/Ubuntu, xxd is in vim-common or vim-common package
        sudo apt-get update && sudo apt-get install -y vim-common
    elif command_exists yum; then
        # On CentOS/RHEL, xxd is in vim-common
        sudo yum install -y vim-common
    elif command_exists dnf; then
        # On Fedora
        sudo dnf install -y vim-common
    elif command_exists brew; then
        # On macOS, xxd comes with vim
        brew install vim
    elif command_exists pacman; then
        # On Arch Linux
        sudo pacman -Sy --noconfirm vim
    else
        print_warning "Cannot determine package manager. Please install xxd manually."
        print_warning "On Ubuntu/Debian: sudo apt-get install vim-common"
        print_warning "On CentOS/RHEL: sudo yum install vim-common"
        print_warning "On macOS: brew install vim"
        return 1
    fi
}

# Function to extract key ID from GPG public key file
extract_key_id() {
    local key_file="$1"
    
    if [ ! -f "$key_file" ]; then
        print_error "Key file not found: $key_file"
        return 1
    fi
    # Try to extract key ID using gpg2
    local key_id
    key_id=$(gpg2 --with-colons --import-options show-only --import "$key_file" 2>/dev/null | \
             grep "^pub:" | head -1 | cut -d: -f5)
    
    if [ -z "$key_id" ]; then
        # Alternative method: try to import temporarily and get key ID
        key_id=$(gpg2 --import "$key_file" 2>&1 | grep "key" | grep -o "[A-F0-9]\{16\}" | head -1)
        
        if [ -z "$key_id" ]; then
            # Another alternative: look for key pattern in the file
            key_id=$(grep -o "KEY-[A-F0-9]\{16\}" "$key_file" | head -1 | cut -d- -f2)
        fi
    fi
    
    if [ -n "$key_id" ]; then
        echo "$key_id"
        return 0
    else
        print_error "Could not extract key ID from $key_file"
        return 1
    fi
}

    # install Python packages
install_python_packages() {
    print_status "Installing Python packages..."
    
    # Packages
    packages=("python3-requests" "python3-pil")
    
    for package in "${packages[@]}"; do
        print_status "Checking/installing $package..."
        
        if command_exists apt-get; then
            # Debian/Ubuntu
            if dpkg -l | grep -q "^ii.*$package"; then
                print_status "$package is already installed"
            else
                sudo apt-get update && sudo apt-get install -y "$package"
            fi
        elif command_exists yum; then
            # CentOS/RHEL 
            local yum_package
            case "$package" in
                "python3-requests")
                    yum_package="python3-requests"
                    ;;
                "python3-pil")
                    yum_package="python3-pillow"
                    ;;
                *)
                    yum_package="$package"
                    ;;
            esac
            
            if rpm -q "$yum_package" >/dev/null 2>&1; then
                print_status "$yum_package is already installed"
            else
                sudo yum install -y "$yum_package"
            fi
        elif command_exists dnf; then
            # Fedora
            local dnf_package
            case "$package" in
                "python3-requests")
                    dnf_package="python3-requests"
                    ;;
                "python3-pil")
                    dnf_package="python3-pillow"
                    ;;
                *)
                    dnf_package="$package"
                    ;;
            esac
            
            if rpm -q "$dnf_package" >/dev/null 2>&1; then
                print_status "$dnf_package is already installed"
            else
                sudo dnf install -y "$dnf_package"
            fi
        elif command_exists brew; then
            # macOS
            print_status "On macOS, installing Python packages via pip3..."
            pip3 install requests pillow
            return 0
        elif command_exists pacman; then
            # Arch Linux
            local arch_package
            case "$package" in
                "python3-requests")
                    arch_package="python-requests"
                    ;;
                "python3-pil")
                    arch_package="python-pillow"
                    ;;
                *)
                    arch_package="$package"
                    ;;
            esac
            
            if pacman -Qi "$arch_package" >/dev/null 2>&1; then
                print_status "$arch_package is already installed"
            else
                sudo pacman -Sy --noconfirm "$arch_package"
            fi
        else
            print_warning "Cannot determine package manager for $package"
            print_warning "Please install manually:"
            print_warning "  Ubuntu/Debian: sudo apt install $package"
            print_warning "  CentOS/RHEL: sudo yum install $package (names may differ)"
            print_warning "  Fedora: sudo dnf install $package (names may differ)"
            print_warning "  macOS: pip3 install requests pillow"
            print_warning "  Arch: sudo pacman -S ${package/python3-/python-}"
            return 1
        fi
    done
    
    print_success "Python packages installation completed"
}

# Alternative using pip3 
install_python_packages_pip() {
    print_status "Installing Python packages via pip3..."
    
    # Check for pip3
    if ! command_exists pip3; then
        print_status "pip3 not found, installing..."
        if command_exists apt-get; then
            sudo apt-get install -y python3-pip
        elif command_exists yum; then
            sudo yum install -y python3-pip
        elif command_exists dnf; then
            sudo dnf install -y python3-pip
        elif command_exists brew; then
            brew install python3
        elif command_exists pacman; then
            sudo pacman -Sy --noconfirm python-pip
        else
            print_error "Cannot install pip3. Please install pip3 manually."
            return 1
        fi
    fi
    
    # Install using pip3
    packages=("requests" "pillow")
    for package in "${packages[@]}"; do
        print_status "Installing $package via pip3..."
        if pip3 list | grep -i "^$package" >/dev/null 2>&1; then
            print_status "$package is already installed via pip3"
        else
            pip3 install "$package"
        fi
    done
    
    print_success "Python packages installed via pip3"
}

# Check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    # Check and install git if needed
    if ! command_exists git; then
        print_error "Git is not installed. Installing git..."
        if ! install_package git; then
            print_error "Failed to install git. Please install git manually."
            exit 1
        fi
    fi
    
    # Check and install gpg2 if needed
    if ! command_exists gpg2; then
        print_warning "GPG2 is not installed. Installing gnupg2..."
        if ! install_gnupg2; then
            print_error "Failed to install gnupg2. Please install gnupg2 manually."
            exit 1
        fi
    fi
    
    # Check and install xxd if needed
    if ! command_exists xxd; then
        print_warning "xxd is not installed. Installing xxd..."
        if ! install_xxd; then
            print_warning "xxd installation failed, but continuing without it..."
        fi
    fi

    # Check and install Python packages if needed
    print_status "Checking Python packages..."
    
    # Check if Python 3 is installed
    if ! command_exists python3; then
        print_warning "Python3 is not installed. Installing..."
        if ! install_package python3; then
            print_warning "Python3 installation failed, skipping Python packages..."
            return 0
        fi
    else
        print_status "Python3 is already installed"
    fi
    
    # Check if pip3 is installed
    if ! command_exists pip3; then
        print_status "pip3 not found, installing..."
        if command_exists apt-get; then
            sudo apt-get install -y python3-pip
        elif command_exists yum; then
            sudo yum install -y python3-pip
        elif command_exists dnf; then
            sudo dnf install -y python3-pip
        elif command_exists brew; then
            brew install python3
        elif command_exists pacman; then
            sudo pacman -Sy --noconfirm python-pip
        else
            print_warning "Cannot install pip3. Please install pip3 manually."
            return 1
        fi
    else
        print_status "pip3 is already installed"
    fi
    
    # Check and install requests if needed
    if python3 -c "import requests" 2>/dev/null; then
        print_status "requests is already installed"
    else
        print_status "Installing requests..."
        if pip3 install requests; then
            print_success "Successfully installed requests"
        else
            print_warning "Failed to install requests"
        fi
    fi
    
    # Check and install Pillow if needed
    if python3 -c "import PIL" 2>/dev/null; then
        print_status "Pillow is already installed"
    else
        print_status "Installing Pillow..."
        if pip3 install pillow; then
            print_success "Successfully installed Pillow"
        else
            print_warning "Failed to install Pillow"
        fi
    fi
    
    print_success "All prerequisites are met"
}

# Configure Git
configure_git() {
    print_status "Configuring Git..."
    
    # Hardcoded details
    git_name="iHSAN"
    git_email="ihsanulrahman@proton.me"
    
    # Set Git configuration
    git config --global user.name "$git_name"
    git config --global user.email "$git_email"
    git config --global init.defaultBranch main
    git config --global pull.rebase false
    
    print_success "Git configuration completed"
    echo "Name: $git_name"
    echo "Email: $git_email"
}

# Clone and import GPGkeys
setup_gpg() {
    print_status "Setting up GPG keys..."
    
    # Hardcoded GPG repo details
    gpg_repo_url="https://github.com/ihsanulrahman/gpg-keys.git"
    clone_dir="gpg-keys"
    
    # Clone the repository
    print_status "Cloning GPG keys repository..."
    if git clone "$gpg_repo_url" "$clone_dir"; then
        print_success "GPG keys repository cloned successfully"
    else
        print_error "Failed to clone GPG keys repository"
        return 1
    fi
    
    # Navigate to the directory
    cd "$clone_dir" || {
        print_error "Failed to enter directory $clone_dir"
        return 1
    }
    
    # Import GPG keys - specifically look for private.asc and public.asc
    print_status "Looking for key files..."
    
    # Check for specific key files
    if [ ! -f "private*.asc" ] && [ ! -f "public*.asc" ]; then
        print_error "Neither private nor public keys found in the repository"
        echo "Available files:"
        ls -la
        cd ..
        return 1
    fi
    
    imported_keys=()
    key_id=""
    
    # Import private key first
    if [ -f "private*.asc" ]; then
        print_status "Importing private key from private.asc..."
        if gpg2 --import "private*.asc"; then
            imported_keys+=("private.asc")
            print_success "Private key imported successfully"
        else
            print_error "Failed to import private key"
            cd ..
            return 1
        fi
    else
        print_warning "private.asc not found, skipping private key import"
    fi
    
    # Import public key
    if [ -f "public*.asc" ]; then
        print_status "Importing public key from public.asc..."
        if gpg2 --import "public*.asc"; then
            imported_keys+=("public.asc")
            print_success "Public key imported successfully"
            
            # Extract key ID from public key
            print_status "Extracting key ID from public.asc..."
            extracted_key_id=$(extract_key_id "public*.asc")
            if [ -n "$extracted_key_id" ]; then
                key_id="$extracted_key_id"
                print_success "Extracted key ID: $key_id"
            fi
        else
            print_warning "Failed to import public key (may already exist)"
        fi
    else
        print_warning "public.asc not found, skipping public key import"
    fi
    
    if [ ${#imported_keys[@]} -eq 0 ]; then
        print_error "No GPG keys were successfully imported"
        cd ..
        return 1
    fi
    
    # If we couldn't extract key ID from public.asc, try to get it from keyring
    if [ -z "$key_id" ]; then
        print_status "Getting GPG key ID from keyring..."
        key_id=$(gpg2 --list-secret-keys --keyid-format LONG 2>/dev/null | grep sec | tail -1 | awk '{print $2}' | cut -d'/' -f2)
        
        if [ -z "$key_id" ]; then
            print_error "Could not determine GPG key ID"
            cd ..
            return 1
        fi
    fi
    
    print_success "Using GPG key ID: $key_id"
    
    # Verify private key is imported and usable
    print_status "Verifying private key import..."
    if gpg2 --list-secret-keys "$key_id" >/dev/null 2>&1; then
        print_success "Private key successfully imported and available"
    else
        print_error "Private key not found or not usable"
        cd ..
        return 1
    fi
    
    # Configure Git to use the GPG key with gpg2
    print_status "Configuring Git to use GPG key..."
    git config --global user.signingkey "$key_id"
    git config --global commit.gpgsign true
    git config --global tag.gpgsign true
    git config --global gpg.program gpg2
    
    print_success "GPG setup completed"
    
    # Go back to original directory
    cd ..
}

# Test GPG signing
test_gpg_signing() {
    print_status "Testing GPG configuration..."
    
    # Test if GPG key is properly set up with private key
    if echo "test" | gpg2 --clearsign > /dev/null 2>&1; then
        print_success "GPG signing test passed - private key is working"
    else
        print_warning "GPG signing test failed - you may need to set up GPG agent or enter passphrase"
    fi
    
    # Test Git configuration
    if git config --global user.signingkey > /dev/null 2>&1; then
        key=$(git config --global user.signingkey)
        print_success "Git signing key is set to: $key"
    else
        print_error "Git signing key is not set"
    fi
}

# Display final configuration
show_configuration() {
    print_status "Final Git configuration:"
    echo "User Name: $(git config --global user.name)"
    echo "User Email: $(git config --global user.email)"
    echo "Signing Key: $(git config --global user.signingkey)"
    echo "Commit Signing: $(git config --global commit.gpgsign)"
    echo "Tag Signing: $(git config --global tag.gpgsign)"
    echo "GPG Program: $(git config --global gpg.program)"
}

# Verify key import
verify_key_import() {
    local key_id="$1"
    
    print_status "Verifying key import..."
    
    echo "Public keys:"
    gpg2 --list-keys "$key_id" 2>/dev/null
    
    echo "Private keys:"
    gpg2 --list-secret-keys "$key_id" 2>/dev/null
    
    if gpg2 --list-secret-keys "$key_id" >/dev/null 2>&1; then
        print_success "Private key is properly imported"
    else
        print_error "Private key is missing - signing will not work"
    fi
}

# Trust the GPG key (optional)
trust_gpg_key() {
    local key_id="$1"
    
    if [ -z "$key_id" ]; then
        key_id=$(git config --global user.signingkey)
    fi
    
    if [ -n "$key_id" ]; then
        print_status "Setting ultimate trust for key $key_id..."
        echo -e "5\ny\n" | gpg2 --command-fd 0 --edit-key "$key_id" trust 2>/dev/null
        if [ $? -eq 0 ]; then
            print_success "Key $key_id set to ultimate trust level"
        else
            print_warning "Could not set trust level automatically. You may need to do it manually."
            echo "To set trust manually run: gpg2 --edit-key $key_id"
            echo "Then enter: trust -> 5 -> y -> quit"
        fi
    fi
}

# Main execution
main() {
    echo "=================================================="
    echo "        Git and GPG Auto Setup Script"
    echo "=================================================="
    echo ""
    
    check_prerequisites
    echo ""
    
    configure_git
    echo ""
    
    setup_gpg
    echo ""
    
    # Trust the key if we have one
    key_id=$(git config --global user.signingkey)
    if [ -n "$key_id" ]; then
        trust_gpg_key "$key_id"
        echo ""
        
        verify_key_import "$key_id"
        echo ""
    fi
    
    test_gpg_signing
    echo ""
    
    show_configuration
    echo ""
    
    print_success "Setup completed!"
    
    # Display next steps
    print_status "Next steps:"
    echo "1. Add your GPG public key to GitHub/GitLab:"
    echo "   gpg2 --armor --export $(git config --global user.signingkey)"
    echo "2. Test with a signed commit:"
    echo "   git init /tmp/test-repo && cd /tmp/test-repo"
    echo "   git commit --allow-empty -S -m 'Test signed commit'"
    echo "3. If you have issues with passphrase, set up gpg-agent:"
    echo "   echo 'use-agent' >> ~/.gnupg/gpg.conf"
    echo "4. To cache passphrase:"
    echo "   echo 'default-cache-ttl 3600' >> ~/.gnupg/gpg-agent.conf"
    echo "   echo 'max-cache-ttl 7200' >> ~/.gnupg/gpg-agent.conf"
}

# Run the main function
main
