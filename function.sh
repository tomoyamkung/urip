#!/bin/bash
# shellcheck disable=SC3040
set -euo pipefail

function to_params() {
    # e.g. ${1} = '{ "params": ["path/to", "/uri"] }'
    # => BUCKET_PATH=path/to, URI=/uri
    local -r cleaning=$(echo "${1}" | sed -e 's/.*\[\(.*\)\].*/\1/g' | tr -d '"' | tr -d ' ')

    if echo "${cleaning}" | awk -F, '{print $1}' | grep -q "^path" ; then
        BUCKET_PATH=$(echo "${cleaning}" | awk -F, '{print $1}' | sed -e 's/^\([^:]*\):\(.*\)$/\2/')
        URI=$(echo "${cleaning}" | awk -F, '{print $2}' | sed -e 's/^\([^:]*\):\(.*\)$/\2/')
    else
        BUCKET_PATH=$(echo "${cleaning}" | awk -F, '{print $2}' | sed -e 's/^\([^:]*\):\(.*\)$/\2/')
        URI=$(echo "${cleaning}" | awk -F, '{print $1}' | sed -e 's/^\([^:]*\):\(.*\)$/\2/')
    fi

    readonly BUCKET_PATH
    readonly URI
    # echo "BUCKET_PATH:${BUCKET_PATH}"  # debug_message
    # echo "URI:${URI}"  # debug_message
}

function handler() {
    # e.g. ${1} = '{ "params": ["path/to", "/uri"] }'

    echo "${1}" 1>&2;

    to_params "${1}"

    # Download log files to the working directory.
    # 作業ディレクトリにログファイルをダウンロードする
    WORK_DIR=".work"
    if [ -d ${WORK_DIR} ]; then
        rm -fr ${WORK_DIR}
    fi
    mkdir -p ${WORK_DIR}

    cd ${WORK_DIR}
    aws s3 cp s3://"${BUCKET}/${BUCKET_PATH}" . --recursive > /dev/null
    # [Caution] ${BUCKET} is the bucket name in S3. It should be set to an environment variable.
    # 【注意】${BUCKET} はS3 のバケット名。環境変数に設定しておくこと。

    # If the log file does not exist, the process is terminated.
    # ログファイルが存在しなければ処理を終了する。
    if [ -z "$(ls .)" ] ; then
        (cd - && rm -fr ${WORK_DIR}) > /dev/null
        curl -X POST -H 'Content-type: application/json' -d "{\"text\":\"Log files is not found.\"}" "${SLACK_WEBHOOK_URL}"
        exit 1;
    fi

    local -r result=$(find . -type f -name "aws-*" \
        | xargs jq "select(.action == \"ALLOW\" and .httpRequest.uri == \"${URI}\") | {clientIp: .httpRequest.clientIp, headers: .httpRequest.headers, coutry: .httpRequest.country}")
    echo "${result}" 1>&2;  # => clientIp, headers, coutry

    local -r clientip=$(echo "${result}" | grep "clientIp" | awk '{print $2}' | sed -e 's/\"//g' | sed -e 's/,$//g' | sort | uniq)
    echo "${clientip}" 1>&2;  # => clientIp

    (cd - && rm -fr ${WORK_DIR}) > /dev/null
    curl -X POST -H 'Content-type: application/json' -d "{\"text\":\"${URI}:${clientip}\"}" "${SLACK_WEBHOOK_URL}"
    # Slack's Incoming Webhook only notifies the client IP.
    # Slack の Incoming Webhook には クライアント IP だけを通知する
    # [Caution] ${SLACK_WEBHOOK_URL} is the Slack's Incoming Webhook. It should be set to an environment variable.
    # 【注意】${SLACK_WEBHOOK_URL} は Slack の Incoming Webhook。環境変数に設定しておくこと。
}