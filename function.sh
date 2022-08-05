#!/bin/bash
# shellcheck disable=SC3040
set -euo pipefail


function usage() {
    cat <<EOF 1>&2
Description:
    $(basename "${0}") is a tool that looks up client IPs in AWS WAF logs.
    The behavior of this tool is as follows.

    1. Run s3 cp to copy the WAF log to your working directory
    2. Search the log by URI
    3. Output the client IP of the corresponding log

    $(basename "${0}") は AWS WAF のログからクライアント IP を検索するツールです。
    このツールの挙動は以下の通りです。

    1. s3 cp を実行して、作業ディレクトリに WAF のログをコピーする
    2. ログに対して URI で検索する
    3. 該当したログのクライアント IP を出力する

Usage:
    $(basename "${0}") --profile PROFILE_NAME '{"path": "/path/to","uri": "/hoge"}'

Options:
    --help      print this.
                これを出力します。
EOF
}


while (( $# > 0 ))
do
    case $1 in
        --help)
            usage
            exit 1
            ;;
        --profile)
            if [[ -z "$2" ]] || [[ "$2" =~ ^-+ ]]; then
                echo "'option' requires an argument." 1>&2
                exit 2
            else
                PROFILE="${2}"
                echo "PROFILE:${PROFILE}"
                readonly PROFILE
                shift
            fi
            ;;
        -*)
            usage
            exit 1
            ;;
        *)
            EVENT_DATA="${1}"
            echo "EVENT_DATA:${EVENT_DATA}"
            readonly EVENT_DATA
            exit 1
            ;;
    esac
    shift
done

function to_params() {
    # params:'{"path": "/path/to","uri": "/hoge"}' => BUCKET_PATH=/path/to, URI=/hoge
    local -r cleaning=$(echo "${1}" | tr -d '{' | tr -d '}' | tr -d '"' | tr -d ' ')

    if echo "${cleaning}" | awk -F, '{print $1}' | grep -q "^path" ; then
        BUCKET_PATH=$(echo "${cleaning}" | awk -F, '{print $1}' | sed -e 's/^\([^:]*\):\(.*\)$/\2/')
        URI=$(echo "${cleaning}" | awk -F, '{print $2}' | sed -e 's/^\([^:]*\):\(.*\)$/\2/')
    else
        BUCKET_PATH=$(echo "${cleaning}" | awk -F, '{print $2}' | sed -e 's/^\([^:]*\):\(.*\)$/\2/')
        URI=$(echo "${cleaning}" | awk -F, '{print $1}' | sed -e 's/^\([^:]*\):\(.*\)$/\2/')
    fi

    readonly BUCKET_PATH
    readonly URI
}

function hander() {
    # e.g. ${1} = '{"path": "/path/to","uri": "/hoge"}'
    local -r _event_data="${1}"
    to_params "${_event_data}"
    # echo "BUCKET_PATH:${BUCKET_PATH}"  # debug_message
    # echo "URI:${URI}"  # debug_message

    local -r WORK_DIR=".work"
    if [ -d ${WORK_DIR} ]; then
        rm -fr ${WORK_DIR}
    fi
    mkdir -p ${WORK_DIR}

    cd ${WORK_DIR}
    aws s3 --profile "${PROFILE}" cp s3://"${BUCKET}${BUCKET_PATH}" . --recursive > /dev/null
    # ${BUCKET} is the bucket name in S3. It should be set to an environment variable.
    # ${BUCKET} はS3 のバケット名。環境変数に設定しておくこと。

    # schellcheck disable=SC2038
    find . -type f -name "aws-*" \
        | xargs jq "select(.action == \"ALLOW\" and .httpRequest.uri == \"${URI}\") | {clientIp: .httpRequest.clientIp, headers: .httpRequest.headers, coutry: .httpRequest.country}"

    (cd - && rm -fr ${WORK_DIR}) > /dev/null
}

hander "${EVENT_DATA}"
exit 0
