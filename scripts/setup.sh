#!/bin/bash

# CosyVoice Project Setup Script
# This script sets up the development environment using uv

set -e  # Exit on error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored messages
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo ""
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to compare versions
version_ge() {
    printf '%s\n%s' "$2" "$1" | sort -V -C
}

print_header "CosyVoice Environment Setup"

# ============================================
# 1. Check Operating System
# ============================================
print_info "Checking operating system..."
OS_TYPE=$(uname -s)
case "$OS_TYPE" in
    Linux*)
        print_success "Operating System: Linux"
        OS="linux"
        ;;
    Darwin*)
        print_success "Operating System: macOS"
        OS="darwin"
        ;;
    MINGW*|MSYS*|CYGWIN*)
        print_warning "Operating System: Windows (Git Bash/MSYS)"
        OS="windows"
        ;;
    *)
        print_error "Unsupported operating system: $OS_TYPE"
        exit 1
        ;;
esac

# ============================================
# 2. Check CUDA availability (for Linux)
# ============================================
HAS_CUDA=false
if [ "$OS" = "linux" ]; then
    print_info "Checking for CUDA..."
    if command_exists nvcc; then
        CUDA_VERSION=$(nvcc --version | grep "release" | awk '{print $6}' | cut -d',' -f1 | cut -d'V' -f2)
        print_success "CUDA detected: version $CUDA_VERSION"

        # Check if CUDA version is compatible (expecting CUDA 12.x)
        CUDA_MAJOR=$(echo $CUDA_VERSION | cut -d'.' -f1)
        if [ "$CUDA_MAJOR" -ge 12 ]; then
            print_success "CUDA version is compatible (12.x or higher)"
            HAS_CUDA=true
        else
            print_warning "CUDA version $CUDA_VERSION detected. This project expects CUDA 12.x"
            print_warning "Some GPU features may not work correctly"
        fi
    else
        print_warning "CUDA not detected. GPU acceleration will not be available."
        print_warning "Install CUDA 12.x for GPU support: https://developer.nvidia.com/cuda-downloads"
    fi
fi

# ============================================
# 3. Check Git
# ============================================
print_info "Checking for git..."
if ! command_exists git; then
    print_error "git is not installed"
    print_error "Please install git: https://git-scm.com/downloads"
    exit 1
fi
GIT_VERSION=$(git --version | awk '{print $3}')
print_success "git is installed: version $GIT_VERSION"

# ============================================
# 4. Check Git submodules
# ============================================
print_info "Checking git submodules..."
if [ -f .gitmodules ]; then
    print_info "Initializing git submodules..."
    git submodule update --init --recursive
    print_success "Git submodules initialized"
else
    print_info "No git submodules found"
fi

# ============================================
# 5. Check Python
# ============================================
print_info "Checking for Python..."
REQUIRED_PYTHON_VERSION="3.10.16"
REQUIRED_PYTHON_MINOR="3.10"

if ! command_exists python3; then
    print_error "python3 is not installed"
    print_error "Please install Python $REQUIRED_PYTHON_VERSION or higher"
    exit 1
fi

PYTHON_VERSION=$(python3 --version | awk '{print $2}')
PYTHON_MINOR=$(echo $PYTHON_VERSION | cut -d'.' -f1,2)
print_success "Python is installed: version $PYTHON_VERSION"

# Check if Python version meets requirements
if ! version_ge "$PYTHON_VERSION" "$REQUIRED_PYTHON_MINOR.0"; then
    print_error "Python version $PYTHON_VERSION is too old"
    print_error "Required: Python >= $REQUIRED_PYTHON_MINOR"
    exit 1
fi

if [ "$PYTHON_MINOR" != "$REQUIRED_PYTHON_MINOR" ]; then
    print_warning "Python $PYTHON_VERSION detected, but project specifies $REQUIRED_PYTHON_VERSION"
    print_warning "Proceeding with current Python version..."
fi

# ============================================
# 6. Check uv
# ============================================
print_info "Checking for uv..."
if ! command_exists uv; then
    print_error "uv is not installed"
    print_info "Installing uv..."

    # Install uv
    if [ "$OS" = "windows" ]; then
        print_error "Please install uv manually on Windows: https://docs.astral.sh/uv/getting-started/installation/"
        exit 1
    else
        curl -LsSf https://astral.sh/uv/install.sh | sh

        # Add uv to PATH for current session
        export PATH="$HOME/.local/bin:$PATH"

        if ! command_exists uv; then
            print_error "Failed to install uv"
            exit 1
        fi
    fi
fi

UV_VERSION=$(uv --version | awk '{print $2}')
print_success "uv is installed: version $UV_VERSION"

# ============================================
# 7. Check disk space
# ============================================
print_info "Checking available disk space..."
if [ "$OS" = "linux" ] || [ "$OS" = "darwin" ]; then
    AVAILABLE_SPACE=$(df -BG . | awk 'NR==2 {print $4}' | sed 's/G//')
    if [ "$AVAILABLE_SPACE" -lt 10 ]; then
        print_warning "Low disk space: ${AVAILABLE_SPACE}GB available"
        print_warning "Consider freeing up space. Recommended: at least 10GB"
    else
        print_success "Sufficient disk space: ${AVAILABLE_SPACE}GB available"
    fi
