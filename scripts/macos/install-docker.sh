#!/bin/bash

# =============================================================================
# Docker Installation - macOS
# =============================================================================
# Installs Docker Desktop for macOS

print_header "Installing Docker (macOS)"

# =============================================================================
# Docker Desktop
# =============================================================================

if [ -d "/Applications/Docker.app" ]; then
    print_success "Docker Desktop already installed"

    # Check if Docker is running
    if docker info >/dev/null 2>&1; then
        DOCKER_VERSION=$(docker --version | awk '{print $3}' | sed 's/,//')
        print_success "Docker is running: $DOCKER_VERSION"
    else
        print_warning "Docker Desktop is installed but not running"
        print_info "Start Docker Desktop from Applications to use Docker"
    fi
else
    print_warning "Docker Desktop not installed"
    print_info "Docker Desktop provides Docker Engine with macOS integration"
    print_info "Website: https://www.docker.com/products/docker-desktop"
    echo ""

    if confirm "Install Docker Desktop?"; then
        print_info "Installing Docker Desktop via Homebrew..."
        brew install --cask docker
        print_success "Docker Desktop installed"
        print_info "Launch Docker Desktop from Applications to complete setup"
    else
        print_warning "Skipping Docker installation"
        return 0
    fi
fi

# =============================================================================
# Verify Docker Compose
# =============================================================================

echo ""
if [ -d "/Applications/Docker.app" ]; then
    # Docker Desktop includes Docker Compose
    print_info "Docker Desktop includes Docker Compose"

    if docker info >/dev/null 2>&1; then
        if docker compose version &> /dev/null; then
            COMPOSE_VERSION=$(docker compose version --short 2>/dev/null || echo "included")
            print_success "Docker Compose available: $COMPOSE_VERSION"
        fi
    else
        print_info "Start Docker Desktop to use Docker Compose"
    fi
fi

# =============================================================================
# Optional: Test Docker Installation
# =============================================================================

if docker info >/dev/null 2>&1; then
    echo ""
    if confirm "Test Docker installation with 'hello-world' container?"; then
        print_info "Running docker hello-world..."
        if docker run --rm hello-world; then
            print_success "Docker is working correctly"
        else
            print_error "Docker test failed"
            print_info "Try restarting Docker Desktop"
        fi
    fi
else
    echo ""
    print_info "Docker is not currently running"
    print_info "To start Docker:"
    print_info "  1. Open 'Docker' from Applications"
    print_info "  2. Wait for Docker to start (whale icon in menu bar)"
    print_info "  3. Run 'docker run hello-world' to test"
fi

echo ""
print_success "Docker setup complete"
