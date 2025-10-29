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

# Check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    if ! command_exists git; then
        print_error "Git is not installed. Please install git first."
        exit 1
    fi
    
    if ! command_exists gpg2; then
        print_error "GPG2 is not installed. Please install gnupg2 first."
        echo "On Ubuntu/Debian: sudo apt-get install gnupg2"
        echo "On macOS: brew install gnupg2"
        echo "On CentOS/RHEL: sudo yum install gnupg2"
        exit 1
    fi
    
    print_success "All prerequisites are met"
}

# Configure Git
configure_git() {
    print_status "Configuring Git..."
    
    # Hardcoded user details
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

# Clone and import GPG keys
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
    if [ ! -f "private.asc" ] && [ ! -f "public.asc" ]; then
        print_error "Neither private.asc nor public.asc found in the repository"
        echo "Available files:"
        ls -la
        cd ..
        return 1
    fi
    
    imported_keys=()
    key_id=""
    
    # Import private key first
    if [ -f "private.asc" ]; then
        print_status "Importing private key from private.asc..."
        if gpg2 --import "private.asc"; then
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
    if [ -f "public.asc" ]; then
        print_status "Importing public key from public.asc..."
        if gpg2 --import "public.asc"; then
            imported_keys+=("public.asc")
            print_success "Public key imported successfully"
            
            # Extract key ID from public key
            print_status "Extracting key ID from public.asc..."
            extracted_key_id=$(extract_key_id "public.asc")
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
