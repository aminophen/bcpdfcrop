## bcpdfcrop.bat --- もうひとつの PDF クロップツール

「Perl 無しの Windows」で pdfcrop の類似処理を行うバッチファイルです。
Heiko Oberdiek (@oberdiek) さんによるオリジナルの Perl スクリプト pdfcrop.pl を参考にしています。
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

### 使い方

コマンドラインから

~~~~
$ bcpdfcrop [/d] [/h] [/s] in.pdf [out.pdf] [page-range] [left-margin] [top-margin] [right-margin] [bottom-margin]
~~~~

という形式で実行します。

- `out.pdf` を指定しない場合は，接尾辞として in.pdf のファイル名に -crop が付きます。
- `<page-range>` は，処理するページ範囲を指定します。
  これはオリジナルの Perl スクリプトにない機能です。
  開始ページと終了ページをハイフンで結んで指定し，アスタリスクを使えば「最後まで」「最初から」を指定できます。
  数字をひとつだけ与えた場合は，その単一ページだけが処理されます。
  指定しなければ全ページが処理されます。以下に例を示します：
    - `$ bcpdfcrop in.pdf out.pdf 3-10` ： 3 ページ目から 10 ページ目までを処理
    - `$ bcpdfcrop in.pdf out.pdf 3-*` ： 3 ページ目から（最後まで）を処理
    - `$ bcpdfcrop in.pdf out.pdf *-10`  ： （最初から）10 ページ目までを処理
    - `$ bcpdfcrop in.pdf out.pdf 3` ： 3 ページ目のみを処理
    - `$ bcpdfcrop in.pdf out.pdf *` ： 1 ページ目のみを処理
- `<***-margin>` は，余白を bp 単位で指定します。全ページに同じ余白が付きます。左・上・右・下の順になります。
    - `$ bcpdfcrop in.pdf out.pdf 3-10 5 10 15 20` ： 「左に5bp，上に10bp，右に15bp，下に20bp」の余白が付きます。
- 引数を空にしたい場合は，単に `""` とすると期待通りになるかもしれません。
- オプションとして，`/d` や `/h` や `/s` を最初に指定することができます（複数使う場合は `/d`，`/h`, `/s` の順にしてください）。
    - `/d` オプションは，デバッグ用に一時ファイルを削除せず残します (debug) 。
    - `/h` オプションは，BoundingBox の代わりに HiResBoundingBox を使います (hires) 。
    - `/s` オプションは，複数ページ PDF の処理で各ページを個別のファイルに分割して出力します (separate, split) 。
      これはオリジナルの Perl スクリプトにない機能です。
- v0.2.0 以降では，呼び出すプログラムのコマンド名をユーザが自由に変更できます。
  バッチファイル冒頭に用意した欄に PDFTEXCMD，XBBCMD，GSCMD という変数の値を書き込めば，そのプログラムを実行します。
  値を空にした状態ではデフォルトのプログラムが適用されます。
    - PDFTEXCMD は pdfTeX のコマンド名を指定します。デフォルトは pdftex ですが，luatex でも動く可能性があります。
    - XBBCMD は extractbb のコマンド名を指定します。
    - GSCMD は Ghostscript のコマンド名を指定します。デフォルトは rungs ですが，gswin32c あるいは gswin64c とすると都合が良いかもしれません。

より簡単な使い方として，バッチファイルをデスクトップなどに置いておいて PDF ファイルをドラッグ＆ドロップすることもできます。
この場合，PDF ファイルの全ページがクロップされて単一ファイルになって出てきます。
ただし，一度に複数ファイルをドラッグ＆ドロップしても正しく処理されるのは一つだけです（むしろ二番目の PDF ファイルは，クロップ後のファイルで上書きされてしまいますので，注意してください）。

付録として，複数ファイルをドラッグ＆ドロップして処理可能な bcpdfcrop-multi.bat というバッチファイルも公開します。
本体の bcpdfcrop.bat をパスの通った場所に置いておけば，bcpdfcrop-multi は bcpdfcrop を内部で繰り返し呼び出して複数ファイルをクロップします。
もちろん bcpdfcrop-multi は bcpdfcrop に依存しますので，パスを見つけられなければ何もできません（このほうが当然ながら圧倒的に開発が楽だから）。

### その他の特徴

- Ghostscript は rungs.exe を使用していますので，TeX Live でも W32TeX でも利用できると思います。
- PDF ファイルはカレントディレクトリまたは任意のディレクトリのフルパスで指定できます。
- 元の PDF ファイル名やパスに空白文字あるいは ShiftJIS の「ダメ文字」が含まれていても正しく処理できます。
- 元の PDF ファイルの PDF Version を保持します。
- ページ範囲指定機能・分割出力機能がオリジナルの pdfcrop.pl にはない機能で，bcpdfcrop.bat の優れた点だと思っています。
- 作業ディレクトリとして，Windows 環境変数の `%TEMP%` の場所を使います（この点も pdfcrop.pl とは異なります；もし値が空の場合はカレントディレクトリを使います）。

### 今気づいている点・制限事項 (v0.2.2) ：

- pdfcrop.pl とは引数の指定の仕方が異なります。
- pdfcrop.pl のような多用なオプション指定には対応していません（余白のみ指定可能）。
- 出来上がる PDF ファイルのサイズが異なります。
  本家 Perl スクリプト版とバッチファイル版で同じ PDF を処理すると，バッチファイル版で作った方がファイルサイズが小さくなります（余分な情報を埋め込まないからです；なんかラッキー）。
  ただし，Perl 版のほうが処理は高速です。

### ライセンス

修正 BSD ライセンス (BSD 2-Clause) にしました。license.txt を参照してください。

### 更新履歴

bcpdfcrop および bcpdfcrop-multi の更新履歴は changelog.txt を参照してください。
以前の tcpdfcrop の更新履歴は Gist の Revision 記録およびコメント欄を参照してください。

--------------------
Hironobu YAMASHITA (aka. "Acetaminophen" or "@aminophen")
http://acetaminophen.hatenablog.com/
