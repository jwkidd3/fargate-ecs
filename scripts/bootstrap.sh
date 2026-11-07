#!/usr/bin/env bash
#
# bootstrap.sh — Prepare a Cloud9 environment for the AWS ECS Fargate course.
#
#   1. Grows the root EBS volume to 100 GB (default) and expands the filesystem
#   2. Installs Terraform, AWS CLI v2, Docker, jq, git, tree
#   3. Enables Terraform shell completion
#   4. Prints a verification summary
#
# Usage:
#   ./scripts/bootstrap.sh          # resize to 100 GB
#   ./scripts/bootstrap.sh 50       # resize to 50 GB
#   SKIP_RESIZE=1 ./scripts/bootstrap.sh
#
# Safe to re-run: every step checks current state before changing anything.

set -uo pipefail

TARGET_GB="${1:-100}"
IMDS="http://169.254.169.254"

RED=$'\033[0;31m'; GREEN=$'\033[0;32m'; YELLOW=$'\033[0;33m'; BLUE=$'\033[0;34m'; BOLD=$'\033[1m'; NC=$'\033[0m'

step()  { printf '\n%s==> %s%s\n' "${BLUE}${BOLD}" "$*" "$NC"; }
ok()    { printf '%s  [ ok ]%s %s\n'   "$GREEN"  "$NC" "$*"; }
warn()  { printf '%s  [warn]%s %s\n'   "$YELLOW" "$NC" "$*"; }
fail()  { printf '%s  [fail]%s %s\n'   "$RED"    "$NC" "$*"; }

WARNINGS=0
note_warn() { warn "$*"; WARNINGS=$((WARNINGS + 1)); }

# ---------------------------------------------------------------------------
# Detect the package manager
# ---------------------------------------------------------------------------
if command -v dnf >/dev/null 2>&1; then
    PKG=dnf
    PKG_PLUGINS=dnf-plugins-core
else
    PKG=yum
    PKG_PLUGINS=yum-utils
fi

# ---------------------------------------------------------------------------
# 1. Grow the root EBS volume
# ---------------------------------------------------------------------------
resize_disk() {
    if [[ -n "${SKIP_RESIZE:-}" ]]; then
        warn "SKIP_RESIZE set — leaving disk size alone"
        return 0
    fi

    local token imds_args instance_id region volume_id current_gb

    # IMDSv2 token; fall back to IMDSv1 if the PUT is refused.
    token=$(curl -sf -X PUT "${IMDS}/latest/api/token" \
        -H "X-aws-ec2-metadata-token-ttl-seconds: 21600" --max-time 5 2>/dev/null || true)
    if [[ -n "$token" ]]; then
        imds_args=(-H "X-aws-ec2-metadata-token: $token")
    else
        imds_args=()
    fi

    instance_id=$(curl -sf --max-time 5 "${imds_args[@]}" "${IMDS}/latest/meta-data/instance-id" 2>/dev/null || true)
    region=$(curl -sf --max-time 5 "${imds_args[@]}" "${IMDS}/latest/meta-data/placement/region" 2>/dev/null || true)

    if [[ -z "$instance_id" || -z "$region" ]]; then
        note_warn "Could not read EC2 instance metadata — skipping resize."
        note_warn "This is expected if you are not on an EC2-backed Cloud9 environment."
        return 0
    fi
    ok "Instance $instance_id in $region"

    volume_id=$(aws ec2 describe-instances --region "$region" \
        --instance-ids "$instance_id" \
        --query 'Reservations[0].Instances[0].BlockDeviceMappings[0].Ebs.VolumeId' \
        --output text 2>/dev/null)

    if [[ -z "$volume_id" || "$volume_id" == "None" ]]; then
        note_warn "Could not find the root EBS volume. Does this environment have"
        note_warn "permission to call ec2:DescribeInstances? Skipping resize."
        return 0
    fi

    current_gb=$(aws ec2 describe-volumes --region "$region" \
        --volume-ids "$volume_id" --query 'Volumes[0].Size' --output text 2>/dev/null)
    ok "Root volume $volume_id is currently ${current_gb} GB"

    if [[ "$current_gb" -ge "$TARGET_GB" ]]; then
        ok "Already at least ${TARGET_GB} GB — no EBS change needed"
    else
        step "Growing EBS volume to ${TARGET_GB} GB"
        if ! aws ec2 modify-volume --region "$region" \
             --volume-id "$volume_id" --size "$TARGET_GB" >/dev/null 2>&1; then
            note_warn "ec2:ModifyVolume failed. Either this environment lacks the"
            note_warn "permission, or the volume was modified in the last 6 hours."
            note_warn "Continuing with tool installation."
            return 0
        fi

        printf '  waiting for the volume modification to be applied'
        local waited=0 state=""
        while [[ $waited -lt 300 ]]; do
            state=$(aws ec2 describe-volumes-modifications --region "$region" \
                --volume-ids "$volume_id" \
                --query 'VolumesModifications[0].ModificationState' \
                --output text 2>/dev/null)
            [[ "$state" == "optimizing" || "$state" == "completed" ]] && break
            printf '.'; sleep 5; waited=$((waited + 5))
        done
        printf '\n'
        if [[ "$state" != "optimizing" && "$state" != "completed" ]]; then
            note_warn "Volume modification did not reach 'optimizing' within 5 minutes (state: ${state:-unknown})."
            note_warn "The filesystem grow below may not pick up the new size."
        else
            ok "EBS volume is now ${TARGET_GB} GB (state: $state)"
        fi
    fi

    # --- Grow the partition and filesystem to match the volume ---
    step "Expanding the partition and filesystem"

    sudo "$PKG" install -y cloud-utils-growpart >/dev/null 2>&1 || true

    local part disk partnum fstype
    part=$(findmnt -no SOURCE /)
    if [[ -z "$part" ]]; then
        note_warn "Could not determine the root device — skipping filesystem grow"
        return 0
    fi

    disk="/dev/$(lsblk -no pkname "$part" 2>/dev/null | head -n1 | tr -d ' ')"
    partnum=$(printf '%s' "$part" | grep -oE '[0-9]+$')

    if [[ "$disk" == "/dev/" || -z "$partnum" ]]; then
        note_warn "Root device $part is not a recognised partition — skipping grow"
        return 0
    fi

    if sudo growpart "$disk" "$partnum" >/dev/null 2>&1; then
        ok "Partition $part grown to fill $disk"
    else
        ok "Partition already uses the whole disk"
    fi

    fstype=$(findmnt -no FSTYPE /)
    case "$fstype" in
        xfs)
            sudo xfs_growfs -d / >/dev/null 2>&1 && ok "xfs filesystem expanded" \
                || note_warn "xfs_growfs reported no change"
            ;;
        ext2|ext3|ext4)
            sudo resize2fs "$part" >/dev/null 2>&1 && ok "$fstype filesystem expanded" \
                || note_warn "resize2fs reported no change"
            ;;
        *)
            note_warn "Unrecognised root filesystem '$fstype' — grow it manually"
            ;;
    esac
}

