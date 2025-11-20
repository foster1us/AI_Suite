#!/usr/bin/env bash
set -e

BASE_DIR=/workspace
APP_DIR="${BASE_DIR}/kohya_ss"
VENV_DIR="${BASE_DIR}/venvs/kohya_ss"

echo "KOHYA: Preparing kohya_ss in ${APP_DIR} with venv ${VENV_DIR}"

mkdir -p "${BASE_DIR}"
mkdir -p "$(dirname "${VENV_DIR}")"

# Clone or update repo
if [ ! -d "${APP_DIR}/.git" ]; then
  echo "KOHYA: Cloning kohya_ss..."
  git clone https://github.com/bmaltais/kohya_ss.git "${APP_DIR}"
else
  echo "KOHYA: Repo already exists, fetching updates..."
  cd "${APP_DIR}"
  git fetch --all || true
fi

cd "${APP_DIR}"

# Checkout desired version/tag/branch if provided
if [ -n "${KOHYA_VERSION}" ]; then
  echo "KOHYA: Checking out ${KOHYA_VERSION}"
  git checkout "${KOHYA_VERSION}"
fi

# Move any pre-baked requirements into the repo (if present)
# (keeps your original behavior but makes it non-fatal if files are missing)
mv /requirements* "${APP_DIR}/" 2>/dev/null || true

# Init/update submodules
git submodule update --init --recursive

# Create venv if needed
if [ ! -d "${VENV_DIR}" ]; then
  echo "KOHYA: Creating virtualenv..."
  python3 -m venv --system-site-packages "${VENV_DIR}"
fi

# Activate venv
# shellcheck source=/dev/null
source "${VENV_DIR}/bin/activate"

# Keep pip current enough
pip3 install --upgrade "pip>=24.0"

# Install torch and xformers
pip3 install --no-cache-dir \
  "torch==${KOHYA_TORCH_VERSION}" torchvision torchaudio \
  --index-url "${INDEX_URL}"

pip3 install --no-cache-dir \
  "xformers==${KOHYA_XFORMERS_VERSION}" \
  --index-url "${INDEX_URL}"

# Install requirements and clean up
if [ -f requirements_runpod.txt ]; then
  pip3 install -r requirements_runpod.txt
fi

if [ -f requirements.txt ]; then
  pip3 install -r requirements.txt
fi

pip3 cache purge || true
deactivate

echo "KOHYA: Installation finished."