fi

# ============================================
# 8. Setup Python environment with uv
# ============================================
print_header "Setting Up Python Environment"

print_info "Creating virtual environment with uv..."
uv venv --python "$REQUIRED_PYTHON_VERSION" || uv venv --python "$PYTHON_MINOR"

print_success "Virtual environment created"

# ============================================
# 9. Install dependencies
# ============================================
print_info "Installing core dependencies..."
print_warning "This may take several minutes depending on your internet connection..."

# Install core dependencies (without TensorRT)
uv sync

print_success "Core dependencies installed"

# ============================================
# 10. Install TensorRT (optional, Linux only)
# ============================================
if [ "$OS" = "linux" ] && [ "$HAS_CUDA" = true ]; then
    print_info "TensorRT installation detected (Linux with CUDA)"

    read -p "Do you want to install TensorRT for GPU acceleration? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_info "Installing TensorRT packages..."

        # Install TensorRT using pip with the NVIDIA PyPI index
        if [ "$OS" = "windows" ]; then
            .venv/Scripts/python -m pip install --extra-index-url https://pypi.nvidia.com \
                tensorrt-cu12==10.0.1 \
                tensorrt-cu12-bindings==10.0.1 \
                tensorrt-cu12-libs==10.0.1 2>/dev/null || {
                print_warning "TensorRT installation failed. This is optional and can be skipped."
                print_warning "You can install it later with: pip install tensorrt-cu12 tensorrt-cu12-bindings tensorrt-cu12-libs --extra-index-url https://pypi.nvidia.com"
            }
        else
            .venv/bin/python -m pip install --extra-index-url https://pypi.nvidia.com \
                tensorrt-cu12==10.0.1 \
                tensorrt-cu12-bindings==10.0.1 \
                tensorrt-cu12-libs==10.0.1 2>/dev/null || {
                print_warning "TensorRT installation failed. This is optional and can be skipped."
                print_warning "You can install it later with: pip install tensorrt-cu12 tensorrt-cu12-bindings tensorrt-cu12-libs --extra-index-url https://pypi.nvidia.com"
            }
        fi

        if [ $? -eq 0 ]; then
            print_success "TensorRT installed successfully"
        fi
    else
        print_info "Skipping TensorRT installation"
        print_info "You can install it later with: uv pip install --extra-index-url https://pypi.nvidia.com tensorrt-cu12 tensorrt-cu12-bindings tensorrt-cu12-libs"
    fi
else
    if [ "$OS" != "linux" ]; then
        print_info "TensorRT is only available on Linux, skipping..."
    elif [ "$HAS_CUDA" = false ]; then
        print_info "CUDA not detected, skipping TensorRT installation..."
    fi
fi

# ============================================
# 11. Verify installation
# ============================================
print_header "Verifying Installation"

print_info "Checking key dependencies..."

# Activate virtual environment and check packages
if [ "$OS" = "windows" ]; then
    source .venv/Scripts/activate
else
    source .venv/bin/activate
fi

# Check for critical packages
CRITICAL_PACKAGES=("torch" "torchaudio" "transformers" "fastapi" "gradio")
ALL_OK=true

for package in "${CRITICAL_PACKAGES[@]}"; do
    if uv pip show "$package" >/dev/null 2>&1; then
        VERSION=$(uv pip show "$package" | grep "Version:" | awk '{print $2}')
        print_success "$package: $VERSION"
    else
        print_error "$package is not installed"
        ALL_OK=false
    fi
done

if [ "$ALL_OK" = true ]; then
    print_success "All critical packages are installed"
else
    print_error "Some critical packages are missing"
    exit 1
fi

# ============================================
# 12. Final checks and instructions
# ============================================
print_header "Setup Complete!"

print_success "Environment setup completed successfully!"
echo ""
print_info "To activate the virtual environment, run:"
if [ "$OS" = "windows" ]; then
    echo -e "  ${GREEN}source .venv/Scripts/activate${NC}"
else
    echo -e "  ${GREEN}source .venv/bin/activate${NC}"
fi
echo ""
print_info "To run the web UI:"
echo -e "  ${GREEN}python webui.py${NC}"
echo ""
print_info "For more information, see README.md"
echo ""

# Optional: Create a .env file template if it doesn't exist
if [ ! -f ".env" ]; then
    print_info "Creating .env template..."
    cat > .env << 'EOF'
# CosyVoice Environment Variables
# Uncomment and modify as needed

# Model cache directory
# MODEL_CACHE_DIR=./models

# API settings
# API_HOST=0.0.0.0
# API_PORT=8000

# Logging level
# LOG_LEVEL=INFO
EOF
    print_success ".env template created"
fi

print_success "Setup script finished!"
