#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat >&2 <<'EOF'
Usage:
  REMOTE_PASS=... scripts/remote-run.sh <target> <command...>
  REMOTE_PASS=... scripts/remote-run.sh <target> < script.sh

Targets:
  autodl  root@connect.westb.seetacloud.com:42894
  idc     root@connect.westc.seetacloud.com:13401

Environment overrides:
  REMOTE_HOST, REMOTE_PORT, REMOTE_USER, REMOTE_PASS
EOF
}

if [[ $# -lt 1 ]]; then
  usage
  exit 2
fi

target="$1"
shift

case "$target" in
  autodl)
    default_host="connect.westb.seetacloud.com"
    default_port="42894"
    default_user="root"
    ;;
  idc)
    default_host="connect.westc.seetacloud.com"
    default_port="13401"
    default_user="root"
    ;;
  *)
    if [[ -z "${REMOTE_HOST:-}" ]]; then
      echo "Unknown target '$target'. Set REMOTE_HOST/REMOTE_PORT/REMOTE_USER or use a known target." >&2
      usage
      exit 2
    fi
    default_host="${REMOTE_HOST}"
    default_port="${REMOTE_PORT:-22}"
    default_user="${REMOTE_USER:-root}"
    ;;
esac

host="${REMOTE_HOST:-$default_host}"
port="${REMOTE_PORT:-$default_port}"
user="${REMOTE_USER:-$default_user}"

if [[ -z "${REMOTE_PASS:-}" ]]; then
  echo "REMOTE_PASS is required." >&2
  exit 2
fi

if ! command -v expect >/dev/null 2>&1; then
  echo "expect is required. Install it first, or run ssh manually." >&2
  exit 2
fi

tmp_cmd=""
cleanup() {
  [[ -n "$tmp_cmd" && -f "$tmp_cmd" ]] && rm -f "$tmp_cmd"
}
trap cleanup EXIT

if [[ $# -gt 0 ]]; then
  remote_cmd="$*"
else
  tmp_cmd="$(mktemp)"
  cat > "$tmp_cmd"
  remote_cmd="bash -s"
fi

export RR_HOST="$host" RR_PORT="$port" RR_USER="$user" RR_PASS="$REMOTE_PASS" RR_CMD="$remote_cmd" RR_STDIN_FILE="$tmp_cmd"

expect <<'EOF'
set timeout -1
set host $env(RR_HOST)
set port $env(RR_PORT)
set user $env(RR_USER)
set pass $env(RR_PASS)
set cmd  $env(RR_CMD)
set stdin_file $env(RR_STDIN_FILE)

proc send_stdin_if_needed {} {
  global stdin_file
  if {$stdin_file ne ""} {
    set fh [open $stdin_file r]
    set body [read $fh]
    close $fh
    log_user 0
    send -- $body
    send -- "\nexit\n"
    log_user 1
    set stdin_file ""
  }
}

spawn ssh -T -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -p $port $user@$host $cmd

if {$stdin_file ne ""} {
  set timeout 10
  expect {
    -re "(?i)password:" {
      send -- "$pass\r"
      send_stdin_if_needed
    }
    -re "(?i)permission denied" {
      exit 255
    }
    timeout {
      send_stdin_if_needed
    }
    eof {
      catch wait result
      exit [lindex $result 3]
    }
  }
  set timeout -1
  expect {
    eof {
      catch wait result
      exit [lindex $result 3]
    }
  }
}

expect {
  -re "(?i)password:" {
    send -- "$pass\r"
    exp_continue
  }
  -re "(?i)permission denied" {
    exit 255
  }
  -re "(?i)warning: permanently added" {
    exp_continue
  }
  eof {
    catch wait result
    exit [lindex $result 3]
  }
}
EOF
