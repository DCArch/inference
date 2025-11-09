#!/bin/bash
set -e  # Exit on error

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INFERENCE_DIR="${SCRIPT_DIR}"

echo "======================================================================"
echo "MLPerf Inference Benchmark Download Script"
echo "======================================================================"
echo ""

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

# Create completion marker
touch "${INFERENCE_DIR}/.mlperf_downloads_complete"

echo "======================================================================"
echo "MLPerf downloads complete!"
echo "======================================================================"
echo ""
echo "Summary:"
echo "  - LLaMA2-70B:          ${INFERENCE_DIR}/language/llama2-70b/"
echo "  - Mixtral-8x7B:        ${INFERENCE_DIR}/language/mixtral-8x7b/"
echo "  - DLRM-v2:             ${INFERENCE_DIR}/recommendation/dlrm_v2/pytorch/"
echo "  - Stable Diffusion XL: ${INFERENCE_DIR}/text_to_image/"
echo "  - DCSim hooks:         ${INFERENCE_DIR}/dcsim_hooks/"
echo ""
echo "Total downloaded: ~300GB"
echo ""
