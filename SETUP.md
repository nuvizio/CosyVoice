# CosyVoice Setup Guide

## Quick Start

To set up the CosyVoice development environment, run:

```bash
./setup.sh
```

This script will automatically:
- ✅ Check system requirements
- ✅ Verify CUDA installation (on Linux)
- ✅ Initialize git submodules
- ✅ Create a Python virtual environment using `uv`
- ✅ Install all dependencies
- ✅ Verify the installation

## Prerequisites

The setup script checks for these requirements:

### Required
- **Operating System**: Linux, macOS, or Windows (with Git Bash/WSL)
- **Python**: 3.10 or higher (3.10.16 recommended)
- **Git**: Any recent version
- **uv**: Will be auto-installed if missing (on Linux/macOS)
- **Disk Space**: At least 10GB free

### Recommended (for GPU support)
- **CUDA**: 12.x or higher (for Linux systems)
- **NVIDIA GPU**: For accelerated inference

## Manual Setup

If you prefer manual setup or if the script fails:

### 1. Install uv

**Linux/macOS:**
```bash
curl -LsSf https://astral.sh/uv/install.sh | sh
```

**Windows:**
See https://docs.astral.sh/uv/getting-started/installation/

### 2. Create Virtual Environment

```bash
uv venv --python 3.10.16
```

### 3. Activate Virtual Environment

**Linux/macOS:**
```bash
source .venv/bin/activate
```

**Windows:**
```bash
.venv\Scripts\activate
```

### 4. Install Dependencies

Using requirements.txt (traditional method):
```bash
uv pip install -r requirements.txt
```

Or using pyproject.toml (recommended):
```bash
uv sync
```

### 5. Initialize Git Submodules

```bash
git submodule update --init --recursive
```

## Usage After Setup

### Activate the Environment

**Linux/macOS:**
```bash
source .venv/bin/activate
```

**Windows:**
```bash
.venv\Scripts\activate
```

### Run the Web UI

```bash
python webui.py
```

### Run API Server

```bash
python -m uvicorn your_api:app --reload
```

## Troubleshooting

### CUDA Not Detected

If you have a GPU but CUDA is not detected:
1. Install CUDA Toolkit 12.x: https://developer.nvidia.com/cuda-downloads
2. Verify installation: `nvcc --version`
3. Re-run the setup script

### Python Version Issues

If your system Python is too old:
1. Install Python 3.10+ using [pyenv](https://github.com/pyenv/pyenv) or from [python.org](https://www.python.org/downloads/)
2. Update the Python path and re-run setup

### Disk Space Issues

The installation requires significant space for:
- PyTorch and dependencies (~5-8GB)
- Model weights (varies by model, can be 10GB+)

Free up space or use a different installation directory.

### Network Issues

If dependency downloads fail:
1. Check your internet connection
2. Try using a different network or VPN
3. Consider using a PyPI mirror if you're in a region with slow access

### uv Installation Fails

On Windows, install uv manually:
```powershell
powershell -c "irm https://astral.sh/uv/install.ps1 | iex"
```

## Using uv for Package Management

### Add a new dependency
```bash
uv pip install package-name
```

### Update dependencies
```bash
uv pip install --upgrade package-name
```

### List installed packages
```bash
uv pip list
```

### Sync dependencies from pyproject.toml
```bash
uv sync
```

## Environment Variables

The setup script creates a `.env` template file. Edit it to customize:

- `MODEL_CACHE_DIR`: Directory for cached models
- `API_HOST`: API server host (default: 0.0.0.0)
- `API_PORT`: API server port (default: 8000)
- `LOG_LEVEL`: Logging verbosity (DEBUG, INFO, WARNING, ERROR)

## Next Steps

1. Read the [README.md](README.md) for project overview
2. Check [examples/](examples/) for usage examples
3. See [FAQ.md](FAQ.md) for common questions
4. Visit the demos:
   - [CosyVoice 3.0 Demos](https://funaudiollm.github.io/cosyvoice3/)
   - [CosyVoice 2.0 Demos](https://funaudiollm.github.io/cosyvoice2/)

## Support

If you encounter issues not covered here:
1. Check existing GitHub issues
2. Review the documentation
3. Open a new issue with:
   - Your OS and Python version
   - The complete error message
   - Steps to reproduce

## License

This project is licensed under the Apache License 2.0. See [LICENSE](LICENSE) for details.
