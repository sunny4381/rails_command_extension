# rails コマンドへ独自コマンドを組み込む方法

Rake タスクって何だか変ですよね。できたら書きたくないですよね。

Ruby には [Thor](https://github.com/erikhuda/thor) というイケてるコマンドライン・ユーティリティを書ける Gem がすでにあります。Thor は、イケてるので、サブコマンドを書くことができます。Rake タスクではなくて、Thor を利用できたら素敵ですよね。

実は rails コマンドは Thor をすでに利用しているんです。そして、Rails Engine の場合、Thor を使って独自コマンドを提供する標準的な方法が用意されているようですが、Rails Application の場合、標準的な方法はありません。自分でなんとかするしかありません。

以降では自分でなんとかする方法を説明します。generator のアシストは受けられないので、全て手作業でファイルを修正したり、ファイルを作成したりしていきます。

## 前提

本記事で作成したサンプルは <https://github.com/sunny4381/rails_command_extension> に置いておきます。
このサンプルは [Rails チュートリアル](https://railstutorial.jp/chapters/beginning?version=6.0)の[第14章のソースコード](https://github.com/yasslab/sample_apps/tree/master/6_0_0/ch14)を元にしています。Rails チュートリアルでは `User` と `Micropost` の二つのモデルが登場しますので、本記事もこの2つのモデルを操作してみたいと思います。

## Rails::Command::Base

早速、独自コマンドを作成していきます。独自コマンドは、直接 Thor を継承せずに、Rails::Command::Base を継承します。

~~~ruby:lib/commands/main/main_command.rb
require "rails/command"

module SampleApp
  module Command
    class MainCommand < Rails::Command::Base
      namespace "sample"
      @command_name = "sample"

      def hello
        say "hello"
      end
    end
  end
end
~~~

`namespace` と `@command_name` を指定して、コマンド名を明示的に指定しています。この 2 つの指定がなければ `sample_app:main` なんていう冗長なコマンド名になってしまいます。

上記のコードを `lib/commands/main/main_command.rb` へ保存します。

## bin/rails の変更

`bin/rails` を直接変更して、独自コマンドを組み込みます。次のように修正します。

~~~ruby:bin/rails
#!/usr/bin/env ruby
APP_PATH = File.expand_path('../config/application', __dir__)
require_relative '../config/boot'

# install application commands
require_relative '../lib/commands/main/main_command'

# run rails command
require 'rails/commands'
~~~

`require_relative` で、独自コマンドを読み込んでいます。
`Rails::Command::Base` に、独自コマンドを rails コマンドのコマンド一覧へ登録する処理がありますので、読み込むだけで rails コマンドに登録されます。試しに `bin/rails` を実行してみます。

~~~shell
$ bin/rails
  ...
  routes
  runner
  sample_app:hello
  secret
  secrets:edit
  ...
~~~

少しわかりづらいですが、`sample_app:hello` と独自コマンドが表示されています。試しに実行してみます。

~~~shell
$ bin/rails sample_app:hello
hello
~~~

## モデルの操作とサブコマンド

コンソールに文字列を表示するような単純な処理なら問題ありませんが、Rails アプリケーションが初期化されていないので、モデルを検索したり、作成したり、削除したりすることがまだできません。

モデルを操作するコマンドをサブコマンドとして追加していきます。まず `mail_command.rb` の修正。

~~~ruby:lib/commands/main/main_command.rb
require "rails/command"
require_relative '../user/user_command'
require_relative '../micropost/micropost_command'

module SampleApp
  module Command
    class MainCommand < Rails::Command::Base
      namespace "sample_app"
      @command_name = "sample_app"

      subcommand "user", SampleApp::Command::UserCommand
      subcommand "micropost", SampleApp::Command::MicropostCommand
    end
  end
end
~~~

Rails アプリケーションが初期化されていないので、クラスのオートロードも効きません。`require_relative` を用いて明示的に `user_command.rb` と `micropost_command.rb` をロードしています。そして、Thor の `subcommand` 命令で user と micropost という2つのサブコマンドを追加しています。

`user_command.rb` を次のように実装します。

~~~ruby:lib/commands/user/user_command.rb
module SampleApp
  module Command
    class UserCommand < Rails::Command::Base
      desc "list", "list users."
      def list
        require_application_and_environment!

        say
        say "#{'Name'.ljust(14)}  #{'Email'.ljust(32)}  Updated At"
        say "-" * 80

        User.all.each do |user|
          say "#{user.name.ljust(14)}  #{user.email.ljust(32)}  #{user.updated_at.iso8601}"
        end
      end
    end
  end
end
~~~

`user_command.rb` では、ユーザー一覧を表示する `list` というコマンドを定義しています。
`list` の先頭で `require_application_and_environment!` を呼び出し Rails アプリケーションを初期化しています。
続いて User をデータベースからロードし、コンソールに出力しています。
なお、Rails アプリケーションの初期化後は、オートロードが効くようになるので、User モデルを明示的に読み込む必要はありません。

`micropost_command.rb` を次のように実装します。

~~~ruby:lib/commands/micropost/micropost_command.rb
module SampleApp
  module Command
    class MicropostCommand < Rails::Command::Base
      desc "list", "list microposts."
      def list
        require_application_and_environment!

        say
        say "#{'Name'.ljust(14)}  #{'Content'.ljust(14)}  Created At"
        say "-" * 80

        Micropost.all.each do |post|
          say "#{post.user.name.ljust(14)}  #{post.content.ljust(14)}  #{post.created_at.iso8601}"
        end
      end
    end
  end
end
~~~

ほぼ `user_command.rb` と同じで、こちらの方は Micropost モデルの一覧をコンソールに出力しています。

サブコマンドを追加できたら試しに実行してみます。

~~~
$ bin/rails sample_app:user list

Name            Email                             Updated At
--------------------------------------------------------------------------------
sample          sample@example.jp                 2020-12-05T05:33:11Z

~~~

Rails チュートリアルを少し進め、ユーザーを登録したら、上のように出力されます。

## 今後の課題

残念ながら `bin/rails` コマンドだと独自コマンドを実行することができますが、単に
`rails` や `bundle exec rails` の場合、独自コマンドを実行することができません。
これらでも独自コマンドを実行できるようにするのは、今後の課題です。
