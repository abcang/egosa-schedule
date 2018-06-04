egosa-schedule
===

配信予定ツイートを捕捉するために作ったやつ
正規表現で頑張ってるので検出漏れ、誤検出あり

30秒に1回最大100件取得できます。それ以上の流速はまだ考慮してないです。

## 環境
* Bundler
* Ruby

## 設定
環境変数にTwitterのコンシューマキーなどを設定します。  

WEBHOOK_URL: SlackのWebhookのURL
LIST_USER: リスト作成者
LIST_NAME: リスト名

例えば `https://twitter.com/abcang1015/lists/egosa-schedule` の場合、
LIST_USERは`abcang1015`、LIST_NAMEは`egosa-schedule`になります。

## 起動

```bash
$ cat .env
WEBHOOK_URL=xxxxxx
CONSUMER_KEY=xxx
CONSUMER_SECRET=xxx
OAUTH_TOKEN=xxx
OAUTH_TOKEN_SECRET=xxx
LIST_USER=abcang1015
LIST_NAME=egosa-schedule
$ bundle install --path vendor/bundle --deployment
$ ruby main.rb .env
```

## Docker

```bash
$ docker build -t egosa-schedule .
$ docker run -d egosa-schedule \
  -e "WEBHOOK_URL=xxxxxx" \
  -e "CONSUMER_KEY=xxx" \
  -e "CONSUMER_SECRET=xxx" \
  -e "OAUTH_TOKEN=xxx" \
  -e "OAUTH_TOKEN_SECRET=xxx" \
  -e "LIST_USER=abcang1015" \
  -e "LIST_NAME=egosa-schedule"
```

## ライセンス
MIT
