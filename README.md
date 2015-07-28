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

### 使い方

コマンドラインから

~~~~
$ bcpdfcrop [/h] [/s] in.pdf [out.pdf] [page-range] [left-margin] [top-margin] [right-margin] [bottom-margin]
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
- オプションとして，`/h` と `/s` を最初に指定することができます（両方使う場合は `/h`, `/s` の順にしてください）。
    - `/h` オプションは，BoundingBox の代わりに HiResBoundingBox を使います (hires) 。
    - `/s` オプションは，複数ページ PDF の処理で各ページを個別のファイルに分割して出力します (separate, split) 。
      これはオリジナルの Perl スクリプトにない機能です。

より簡単な使い方として，バッチファイルをデスクトップなどに置いておいて PDF ファイルをドラッグ＆ドロップすることもできます。
この場合，PDF ファイルの全ページがクロップされて単一ファイルになって出てきます。

### その他の特徴

- Ghostscript は rungs.exe を使用していますので，TeX Live でも W32TeX でも利用できると思います。
- PDF ファイルはカレントディレクトリまたは任意のディレクトリのフルパスで指定できます。
- 元の PDF ファイル名やパスに空白文字あるいは ShiftJIS の「ダメ文字」が含まれていても正しく処理できます。
- 元の PDF ファイルの PDF Version を保持します。
- ページ範囲指定機能・分割出力機能がオリジナルの pdfcrop.pl にはない機能で，bcpdfcrop.bat の優れた点だと思っています。
- 作業ディレクトリとして，Windows 環境変数の `%TEMP%` の場所を使います（この点も pdfcrop.pl とは異なります；もし値が空の場合はカレントディレクトリを使います）。

### 今気づいている点・制限事項 (v0.1.0) ：

- pdfcrop.pl とは引数の指定の仕方が異なります。
- pdfcrop.pl のような多用なオプション指定には対応していません（余白のみ指定可能）。
- 元の PDF に空白のページが含まれている場合の扱いが異なります。
  本家 Perl スクリプト版は元のページサイズを維持して取り込みますが，バッチファイル版は横幅のみ維持して縦幅は 1 mm になるようです。
- 出来上がる PDF ファイルのサイズが異なります。
  本家 Perl スクリプト版とバッチファイル版で同じ PDF を処理すると，バッチファイル版で作った方がファイルサイズが小さくなります（余分な情報を埋め込まないからです；なんかラッキー）。
  ただし，Perl 版のほうが処理は高速です。

### ライセンス

修正 BSD ライセンス (BSD 2-Clause) にしました。license.txt を参照してください。

### 更新履歴

- v0.1.0 (2015-07-28)
    - tcpdfcrop.bat (v0.9.3) の内部処理を変更し，`/s` オプションを追加して公開。
    - tcpdfcrop の tc (TeX comedian) らしさがなくなったので，bc (Batch comedian) に変更。

--------------------
Hironobu YAMASHITA (aka. "Acetaminophen" or "@aminophen")
http://acetaminophen.hatenablog.com/
