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
    if [[ -z $1 ]]; then
      echo ""
      return
    fi
    shift
  done

  shift

  while [[ -n "$1" ]]; do
    args+=("$1")
    shift
  done

  echo -n "${args[@]}"
}

function get_args_before_double_dash() {
    # 初始化一个空数组来存储参数
    local args=()
    
    # 遍历所有参数
    while [[ $# -gt 0 ]]; do
        if [[ $1 == "--" ]]; then
            # 遇到 -- 时，停止遍历
            break
        fi
        if [[ -z $1 ]]; then
          echo ""
          return
        fi
        # 将参数添加到数组中
        args+=("$1")
        # 移动到下一个参数
        shift
    done
    
    # 打印参数列表
    echo -n "${args[@]}"
}
