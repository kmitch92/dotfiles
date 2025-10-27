#!/bin/bash

# =============================================================================
# Docker Installation - Linux
# =============================================================================
# Installs Docker Engine and optionally Docker Desktop for Linux

print_header "Installing Docker (Linux)"

# =============================================================================
# Docker Engine
# =============================================================================

if command_exists docker; then
    DOCKER_VERSION=$(docker --version | awk '{print $3}' | sed 's/,//')
    print_success "Docker found: $DOCKER_VERSION"

    # Check if Docker daemon is running
    if docker info >/dev/null 2>&1; then
        print_success "Docker daemon is running"
    else
        print_warning "Docker is installed but daemon is not running"
        print_info "Start Docker with: sudo systemctl start docker"
    fi
else
    print_warning "Docker not installed"
    echo ""

    if confirm "Install Docker Engine?"; then
        print_info "Installing Docker Engine..."

        local distro=$(detect_linux_distro)

        case $distro in
            ubuntu|debian|pop)
                # Install dependencies
                print_info "Installing dependencies..."
                sudo apt-get update
                sudo apt-get install -y ca-certificates curl gnupg lsb-release

                # Add Docker's official GPG key
                print_info "Adding Docker GPG key..."
                sudo install -m 0755 -d /etc/apt/keyrings
                curl -fsSL https://download.docker.com/linux/$distro/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
                sudo chmod a+r /etc/apt/keyrings/docker.gpg

                # Set up repository
                print_info "Setting up Docker repository..."
                echo \
                  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/$distro \
                  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

                # Install Docker Engine
                print_info "Installing Docker Engine..."
                sudo apt-get update
                sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

                # Start and enable Docker
                sudo systemctl start docker
                sudo systemctl enable docker

                print_success "Docker Engine installed"
                ;;

            fedora|rhel|centos)
                # Install dependencies
                print_info "Installing dependencies..."
                sudo dnf -y install dnf-plugins-core

                # Add Docker repository
                print_info "Adding Docker repository..."
                sudo dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo

                # Install Docker Engine
                print_info "Installing Docker Engine..."
                sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

                # Start and enable Docker
                sudo systemctl start docker
                sudo systemctl enable docker

                print_success "Docker Engine installed"
                ;;

            arch|manjaro)
                print_info "Installing Docker via pacman..."
                sudo pacman -S --noconfirm docker docker-compose

                # Start and enable Docker
                sudo systemctl start docker.service
                sudo systemctl enable docker.service

                print_success "Docker Engine installed"
                ;;

            *)
                print_error "Unsupported distribution: $distro"
                print_info "Please install Docker manually from https://docs.docker.com/engine/install/"
                return 1
                ;;
        esac

        # Add user to docker group
        echo ""
        if confirm "Add current user ($USER) to docker group? (recommended to run docker without sudo)"; then
            sudo usermod -aG docker $USER
            print_success "User added to docker group"
            print_warning "You need to log out and back in for group changes to take effect"
            print_info "Or run: newgrp docker"
        fi
    else
        print_warning "Skipping Docker installation"
        return 0
    fi
fi

# =============================================================================
# Docker Desktop (Optional)
# =============================================================================

echo ""
print_info "Docker Desktop for Linux is available (optional)"
print_info "It provides a GUI and enhanced features, but Docker Engine is sufficient for most use cases"
echo ""

if confirm "Install Docker Desktop for Linux?"; then
    local distro=$(detect_linux_distro)

    case $distro in
        ubuntu|debian|pop)
            print_info "Downloading Docker Desktop..."

            # Get the latest version
            local arch=$(dpkg --print-architecture)
            local download_url="https://desktop.docker.com/linux/main/$arch/docker-desktop-latest-$arch.deb"

            wget -O /tmp/docker-desktop.deb "$download_url"

            print_info "Installing Docker Desktop..."
            sudo apt-get install -y /tmp/docker-desktop.deb
            rm /tmp/docker-desktop.deb

            print_success "Docker Desktop installed"
            print_info "Start with: systemctl --user start docker-desktop"
            ;;

        fedora|rhel|centos)
            print_info "Downloading Docker Desktop..."

            local download_url="https://desktop.docker.com/linux/main/amd64/docker-desktop-latest-x86_64.rpm"

            wget -O /tmp/docker-desktop.rpm "$download_url"

            print_info "Installing Docker Desktop..."
            sudo dnf install -y /tmp/docker-desktop.rpm
            rm /tmp/docker-desktop.rpm

            print_success "Docker Desktop installed"
            print_info "Start with: systemctl --user start docker-desktop"
            ;;

        arch|manjaro)
            print_warning "Docker Desktop is not officially packaged for Arch Linux"
            print_info "Consider using Docker Engine with Portainer for a GUI alternative"
            ;;

        *)
            print_error "Docker Desktop installation not supported for this distribution"
            ;;
    esac
fi

# =============================================================================
# Verify Docker Compose
# =============================================================================

echo ""
if command_exists docker; then
    if docker compose version &> /dev/null; then
        COMPOSE_VERSION=$(docker compose version --short 2>/dev/null || echo "installed")
        print_success "Docker Compose available: $COMPOSE_VERSION"
    else
        print_warning "Docker Compose plugin not found"

        if confirm "Install Docker Compose plugin?"; then
            local distro=$(detect_linux_distro)

            case $distro in
                ubuntu|debian|pop)
                    sudo apt-get install -y docker-compose-plugin
                    ;;
                fedora|rhel|centos)
                    sudo dnf install -y docker-compose-plugin
                    ;;
                arch|manjaro)
                    sudo pacman -S --noconfirm docker-compose
                    ;;
            esac

            print_success "Docker Compose installed"
        fi
    fi
fi

# =============================================================================
# Test Docker Installation
# =============================================================================

if command_exists docker && docker info >/dev/null 2>&1; then
    echo ""
    if confirm "Test Docker installation with 'hello-world' container?"; then
        print_info "Running docker hello-world..."

        if docker run --rm hello-world; then
            print_success "Docker is working correctly"
        else
            print_error "Docker test failed"

            # Check if it's a permission issue
            if ! groups | grep -q docker; then
                print_info "You may need to add yourself to the docker group or restart your session"
                print_info "Try: newgrp docker"
            fi
        fi
    fi
elif command_exists docker; then
    echo ""
    print_warning "Docker is installed but not running"
    print_info "Start Docker with: sudo systemctl start docker"
fi

echo ""
print_success "Docker setup complete"