# ---------------------------------------------------------------------------
# 2. Install the course tools
# ---------------------------------------------------------------------------
install_terraform() {
    if command -v terraform >/dev/null 2>&1; then
        ok "Terraform already installed ($(terraform version | head -n1))"
        return 0
    fi
    sudo "$PKG" install -y "$PKG_PLUGINS" >/dev/null 2>&1
    sudo "$PKG"-config-manager --add-repo \
        https://rpm.releases.hashicorp.com/AmazonLinux/hashicorp.repo >/dev/null 2>&1 \
        || sudo "$PKG" config-manager --add-repo \
           https://rpm.releases.hashicorp.com/AmazonLinux/hashicorp.repo >/dev/null 2>&1
    if sudo "$PKG" install -y terraform >/dev/null 2>&1; then
        hash -r
        ok "Terraform installed ($(terraform version | head -n1))"
    else
        fail "Terraform install failed — see Lab 3 troubleshooting"
        WARNINGS=$((WARNINGS + 1))
    fi
}

install_awscli_v2() {
    if aws --version 2>&1 | grep -q 'aws-cli/2'; then
        ok "AWS CLI v2 already installed ($(aws --version 2>&1))"
        return 0
    fi
    local tmp
    tmp=$(mktemp -d)
    if curl -sf -o "$tmp/awscliv2.zip" \
         "https://awscli.amazonaws.com/awscli-exe-linux-$(uname -m).zip" \
       && unzip -q "$tmp/awscliv2.zip" -d "$tmp" \
       && sudo "$tmp/aws/install" --update >/dev/null 2>&1; then
        hash -r
        ok "AWS CLI v2 installed ($(aws --version 2>&1))"
    else
        note_warn "AWS CLI v2 install failed; the preinstalled CLI will be used."
        note_warn "The ECR bonus lab needs v2 for 'aws ecr get-login-password'."
    fi
    rm -rf "$tmp"
}

