#!/usr/bin/env bash

USER_SUFFIX="$(id -u -n)"

text_red=$(tput setaf 1)   # Red
text_green=$(tput setaf 2) # Green
text_bold=$(tput bold)     # Bold
text_reset=$(tput sgr0)    # Reset your text

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

function get_args_after_double_dash {
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

function compute_coverage {
  replayer=$1
  testcases=$(eval "$2")
  step=$3
  covfile=$4

  # delete the existing coverage file
  rm $covfile || true
  touch $covfile

  # clear gcov data
  gcovr -r . -s -d >/dev/null 2>&1

  # output the header of the coverage file which is in the CSV format
  # Time: timestamp, l_per/b_per and l_abs/b_abs: line/branch coverage in percentage and absolutate number
  echo "Time,l_per,l_abs,b_per,b_abs" >>$covfile

  # process other testcases
  count=0
  for f in $testcases; do
    time=$(stat -c %Y $f)

    "$replayer" "$f" >/dev/null 2>&1 || true

    count=$(expr $count + 1)
    rem=$(expr $count % $step)
    if [ "$rem" != "0" ]; then continue; fi
    cov_data=$(gcovr -r . -s | grep "[lb][a-z]*:")
    l_per=$(echo "$cov_data" | grep lines | cut -d" " -f2 | rev | cut -c2- | rev)
    l_abs=$(echo "$cov_data" | grep lines | cut -d" " -f3 | cut -c2-)
    b_per=$(echo "$cov_data" | grep branch | cut -d" " -f2 | rev | cut -c2- | rev)
    b_abs=$(echo "$cov_data" | grep branch | cut -d" " -f3 | cut -c2-)

    echo "$time,$l_per,$l_abs,$b_per,$b_abs" >>$covfile
  done

  # output cov data for the last testcase(s) if step > 1
  if [[ $step -gt 1 ]]; then
    time=$(stat -c %Y $f)
    cov_data=$(gcovr -r . -s | grep "[lb][a-z]*:")
    l_per=$(echo "$cov_data" | grep lines | cut -d" " -f2 | rev | cut -c2- | rev)
    l_abs=$(echo "$cov_data" | grep lines | cut -d" " -f3 | cut -c2-)
    b_per=$(echo "$cov_data" | grep branch | cut -d" " -f2 | rev | cut -c2- | rev)
    b_abs=$(echo "$cov_data" | grep branch | cut -d" " -f3 | cut -c2-)

    echo "$time,$l_per,$l_abs,$b_per,$b_abs" >>$covfile
  fi
}
