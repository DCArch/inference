#!/bin/bash
set -e  # Exit on error

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INFERENCE_DIR="${SCRIPT_DIR}"

echo "======================================================================"
echo "MLPerf Inference Benchmark Setup Script"
echo "======================================================================"
echo ""

# ==============================================================================
# Python Virtual Environment Setup
# ==============================================================================
echo "======================================================================"
echo "Setting up Python virtual environment..."
echo "======================================================================"

# 1. Fresh venv setup
rm -rf ~/mlperf_venv
python3 -m venv ~/mlperf_venv
source ~/mlperf_venv/bin/activate

# 2. Create empty pip config to override Compute Canada's
cat > ~/mlperf_venv/pip.conf << 'EOF'
[global]
find-links = 
disable-pip-version-check = false

[install]
find-links = 
constraint = 
only-binary = 
prefer-binary = false
EOF

# 3. Set config and add to activate script for persistence
export PIP_CONFIG_FILE=~/mlperf_venv/pip.conf
echo 'export PIP_CONFIG_FILE=~/mlperf_venv/pip.conf' >> ~/mlperf_venv/bin/activate

# 4. Verify clean config
pip config list

# 5. Upgrade pip and install wheel first
pip install --upgrade pip wheel setuptools

# 6. PyTorch ecosystem (CPU)
echo "Installing PyTorch (CPU)..."
pip install torch==2.2.0+cpu torchvision==0.17.0+cpu torchaudio==2.2.0+cpu --extra-index-url https://download.pytorch.org/whl/cpu

# 7. DLRM dependencies - download, rename, and install fbgemm_gpu wheel
echo "Installing DLRM dependencies..."
cd /tmp
wget -q https://download.pytorch.org/whl/cpu/fbgemm_gpu-0.6.0%2Bcpu-cp311-cp311-manylinux2014_x86_64.whl
mv fbgemm_gpu-0.6.0+cpu-cp311-cp311-manylinux2014_x86_64.whl fbgemm_gpu-0.6.0+cpu-cp311-cp311-linux_x86_64.whl
pip install fbgemm_gpu-0.6.0+cpu-cp311-cp311-linux_x86_64.whl
rm -f fbgemm_gpu-0.6.0+cpu-cp311-cp311-linux_x86_64.whl
cd -

pip install torchrec==0.6.0 torchsnapshot

# 8. Common ML dependencies
echo "Installing common ML dependencies..."
pip install numpy scipy pybind11 pydot torchviz protobuf tqdm
pip install scikit-learn

# 9. Hugging Face stack
echo "Installing Hugging Face stack..."
pip install transformers==4.31.0 accelerate==0.21.0 sentencepiece==0.1.99

# 10. NLP evaluation tools (LLaMA2/Mixtral)
echo "Installing NLP evaluation tools..."
pip install nltk==3.8.1 evaluate==0.4.0 absl-py==1.4.0 rouge-score==0.1.2

# 11. Stable Diffusion specific
echo "Installing Stable Diffusion dependencies..."
pip install diffusers==0.30.3 open-clip-torch==2.26.1 opencv-python==4.10.0.84 pycocotools==2.0.7 "torchmetrics[image]==1.4.3"

# 12. Mixtral specific
echo "Installing Mixtral dependencies..."
pip install git+https://github.com/amazon-science/mxeval.git@e09974f990eeaf0c0e8f2b5eaff4be66effb2c86

echo "✓ Python environment setup complete"
echo ""

# ==============================================================================
# Download Models and Datasets
# ==============================================================================

# Check if rclone is installed
if ! command -v rclone &> /dev/null; then
    echo "ERROR: rclone is not installed."
    echo ""
    echo "Please install rclone using one of the following commands:"
    echo ""
    echo "Official installer:"
    echo "  curl https://rclone.org/install.sh | sudo bash"
    echo ""
    echo "Ubuntu/Debian:"
    echo "  sudo apt install rclone"
    echo ""
    echo "CentOS/RHEL:"
    echo "  sudo dnf install rclone"
    echo ""
    exit 1
fi

echo "✓ rclone found"
echo ""

# Configure rclone for MLCommons public bucket (if not already configured)
if ! rclone listremotes | grep -q "mlc-inference:"; then
    echo "Configuring rclone for MLCommons public bucket..."
    rclone config create mlc-inference s3 \
        provider Cloudflare \
        access_key_id f65ba5eef400db161ea49967de89f47b \
        secret_access_key fbea333914c292b854f14d3fe232bad6c5407bf0ab1bebf78833c2b359bdfd2b \
        endpoint https://c2686074cb2caf5cbaf6d134bdba8b47.r2.cloudflarestorage.com
    echo "✓ rclone configured"
else
    echo "✓ rclone already configured for mlc-inference"
fi
echo ""