install_packages() {
    local pkgs=(jq tree git unzip)
    local missing=()
    for p in "${pkgs[@]}"; do
        command -v "$p" >/dev/null 2>&1 || missing+=("$p")
    done
    if [[ ${#missing[@]} -eq 0 ]]; then
        ok "jq, tree, git, unzip already present"
    else
        sudo "$PKG" install -y "${missing[@]}" >/dev/null 2>&1 \
            && ok "Installed: ${missing[*]}" \
            || note_warn "Could not install: ${missing[*]}"
    fi
}

setup_docker() {
    if ! command -v docker >/dev/null 2>&1; then
        sudo "$PKG" install -y docker >/dev/null 2>&1 || {
            note_warn "Docker install failed (only the ECR bonus lab needs it)"
            return 0
        }
    fi
    sudo systemctl enable --now docker >/dev/null 2>&1 || true
    sudo usermod -aG docker "$USER" >/dev/null 2>&1 || true
    if docker info >/dev/null 2>&1; then
        ok "Docker running ($(docker --version))"
    else
        ok "Docker installed ($(docker --version 2>/dev/null || echo 'version unknown'))"
        warn "Run 'newgrp docker' or reopen the terminal to use docker without sudo"
    fi
}

setup_completion() {
    if ! command -v terraform >/dev/null 2>&1; then
        return 0
    fi
    if ! grep -q 'complete -C .*terraform' ~/.bashrc 2>/dev/null; then
        terraform -install-autocomplete 2>/dev/null \
            && ok "Terraform tab completion enabled (new shells)" \
            || warn "Could not enable Terraform completion"
    else
        ok "Terraform tab completion already enabled"
    fi
}

# ---------------------------------------------------------------------------
# 3. Verification summary
# ---------------------------------------------------------------------------
verify() {
    local disk_avail region ident
    disk_avail=$(df -h / | awk 'NR==2 {print $2 " total, " $4 " free"}')

    printf '\n%s%s\n' "$BOLD" "──────────────────────────────────────────────────────────"
    printf '  Environment summary\n'
    printf '──────────────────────────────────────────────────────────%s\n' "$NC"
    printf '  %-16s %s\n' "OS"        "$(. /etc/os-release && echo "$PRETTY_NAME")"
    printf '  %-16s %s\n' "Disk (/)"  "$disk_avail"
    printf '  %-16s %s\n' "Terraform" "$(terraform version 2>/dev/null | head -n1 || echo 'NOT INSTALLED')"
    printf '  %-16s %s\n' "AWS CLI"   "$(aws --version 2>&1 || echo 'NOT INSTALLED')"
    printf '  %-16s %s\n' "Docker"    "$(docker --version 2>/dev/null || echo 'not installed')"
    printf '  %-16s %s\n' "jq"        "$(jq --version 2>/dev/null || echo 'not installed')"

    region=$(aws configure get region 2>/dev/null || true)
    [[ -z "$region" ]] && region="${AWS_DEFAULT_REGION:-${AWS_REGION:-}}"
    printf '  %-16s %s\n' "AWS region" "${region:-not set}"

    if ident=$(aws sts get-caller-identity --query Arn --output text 2>/dev/null); then
        printf '  %-16s %s\n' "AWS identity" "$ident"
    else
        printf '  %-16s %s\n' "AWS identity" "COULD NOT AUTHENTICATE"
        note_warn "aws sts get-caller-identity failed — check AWS credentials before Lab 4"
    fi
    printf '%s──────────────────────────────────────────────────────────%s\n' "$BOLD" "$NC"
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
main() {
    printf '%s\n' "${BOLD}AWS ECS Fargate course — environment bootstrap${NC}"
    printf 'Target disk size: %s GB\n' "$TARGET_GB"

    if ! command -v aws >/dev/null 2>&1; then
        fail "The AWS CLI was not found. Run this inside an AWS Cloud9 terminal."
        exit 1
    fi

    step "Checking and growing the root disk"
    resize_disk

    step "Installing Terraform"
    install_terraform

    step "Installing AWS CLI v2"
    install_awscli_v2

    step "Installing jq, tree, git, unzip"
    install_packages

    step "Setting up Docker"
    setup_docker

    step "Enabling Terraform tab completion"
    setup_completion

    verify

    if [[ $WARNINGS -eq 0 ]]; then
        printf '\n%sBootstrap complete. You are ready for Lab 3, Exercise 3.3.%s\n\n' "${GREEN}${BOLD}" "$NC"
    else
        printf '\n%sBootstrap finished with %d warning(s) above.%s\n' "${YELLOW}${BOLD}" "$WARNINGS" "$NC"
        printf 'Show your instructor the warnings before continuing.\n\n'
    fi
}

main "$@"
