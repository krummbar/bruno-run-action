#!/bin/bash
dry_run="${BRUNO_ACTION_DRY_RUN}"

function print_input {
  echo "::debug::IN_CSV_FILEPATH='${IN_CSV_FILEPATH}'"
  echo "::debug::IN_PATH='${IN_PATH}'"
  echo "::debug::IN_FILENAME='${IN_FILENAME}'"
  echo "::debug::IN_IGNORE_TRUSTSTORE='${IN_IGNORE_TRUSTSTORE}'"
  echo "::debug::IN_RECURSIVE='${IN_RECURSIVE}'"
  echo "::debug::IN_ENV='${IN_ENV}'"
  echo "::debug::IN_ENV_VARS='${IN_ENV_VARS}'"
  echo "::debug::IN_OUTPUT='${IN_OUTPUT}'"
  echo "::debug::IN_OUTPUT_FORMAT='${IN_OUTPUT_FORMAT}'"
  echo "::debug::IN_CA_CERT='${IN_CA_CERT}'"
  echo "::debug::IN_INSECURE='${IN_INSECURE}'"
  echo "::debug::IN_SANDBOX='${IN_SANDBOX}'"
  echo "::debug::IN_TESTS_ONLY='${IN_TESTS_ONLY}'"
  echo "::debug::IN_BAIL='${IN_BAIL}'"
  echo "::debug::DRY_RUN='${dry_run}'"
}

# Exit script with status code and message
#
# $1 - Exit code
# $2 - Message to be dumped before exiting
function exit_with {
  prefix="::notice"
  if [[ "${1}" != "0" ]]; then
    prefix="::error"
  fi
  echo "${prefix}::$2"
  exit "$1"
}

# Takes absolute or relative paths and returns the absolute path value
# based on the current working directory.
#
# $1 - The path of the file that should be resolved as absolute path
#
# Examples (assuming pwd=/home/user/bruno-run-action)
#   absolute_path "out/bruno.log" => /home/user/bruno-run-action/out/bruno.log
#   absolute_path "/out/bruno.log" => /out/bruno.log
function absolute_path {
  input_path="${1}"
  origin_dir=$(pwd)
  cd "$(dirname "${input_path}")" &>/dev/null || exit_with 1 "The directory of the provided path '${input_path}' does not exist."
  out_abs_path=$(pwd)
  out_filename=$(basename "${input_path}")
  cd "${origin_dir}" || exit_with 1 "Something unexpected happened evaluating the absolute path of '${input_path}'."
  echo "${out_abs_path}/${out_filename}"
}

# Reads all action input parameters and converts them to bru CLI command arguments.
#
# Returns all CLI arguments as string
function parse_bru_args {
  output_args=""
  if [ -n "${IN_FILENAME}" ]; then
    output_args="${IN_FILENAME}"
  fi

  if [ -n "${IN_RECURSIVE}" ]; then
    output_args="${output_args} -r"
  fi

  if [ -n "${IN_ENV}" ]; then
    output_args="${output_args} --env ${IN_ENV}"
  fi

  if [ "${IN_IGNORE_TRUSTSTORE}" == "true" ]; then
    output_args="${output_args} --ignore-truststore"
  fi

  if [ -n "${IN_OUTPUT}" ]; then
    output_args="${output_args} --output $(absolute_path "${IN_OUTPUT}")"
  fi

  if [ -n "${IN_OUTPUT_FORMAT}" ]; then
    output_args="${output_args} --format ${IN_OUTPUT_FORMAT}"
  fi

  if [ -n "${IN_CA_CERT}" ]; then
    output_args="${output_args} --cacert ${IN_CA_CERT}"
  fi

  if [ "${IN_INSECURE}" == "true" ]; then
    output_args="${output_args} --insecure"
  fi

  if [ -n "${IN_SANDBOX}" ]; then
    output_args="${output_args} --sandbox ${IN_SANDBOX}"
  fi

  if [ "${IN_TESTS_ONLY}" == "true" ]; then
    output_args="${output_args} --tests-only"
  fi

  if [ "${IN_BAIL}" == "true" ]; then
    output_args="${output_args} --bail"
  fi

  if [ -n "${IN_CSV_FILEPATH}" ]; then
    output_args="${output_args} --csv-file-path $(absolute_path "${IN_CSV_FILEPATH}")"
  fi

  # Assign --env-var key=value if provided
  # Key value pairs must be separated by line breaks
  if [ -n "${IN_ENV_VARS}" ]; then
    while read -r env_var; do
      output_args="${output_args} --env-var ${env_var}"
    done < <(echo -e "${IN_ENV_VARS}")
  fi
  echo "${output_args}"
}

# Main function executing the bru CLI
#
# Exits with 0 if `bru run ...` was successful.
# Otherwise returns the exit code of the `bru run ...` command.
function main {
  print_input
  bru_version="$(bru --version)"
  echo "::notice::bru version: ${bru_version}"
  echo "bru-version='${bru_version}'" >>"${GITHUB_OUTPUT}"
  bru_args="$(parse_bru_args)"

  # Change to provided working directory
  if [ -n "${IN_PATH}" ]; then
    cd "${IN_PATH}" || exit_with 1 "The provided bruno collection path '${IN_PATH}' does not exist."
  fi

  # Dump current working directory
  echo "::notice::collection directory: '$(pwd)'"

  # Only dump command if DRY_RUN is enabled and exit
  if [ "${dry_run}" = true ]; then
    echo "::notice::bru run ${bru_args}"
    exit_with 0 "Executed in dry mode, skipped executing bruno collection."
  fi

  # Execute 'bru run ...' and evaluate execution status
  if eval "bru run ${bru_args}"; then
    # Write outputs to the $GITHUB_OUTPUT file
    echo "success=true" >>"${GITHUB_OUTPUT}"
    exit_with 0 "bru run succeeded."
  else
    bru_exit_code=$?
    # Write outputs to warning $GITHUB_OUTPUT file
    echo "success=false" >>"${GITHUB_OUTPUT}"
    exit_with ${bru_exit_code} "bru run failed failed with status: ${bru_exit_code}."
  fi
}

main
