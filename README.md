# RubyEvalBot

![enter image description here](https://cdn-ak2.f.st-hatena.com/images/fotolife/o/oneforowl/20170807/20170807231031.gif)

## Description

RubyEvalBotはSlackでrubyのスニペットが投稿されたとき、安全に評価して標準出力を教えてくれるbotです。あなたがslackで仲間たちにちょっとしたショートコードを共有した際にどんな結果を得るかを実際の実行結果で示してくれます。

またコードの評価はセーフレベル1で実行され、処理時間は秒数制限されているため時間のかかる処理やコマンドラインの実行など危険なコードを避けてくれます。

**[Warn]**　評価の安全性は完全ではありませんし、悪意と技術があれば簡単に悪用可能です。参加者が限定されているクローズなSlackでの利用を想定しています。

## Usage

もっとも簡単な形ではnohupでバックグラウンドジョブとして起動することで実行可能です。
```shell
$ git clone https://github.com/owlworks/slack-ruby-eval.git
$ cd ./slack-ruby-eval
$ bundle install
# config.ymlのslack.tokenを編集するか、環境変数ENV['SLACK_TOKEN']にボットアカウントのアクセストークンを設定して下さい
$ nohup eval_ruby.rb &
```

## Details

- コードを評価するためにはbotが参加しているチャットへ、言語をrubyに指定したスニペットが共有される必要があります
- セーフレベル1で実行されない処理、およびFileやIOなど一部のクラスは利用できません
- 完了に数秒以上かかるようなコードについても同様です
- また長過ぎる標準出力については自動的に破棄あるいは省略されます

Enjoy slack!