# Download LLaMA2-70B model (~130GB) and dataset (~10GB)
echo "======================================================================"
echo "1/4: Downloading LLaMA2-70B model and dataset..."
echo "======================================================================"
mkdir -p "${INFERENCE_DIR}/language/llama2-70b/model"
mkdir -p "${INFERENCE_DIR}/language/llama2-70b/dataset"
rclone copy mlc-inference:mlcommons-inference-wg-public/llama2-70b \
    "${INFERENCE_DIR}/language/llama2-70b/model" -P --ignore-existing
rclone copy mlc-inference:mlcommons-inference-wg-public/open_orca \
    "${INFERENCE_DIR}/language/llama2-70b/dataset" -P --ignore-existing
echo "✓ LLaMA2-70B complete"
echo ""

# Download Mixtral-8x7B model (~90GB) and dataset (~10GB)
echo "======================================================================"
echo "2/4: Downloading Mixtral-8x7B model and dataset..."
echo "======================================================================"
mkdir -p "${INFERENCE_DIR}/language/mixtral-8x7b/model"
mkdir -p "${INFERENCE_DIR}/language/mixtral-8x7b/dataset"
rclone copy mlc-inference:mlcommons-inference-wg-public/mixtral_8x7b/mixtral-8x7b-instruct-v0.1 \
    "${INFERENCE_DIR}/language/mixtral-8x7b/model" -P --ignore-existing
rclone copy mlc-inference:mlcommons-inference-wg-public/open_orca \
    "${INFERENCE_DIR}/language/mixtral-8x7b/dataset" -P --ignore-existing
echo "✓ Mixtral-8x7B complete"
echo ""

# Download DLRM-v2 model (~97GB) and dataset (~20-30GB)
echo "======================================================================"
echo "3/4: Downloading DLRM-v2 model and dataset..."
echo "======================================================================"
mkdir -p "${INFERENCE_DIR}/recommendation/dlrm_v2/pytorch/model"
mkdir -p "${INFERENCE_DIR}/recommendation/dlrm_v2/pytorch/dataset"
rclone copy mlc-inference:mlcommons-inference-wg-public/model_weights \
    "${INFERENCE_DIR}/recommendation/dlrm_v2/pytorch/model" -P --ignore-existing
rclone copy mlc-inference:mlcommons-inference-wg-public/dlrm_preprocessed \
    "${INFERENCE_DIR}/recommendation/dlrm_v2/pytorch/dataset" -P --ignore-existing
echo "✓ DLRM-v2 complete"
echo ""

# Download Stable Diffusion XL model (~13GB) and dataset (~13GB)
echo "======================================================================"
echo "4/4: Downloading Stable Diffusion XL model and dataset..."
echo "======================================================================"
mkdir -p "${INFERENCE_DIR}/text_to_image/model"
mkdir -p "${INFERENCE_DIR}/text_to_image/dataset"
rclone copy mlc-inference:mlcommons-inference-wg-public/stable_diffusion_fp16 \
    "${INFERENCE_DIR}/text_to_image/model" -P --ignore-existing

# Download COCO 2014 dataset using the provided script
echo "Downloading COCO 2014 dataset (5000 images)..."
cd "${INFERENCE_DIR}/text_to_image/tools"
bash download-coco-2014.sh -d "${INFERENCE_DIR}/text_to_image/dataset" -m 5000 -n 4
echo "✓ Stable Diffusion XL complete"
echo ""

# Build DCSim hooks
echo "======================================================================"
echo "Building DCSim hooks..."
echo "======================================================================"
if [ -d "${INFERENCE_DIR}/dcsim_hooks" ]; then
    echo "DCSim hooks directory already exists, rebuilding..."
    cd "${INFERENCE_DIR}/dcsim_hooks"
    make clean
    make
else
    echo "Copying DCSim hooks from Utils/SimHooks..."
    cp -r "${SCRIPT_DIR}/../../Utils/SimHooks" "${INFERENCE_DIR}/dcsim_hooks"
    cd "${INFERENCE_DIR}/dcsim_hooks"
    make
fi
echo "✓ DCSim hooks built successfully"
echo ""

# ==============================================================================
# Build Loadgen
# ==============================================================================
echo "======================================================================"
echo "Building loadgen..."
echo "======================================================================"
cd "${INFERENCE_DIR}/loadgen"
pip install .
echo "✓ Loadgen built successfully"
echo ""

# Create completion marker
touch "${INFERENCE_DIR}/.mlperf_downloads_complete"

echo "======================================================================"
echo "MLPerf setup complete!"
echo "======================================================================"
echo ""
echo "Summary:"
echo "  - Python venv:         ~/mlperf_venv/"
echo "  - LLaMA2-70B:          ${INFERENCE_DIR}/language/llama2-70b/"
echo "  - Mixtral-8x7B:        ${INFERENCE_DIR}/language/mixtral-8x7b/"
echo "  - DLRM-v2:             ${INFERENCE_DIR}/recommendation/dlrm_v2/pytorch/"
echo "  - Stable Diffusion XL: ${INFERENCE_DIR}/text_to_image/"
echo "  - DCSim hooks:         ${INFERENCE_DIR}/dcsim_hooks/"
echo ""
echo "To activate the environment: source ~/mlperf_venv/bin/activate"
echo ""
