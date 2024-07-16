#!/usr/bin/env bash

USER_SUFFIX="$(id -u -n)"

text_red=$(tput setaf 1)    # Red
text_green=$(tput setaf 2)  # Green
text_bold=$(tput bold)      # Bold
text_reset=$(tput sgr0)     # Reset your text

function log_error {
    echo "${text_bold}${text_red}${1}${text_reset}"
}

function log_success {
    echo "${text_bold}${text_green}${1}${text_reset}"
}

function use_prebuilt {
    if [[ ! -z "${!PREBUILT_ENV_VAR_NAME:-}" ]]; then
        return 0
    fi
    return 1
}

function get_arguments_after_double_dash {
  local args=()

  while [[ "$1" != "--" ]]; do
    shift
  done

  shift

  while [[ -n "$1" ]]; do
    args+=("$1")
    shift
  done

  echo "${args[@]}"
}
