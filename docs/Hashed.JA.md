# NAME

Getopt::EX::Hashed - Getopt::Long 用ハッシュ格納オブジェクトの自動化

# VERSION

Version 1.0601

# SYNOPSIS

    # script/foo
    use App::foo;
    App::foo->new->run();

    # lib/App/foo.pm
    package App::foo;

    use Getopt::EX::Hashed; {
        Getopt::EX::Hashed->configure( DEFAULT => [ is => 'rw' ] );
        has start    => ' =i  s begin ' , default => 1;
        has end      => ' =i  e       ' ;
        has file     => ' =s@ f       ' , any => qr/^(?!\.)/;
        has score    => ' =i          ' , min => 0, max => 100;
        has answer   => ' =i          ' , must => sub { $_[1] == 42 };
        has mouse    => ' =s          ' , any => [ 'Frankie', 'Benjy' ];
        has question => ' =s          ' , any => qr/^(life|universe|everything)$/i;
    } no Getopt::EX::Hashed;

    sub run {
        my $app = shift;
        use Getopt::Long;
        $app->getopt or pod2usage();
        if ($app->answer == 42) {
            $app->question //= 'life';
            ...

# DESCRIPTION

**Getopt::EX::Hashed**は、**Getopt::Long**および**Getopt::EX::Long**を含む互換モジュールのコマンドラインオプション値を格納するハッシュオブジェクトの作成を自動化するモジュールです。モジュール名は**Getopt::EX**プレフィックスを共有していますが、これまでのところ、**Getopt::EX**の他のモジュールとは独立して動作します。

このモジュールの主な目的は、初期化と仕様を一箇所に統合することです。また、簡単な検証インターフェースも提供します。

`is`パラメータが与えられると、アクセサメソッドが自動的に生成されます。同じ関数がすでに定義されている場合、プログラムは致命的なエラーを引き起こします。アクセサはオブジェクトが破棄されると削除されます。複数のオブジェクトが同時に存在する場合、問題が発生する可能性があります。

# FUNCTION

## **has**

オプション・パラメータを以下の形式で宣言します。括弧はわかりやすくするためのもので、省略してもよい。

    has option_name => ( param => value, ... );

たとえば、整数値をパラメータとしてとり、`-n`としても使えるオプション`--number`を定義するには、次のようにします。

    has number => spec => "=i n";

アクセサは最初の名前で作成されます。この例では、アクセサは `$app->number` と定義されます。

配列参照が与えられている場合、複数の名前を一度に宣言することができます。

    has [ 'left', 'right' ] => ( spec => "=i" );

名前がプラス（`+`）で始まる場合、与えられたパラメータは既存の設定を更新します。

    has '+left' => ( default => 1 );

`spec`パラメータについては、最初のパラメータであればラベルを省略することができます。

    has left => "=i", default => 1;

パラメータの数が偶数でない場合、デフォルトのラベルが先頭に存在するものとみなされます：最初のパラメータがコード参照であれば`action`、そうでなければ`spec`となります。

以下のパラメータが利用可能です。

- \[ **spec** => \] _string_

    オプション指定`spec =>` ラベルを省略できるのは、それが最初のパラメータである場合だけです。

    _string_ では、オプションの仕様とエイリアスの名前は空白で区切られ、どのような順番でも表示できます。

    `--start`というオプションを持ち、その値として整数を取り、`-s`と`--begin`という名前でも使えるようにするには、次のように宣言します。

        has start => "=i s begin";

    上記の宣言は以下の文字列にコンパイルされます。

        start|s|begin=i

    これは、`Getopt::Long`の定義に準拠しています。もちろん、次のように書くこともできます：

        has start => "s|begin=i";

    名前とエイリアスにアンダースコア(`_`)が含まれている場合、アンダースコアの代わりにダッシュ(`-`)を使った別のエイリアスが定義されます。

        has a_to_z => "=s";

    上記の宣言は以下の文字列にコンパイルされます。

        a_to_z|a-to-z=s

    特に何もする必要がない場合は、空文字列（または空白のみ）を値として与えます。そうでない場合は、オプションとはみなされません。

- **alias** => _string_

    **alias**パラメータで追加のエイリアス名を指定することもできます。`spec`パラメータのものと違いはありません。

        has start => "=i", alias => "s begin";

- **is** => `ro` | `rw`

    アクセサメソッドを生成するには、`is`パラメータが必要です。読み込み専用なら`ro`、読み書きなら`rw`を指定します。

    読み書き可能なアクセサはlvalue属性を持っているので、それを代入することができます。このように使えます：

        $app->foo //= 1;

    これは、次のように書くよりずっと簡単です。

        $app->foo(1) unless defined $app->foo;

    以下のすべてのメンバに対してアクセサを作りたい場合は、`configure`を使って`DEFAULT`パラメータを設定します。

        Getopt::EX::Hashed->configure( DEFAULT => [ is => 'rw' ] );

    割り当て可能なアクセサを好まない場合は、`ACCESSOR_LVALUE` パラメータを 0 に設定します。アクセサは `new` の時点で生成されるため、この値はすべてのメンバに対して有効です。

- **default** => _value_ | _coderef_

    デフォルト値を設定します。デフォルト値が指定されない場合、メンバは`undef`として初期化されます。

    値がARRAYまたはHASHへの参照である場合、同じメンバを持つ新しい参照が割り当てられます。つまり、メンバ・データは複数の`new`呼び出しにまたがって共有されます。`new`を複数回呼び出してメンバ・データを変更する場合は注意してください。

    コード参照が与えられている場合は、**new**の時点で呼び出され、デフォルト値が取得されます。宣言ではなく実行時に値を評価したい場合に有効です。デフォルトのアクションを定義したい場合は、**action**パラメータを使う。コード・リファレンスを初期値にしたい場合は、コード・リファレンスを返すコード・リファレンスを指定する必要があります。

    SCALARへの参照が与えられた場合、オプション値はハッシュオブジェクトメンバではなく、参照が示すデータに格納されます。この場合、ハッシュ・メンバにアクセスしても期待値は得られません。

- \[ **action** => \] _coderef_

    パラメータ `action` は、オプションを処理するために呼び出されるコード参照をとます。`<action =`> ラベルは、それが最初のパラメータである場合に限り、省略することができます。

    呼び出されたとき、ハッシュオブジェクトは `$_` として渡されます。

        has [ qw(left right both) ] => '=i';
        has "+both" => sub {
            $_->{left} = $_->{right} = $_[1];
        };

    これを`<"<`">> ですべてをキャッチすることができます。その場合、specパラメータは重要ではなく、必須ではありません。

        has ARGV => default => [];
        has "<>" => sub {
            push @{$_->{ARGV}}, $_[0];
        };

以下のパラメータはすべてデータ検証のためのものです。まず、`must`は汎用的なバリデータであり、何でも実装できます。その他は一般的なルールのショートカットです。

- **must** => _coderef_ | \[ _coderef_ ... \]

    パラメータ `must` は、オプション値を検証するためのコード参照を受け取ります。`action`と同じ引数をとり、ブール値を返します。次の例では、オプション**--answer**は有効な値として42だけを取ります。

        has answer => '=i',
            must => sub { $_[1] == 42 };

    複数のコード参照が与えられた場合、すべてのコードが真を返さなければなりません。

        has answer => '=i',
            must => [ sub { $_[1] >= 42 }, sub { $_[1] <= 42 } ];

- **min** => _number_
- **max** => _number_

    引数の最小値と最大値を設定します。

- **any** => _arrayref_ | qr/_regex_/ | _coderef_

    有効な文字列パラメータリストを設定します。各項目は、文字列、正規表現参照、コード参照のいずれかです。引数は、指定されたリストのいずれかの項目と同じか一致する場合に有効です。値がarrayrefでない場合は、単一の項目リスト（通常は正規表現かコード参照）として扱われます。

    以下の宣言はほぼ等価ですが、2番目の宣言は大文字小文字を区別しません。

        has question => '=s',
            any => [ 'life', 'universe', 'everything' ];

        has question => '=s',
            any => qr/^(life|universe|everything)$/i;

    オプションの引数を使用する場合は、リストにデフォルト値を含めることを忘れないでください。そうしないとバリデーション・エラーになります。

        has question => ':s',
            any => [ 'life', 'universe', 'everything', '' ];

# METHOD

## **new**

新しいハッシュオブジェクトを作成するクラスメソッド。すべてのメンバをデフォルト値で初期化し、設定に従ってアクセサメソッドを作成します。ロックされたキーを持つ祝福されたハッシュ参照を返します (LOCK\_KEYS が有効な場合)。

## **optspec**

`GetOptions` 関数に渡すことができるオプション指定リストを返します。

    GetOptions($obj->optspec)

`GetOptions` は、ハッシュ参照を最初の引数として与えることで、ハッシュに値を格納する機能を持っていますが、それは必要ありません。

## **getopt** \[ _arrayref_ \]

呼び出し元のコンテキストで定義された適切な関数を呼び出してオプションを処理します。

    $obj->getopt

    $obj->getopt(\@argv);

上記の例は、以下のコードのショートカットです。

    GetOptions($obj->optspec)

    GetOptionsFromArray(\@argv, $obj->optspec)

## **use\_keys** _keys_

ハッシュキーは`Hash::Util::lock_keys`によって保護されているため、存在しないメンバにアクセスするとエラーになります。この関数を使用して、使用前に新しいメンバー・キーを宣言してください。

    $obj->use_keys( qw(foo bar) );

任意のキーにアクセスしたい場合は、オブジェクトのロックを解除してください。

    use Hash::Util 'unlock_keys';
    unlock_keys %{$obj};

この動作は`configure`の`LOCK_KEYS`パラメータで変更できます。

## **configure** **label** => _value_, ...

オブジェクトを作成する前に、クラスメソッド`Getopt::EX::Hashed->configure()`を使用します。`new()`を呼び出すと、パッケージ固有の設定がオブジェクトにコピーされ、以降の操作に使用されます。オブジェクト固有の設定を更新するには、`$obj->configure()` を使用します。

以下の設定パラメータが使用できます。

- **LOCK\_KEYS** (default: 1)

    ハッシュ・キーをロックします。これにより、存在しないハッシュ・エントリへの偶発的なアクセスを避けることができます。

- **REPLACE\_UNDERSCORE** (default: 1)

    アンダースコアをダッシュに置き換えたエイリアスを生成します。

- **REMOVE\_UNDERSCORE** (default: 0)

    アンダースコアを除去したエイリアスを生成します。

- **GETOPT** (default: 'GetOptions')
- **GETOPT\_FROM\_ARRAY** (default: 'GetOptionsFromArray')

    `getopt` メソッドから呼び出される関数名を設定します。

- **ACCESSOR\_PREFIX** (default: '')

    指定すると、メンバ名の前に付加されてアクセサ・メソッドになります。`ACCESSOR_PREFIX` が `opt_` として定義されている場合、メンバ `file` のアクセサは `opt_file` になります。

- **ACCESSOR\_LVALUE** (default: 1)

    trueの場合、読み書きアクセサはlvalue属性を持つ。この動作を好まない場合はゼロに設定します。

- **DEFAULT**

    デフォルト・パラメータを設定します。`has`が呼び出されると、DEFAULTパラメータが引数パラメータの前に挿入されます。そのため、両方に同じパラメータが含まれている場合は、引数リストで後の方が優先されます。`+`によるインクリメンタルコールは影響を受けないです。

    DEFAULTの典型的な使い方は、`is`で以下のすべてのハッシュ・エントリーのアクセサ・メソッドを用意することです。`DEFAULT => []`を宣言してリセットします。

        Getopt::EX::Hashed->configure(DEFAULT => [ is => 'ro' ]);

## **reset**

クラスを元の状態にリセットします。

# SEE ALSO

[Getopt::Long](https://metacpan.org/pod/Getopt%3A%3ALong)

[Getopt::EX](https://metacpan.org/pod/Getopt%3A%3AEX), [Getopt::EX::Long](https://metacpan.org/pod/Getopt%3A%3AEX%3A%3ALong)

# AUTHOR

Kazumasa Utashiro

# COPYRIGHT

The following copyright notice applies to all the files provided in
this distribution, including binary files, unless explicitly noted
otherwise.

Copyright 2021-2024 Kazumasa Utashiro

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
