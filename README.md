# urip

Client IP from URI

## Purpose / 目的

Project for retrieving client IPs from AWS WAF using AWS CLI.
When there is an access to a URI of concern, retrieve the client IP from the URI and use it as a reference for investigation.

This project was created on the assumption that it will be executed by AWS Lambda.
Therefore, the execution environment is AWS Lambda, not a local environment.

AWS CLI を使って AWS WAF からクライアント IP を検索するためのプロジェクト。
気になる URI へのアクセスがあった場合に、URI からクライアント IP を検索して、調査の参考にする。

なお、本プロジェクトは AWS Lambda で実行させることを前提に作成した。
よって、実行環境はローカル環境ではなく、AWS Lambda となる。

## Advance preparation / 事前準備

### Install the AWS CLI / AWS CLI をインストールしておく

The installation method is optional. a Docker image is also acceptable.

インストール方法は任意。Docker イメージでも構わない。

```sh
➜  aws --version
aws-cli/2.4.29 Python/3.9.12 Darwin/19.6.0 source/x86_64 prompt/off
```

### Install the AWS SAM CLI / AWS SAM CLI をインストールしておく

Install AWS SAM CLI referring to the following.

- https://docs.aws.amazon.com/ja_jp/serverless-application-model/latest/developerguide/serverless-sam-cli-install.html

https://docs.aws.amazon.com/ja_jp/serverless-application-model/latest/developerguide/serverless-sam-cli-install.html を参考に AWS SAM CLI をインストールする。

### Register a profile / プロファイルを登録しておく

Register a profile using IAM credentials.csv.
Specify this profile as an option in the shell script.

IAM の credentials.csv を使用してプロファイルを登録する。
このプロファイルをシェルスクリプトのオプションに指定する。

## Deployment to AWS Lambda / デプロイ

First, prepare template.yaml.

まず template.yaml を準備する。

1. Now that you have template.yaml.sample, copy it with the filename template.yaml / template.yaml.sample を用意したので、それを template.yaml のファイル名でコピーする
2. There are two "TBD" in template.yaml, so modify the contents to suit each environment / template.yaml に "TBD" が2箇所あるので、各環境に即した内容で修正する

```sh
➜  cp template.yaml.sample template.yaml
➜  vim template.yaml
```

Next, build the project.

次にプロジェクトをビルドする。

```sh
➜  sam build
```

Finally, deploy to AWS.
The `--guided` option should be specified for the first deployment; the samconfig.toml file will be created, so you do not need to specify the `--guided` option for the second and subsequent deployments.

最後に AWS へデプロイする。
初回デプロイ時は `--guided` オプションを付ける。samconfig.toml ファイルが作成されるため、2回目以降は `--guided` オプションを指定しなくて良い。


```sh
➜  sam deploy --profile PROFILE --guided  # first deployment
➜  sam deploy --profile PROFILE
```

## execution (e.g. program) / 実行

Execute from AWS Lambda.
When executing, create a "test event" with the following contents.

AWS Lambda から実行する。
実行する際には、以下の内容で「テストイベント」を作成する。

```json
{
    "params": ["path/to", "/uri"]
}
```
