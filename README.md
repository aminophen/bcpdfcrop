## bcpdfcrop.bat --- もうひとつの PDF クロップツール

「Perl 無しの Windows」で pdfcrop の類似処理を行うバッチファイルです。
Heiko Oberdiek (@oberdiek) さんによるオリジナルの Perl スクリプト pdfcrop.pl の出力を参考にしています。
ZR さん (@zr-tex8r) のバッチファイルをもとに fork した tcpdfcrop.bat がベースです。

- bcpdfcrop.bat 一次配布元
    - bcpdfcrop.bat https://github.com/aminophen/bcpdfcrop
- tcpdfcrop.bat（bcpdfcrop.bat の前身）
    - tcpdfcrop.bat (by ZR) https://gist.github.com/zr-tex8r/138b07c6d71e31aa5334
    - tcpdfcrop.bat (by aminophen) https://gist.github.com/aminophen/fdc3dfa320d9f0c32aeb
- pdfcrop.pl（Perl スクリプト）
    - pdfcrop.pl (by Oberdiek) https://www.ctan.org/pkg/pdfcrop

### 動作条件

- Windows のコマンド プロンプトなら動くと思います。PowerShell では動作未確認です（動く場合もありますが，引数指定によっては期待通りに動かない場合もあります）。
- TeX ディストリビューションと Ghostscript が正しくインストールされている前提です（TeX Live，W32TeX で確認）。
  実際に使用するプログラムは以下のとおりです：
    - pdftex.exe
    - extractbb.exe
    - rungs.exe (gswin32c.exe or gswin64c.exe)

### インストールと設定

基本的に Windows のコマンドライン（主にコマンド プロンプト）から呼び出すことを想定しています。
bcpdfcrop.bat をパスの通ったディレクトリに置けば，インストールは完了です。

デフォルトでは pdftex.exe，extractbb.exe，rungs.exe という TeX 関連プログラムと Ghostscript にパスが通っていることを想定しています。
もしそうでない場合は，バッチファイル冒頭に用意されている欄でコマンド名を変更してください（v0.2.0 以降）。

- `PDFTEXCMD` は pdfTeX のコマンド名を指定します。デフォルトは pdftex.exe ですが，luatex.exe でも動く可能性があります。
- `XBBCMD` は extractbb のコマンド名を指定します。デフォルトは extractbb.exe です。
- `GSCMD` は Ghostscript のコマンド名を指定します。デフォルトは rungs.exe ですが，gswin32c.exe あるいは gswin64c.exe とすると都合が良いかもしれません。

値を空にした状態（初期状態）ではデフォルトのプログラムが適用されます。

### 使い方

コマンドラインから

~~~~
$ bcpdfcrop [<options>] in.pdf [out.pdf] [<additional arguments>]
~~~~

という形式で実行します。

- オプションを除いた第1引数が入力ファイル名，第2引数が出力ファイル名です。
  出力ファイル名を指定しない場合は，入力ファイル名に接尾辞 -crop が付きます。
- オプションを除いた第3引数以降は `<additional arguments>` で，以下のとおりです：
    - 第3引数：   `<page-range>`
    - 第4-7引数： `<left-margin>` `<top-margin>` `<right-margin>` `<bottom-margin>`
- 第3引数 `<page-range>` は，処理するページ範囲を指定します。
  これはオリジナルの Perl スクリプトにない機能です。
  開始ページと終了ページをハイフンで結んで指定し，アスタリスクを使えば「最後まで」「最初から」を指定できます。
  数字をひとつだけ与えた場合は，その単一ページだけが処理されます。
  指定しなければ全ページが処理されます。以下に例を示します：
    - `$ bcpdfcrop in.pdf out.pdf 3-10` ： 3 ページ目から 10 ページ目までを処理
    - `$ bcpdfcrop in.pdf out.pdf 3-*`  ： 3 ページ目から（最後まで）を処理
    - `$ bcpdfcrop in.pdf out.pdf *-10` ： （最初から）10 ページ目までを処理
    - `$ bcpdfcrop in.pdf out.pdf *-*`  ： 全ページを処理
    - `$ bcpdfcrop in.pdf out.pdf *`    ： 全ページを処理（※v0.3.0 以降の仕様）
    - `$ bcpdfcrop in.pdf out.pdf 3`    ： 3 ページ目のみを処理
- 第4-7引数 `<***-margin>` は，余白を bp 単位で指定します。全ページに同じ余白が付きます。左・上・右・下の順になります。
  後述する `/m` オプションによる余白指定のほうが高機能ですので，`/m` オプションの利用を推奨します。
  ただし，仮に `/m` オプションとこれらの引数が同時に指定された場合は，引数の値によって `/m` オプションの値は上書きされます。
    - `$ bcpdfcrop in.pdf out.pdf 3-10 5 10 15 20` ： 「左に5bp，上に10bp，右に15bp，下に20bp」の余白が付きます。
