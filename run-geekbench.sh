#!/usr/bin/env bash
# Download Geekbench for Linux, run the CPU benchmark, and print the
# Geekbench Browser links for the uploaded result.
#
# Usage: ./run-geekbench.sh
#
# Environment:
#   GB_VERSION   Geekbench version to run (default: 7.1.0)
#   GB_WORKDIR   where the download and logs go (default: ./.geekbench)
#   GB_TRACE=1   log the hosts Geekbench connects to (needs strace)

set -euo pipefail

GB_VERSION="${GB_VERSION:-7.1.0}"
GB_WORKDIR="${GB_WORKDIR:-$(cd "$(dirname "$0")" && pwd)/.geekbench}"
case "$(uname -m)" in
  x86_64)  GB_PLATFORM=Linux ;;
  aarch64) GB_PLATFORM=LinuxARMPreview ;;
  *) echo "Unsupported architecture: $(uname -m)" >&2; exit 1 ;;
esac

GB_NAME="Geekbench-${GB_VERSION}-${GB_PLATFORM}"
GB_URL="https://cdn.geekbench.com/${GB_NAME}.tar.gz"
GB_DIR="${GB_WORKDIR}/${GB_NAME}"
GB_BIN="${GB_DIR}/geekbench${GB_VERSION%%.*}"

mkdir -p "$GB_WORKDIR"

if [[ ! -x "$GB_BIN" ]]; then
  echo "Downloading ${GB_URL}"
  curl -fSL --retry 4 -o "${GB_WORKDIR}/${GB_NAME}.tar.gz" "$GB_URL"
  tar -xzf "${GB_WORKDIR}/${GB_NAME}.tar.gz" -C "$GB_WORKDIR"
  rm -f "${GB_WORKDIR}/${GB_NAME}.tar.gz"
fi

log="${GB_WORKDIR}/geekbench-$(date -u +%Y%m%dT%H%M%SZ).log"
echo "Running Geekbench ${GB_VERSION} CPU benchmark (log: ${log})"

cmd=("$GB_BIN" --cpu)
if [[ "${GB_TRACE:-0}" == 1 ]]; then
  # HTTPS through a proxy starts with a plaintext "CONNECT host:port" line,
  # so tracing writes is enough to see which hosts the upload talks to.
  cmd=(strace -f -qq --seccomp-bpf -s 256 -e trace=write,sendto -o "${log%.log}.strace" "${cmd[@]}")
fi

"${cmd[@]}" 2>&1 | tee "$log"

if [[ "${GB_TRACE:-0}" == 1 ]]; then
  echo
  echo "Hosts contacted:"
  grep -oE 'CONNECT [^ ]+' "${log%.log}.strace" | sort | uniq -c || echo "  (none seen)"
fi

result_url="$(grep -oE 'https://browser\.geekbench\.com/v[0-9]+/cpu/[0-9]+' "$log" | head -n1 || true)"
claim_url="$(grep -oE 'https://browser\.geekbench\.com/v[0-9]+/cpu/[0-9]+/claim\?key=[0-9]+' "$log" | head -n1 || true)"
single="$(awk '/Single-Core Score/ {print $NF}' "$log")"
multi="$(awk '/Multi-Core Score/ {print $NF}' "$log")"

echo
echo "Single-Core: ${single:-?}"
echo "Multi-Core:  ${multi:-?}"
if [[ -z "$result_url" ]]; then
  echo "No result URL found; the upload probably failed. See ${log}" >&2
  exit 1
fi
echo "Result:      ${result_url}"
echo "Claim:       ${claim_url:-?}"
