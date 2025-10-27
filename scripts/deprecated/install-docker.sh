#!/bin/bash

# =============================================================================
# Docker Installation
# =============================================================================
# Installs Docker Engine and optionally Docker Desktop

print_header "Installing Docker"

# =============================================================================
# Docker Engine
# =============================================================================

if command_exists docker; then
    DOCKER_VERSION=$(docker --version | awk '{print $3}' | sed 's/,//')
    print_success "Docker found: $DOCKER_VERSION"
else
    print_warning "Docker not installed"
    echo ""
    
    if confirm "Install Docker?"; then
        if is_macos; then
            print_info "On macOS, Docker Desktop is recommended over Docker Engine alone"
            print_info "Skipping to Docker Desktop installation..."
            
        elif is_linux; then
            print_info "Installing Docker Engine..."
            
            # Install dependencies
            install_linux_package ca-certificates
            install_linux_package gnupg
            install_linux_package lsb-release
            
            # Add Docker's official GPG key
            sudo mkdir -p /etc/apt/keyrings
            curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
            
            # Set up repository
            echo \
              "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
              $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
            
            # Install Docker Engine
            sudo apt update
            sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
            
            # Add user to docker group
            sudo usermod -aG docker $USER
            
            print_success "Docker Engine installed"
            print_warning "You need to log out and back in for docker group changes to take effect"
        fi
    fi
fi

# =============================================================================
# Docker Desktop (Optional)
# =============================================================================

if is_macos; then
    echo ""
    if [ ! -d "/Applications/Docker.app" ]; then
        print_warning "Docker Desktop not installed"
        print_info "Docker Desktop provides a GUI and better integration with macOS"
        echo ""
        
        if confirm "Install Docker Desktop?"; then
            print_info "Installing Docker Desktop via Homebrew..."
            brew install --cask docker
            print_success "Docker Desktop installed"
            print_info "Launch Docker Desktop from Applications to complete setup"
        fi
    else
        print_success "Docker Desktop already installed"
    fi
    
elif is_linux; then
    echo ""
    print_info "Docker Desktop is available for Linux (optional)"
    
    if confirm "Install Docker Desktop for Linux?"; then
        print_info "Downloading Docker Desktop..."
        
        # Download latest Docker Desktop DEB
        wget -O /tmp/docker-desktop.deb "https://desktop.docker.com/linux/main/amd64/docker-desktop-4.25.0-amd64.deb"
        
        print_info "Installing Docker Desktop..."
        sudo apt install -y /tmp/docker-desktop.deb
        rm /tmp/docker-desktop.deb
        
        print_success "Docker Desktop installed"
        print_info "Run 'systemctl --user start docker-desktop' to start"
    fi
fi

# =============================================================================
# Docker Compose verification
# =============================================================================
echo ""
if command_exists docker; then
    if docker compose version &> /dev/null; then
        COMPOSE_VERSION=$(docker compose version | awk '{print $4}')
        print_success "Docker Compose found: $COMPOSE_VERSION"
    else
        print_warning "Docker Compose not found"
        
        if confirm "Install Docker Compose?"; then
            if is_linux; then
                sudo apt install -y docker-compose-plugin
                print_success "Docker Compose installed"
            fi
        fi
    fi
fi

# =============================================================================
# Test Docker installation
# =============================================================================
if command_exists docker; then
    echo ""
    if confirm "Test Docker installation with 'hello-world' container?"; then
        print_info "Running docker hello-world..."
        docker run --rm hello-world
        
        if [ $? -eq 0 ]; then
            print_success "Docker is working correctly"
        else
            print_error "Docker test failed"
            print_info "You may need to start Docker Desktop or restart your system"
        fi
    fi
fi

echo ""
print_success "Docker setup complete"