- 引数を空にしたい場合は，単に `""` とすると期待通りになるかもしれません。
- オプションとしては `/d`，`/h`，`/s`，`/m` を最初に指定することができます。
  これらのオプションは順不同で指定できます（※v0.3.1 以降の仕様）。
    - `/d` オプションは，デバッグ用に一時ファイルを削除せず残します (debug) 。
    - `/h` オプションは，BoundingBox の代わりに HiResBoundingBox を使います (hires) 。
    - `/s` オプションは，複数ページ PDF の処理で各ページを個別のファイルに分割して出力します (separate, split) 。
      これはオリジナルの Perl スクリプトにない機能です。
    - `/m "<left> <top> <right> <bottom>"` オプションは，余白を bp 単位で指定します (margins) 。全ページに同じ余白が付きます。
      数字を一つだけ指定した場合は左・上・右・下のすべてに適用され，二つだけ指定した場合は左右と上下がそれぞれ一致します。
      `/m` オプションと同時に先述の第4-7引数が指定されると，これらの値は上書きされます。
        - `$ bcpdfcrop /m "5 10 15 20" in.pdf out.pdf` ： 「左に5bp，上に10bp，右に15bp，下に20bp」の余白が付きます。
        - `$ bcpdfcrop /m "5 10" in.pdf out.pdf`       ： 「左右に5bp，上下に10bp」の余白が付きます。
        - `$ bcpdfcrop /m "5" in.pdf out.pdf`          ： 「左上右下に5bp」の余白が付きます。

### 別の使い方

より簡単な使い方として，バッチファイルをデスクトップなどに置いておき，PDF ファイルをドラッグ＆ドロップすることもできます。
この場合，PDF ファイルの全ページがクロップされて単一ファイルになって出てきます。
ただし，bcpdfcrop.bat に一度に複数ファイルをドラッグ＆ドロップしても正しく処理されるのは一つだけです（むしろ二番目の PDF ファイルは，クロップ後のファイルで上書きされてしまいますので，注意してください）。

付録として，複数ファイルをドラッグ＆ドロップして処理可能な bcpdfcrop-multi.bat というバッチファイルも公開します。
本体の bcpdfcrop.bat をパスの通った場所，または bcpdfcrop-multi.bat と同じ場所に置いておけば，bcpdfcrop-multi は内部で繰り返し bcpdfcrop を呼び出し，複数ファイルをクロップします。
もちろん bcpdfcrop-multi は bcpdfcrop に依存しますので，パスを見つけられなければ何もできません（このほうが当然ながら圧倒的に開発が楽だから）。

### その他の特徴

- Ghostscript は rungs.exe を使用していますので，TeX Live でも W32TeX でも利用できると思います。
- PDF ファイルはカレントディレクトリまたは任意のディレクトリのフルパスで指定できます。
- 元の PDF ファイル名やパスに空白文字あるいは ShiftJIS の「ダメ文字」が含まれていても正しく処理できます。
- 元の PDF ファイルの PDF Version を保持します。
- ページ範囲指定機能・分割出力機能がオリジナルの pdfcrop.pl にはない機能で，bcpdfcrop.bat の優れた点だと思っています。
- 作業ディレクトリとして，Windows 環境変数の `%TEMP%` の場所を使います（この点も pdfcrop.pl とは異なります；もし値が空の場合はカレントディレクトリを使います）。

### 今気づいている点・制限事項 (v0.3.5) ：

- pdfcrop.pl とは引数の指定の仕方が異なります。
- pdfcrop.pl のような多用なオプション指定には対応していません（余白のみ指定可能）。
- 出来上がる PDF ファイルのサイズが異なります。
  本家 Perl スクリプト版とバッチファイル版で同じ PDF を処理すると，バッチファイル版で作った方がファイルサイズが小さくなります（余分な情報を埋め込まないからです；なんかラッキー）。
  ただし，Perl 版のほうが処理は高速です。

### 開発目標

注意していただきたいのですが，pdfcrop.pl の再現は目指していません。
pdfcrop.pl のコード自体も読まずに，独自に実装しています（そもそも Perl 読めないので）。
基本的な仕組みは ZR さんの tcpdfcrop.bat を流用し，中間生成する pdfTeX ソースの検討段階で pdfcrop.pl の結果を一部参考にしました。

### ライセンス

修正 BSD ライセンス (BSD 2-Clause) にしました。license.txt を参照してください。

### 更新履歴

bcpdfcrop および bcpdfcrop-multi の更新履歴は changelog.md を参照してください。
以前の tcpdfcrop の更新履歴は Gist の Revision 記録およびコメント欄を参照してください。

--------------------
Hironobu YAMASHITA (aka. "Acetaminophen" or "@aminophen")
http://acetaminophen.hatenablog.com/
