# NAME

Getopt::EX::Hashed - Getopt::Long용 해시 저장소 객체 자동화

# VERSION

Version 1.0503

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

**Getopt::EX::Hashed**는 해시 객체를 자동화하여 **Getopt::Long** 및 **Getopt::EX::Long**을 포함한 호환 모듈에 대한 명령줄 옵션 값을 저장하는 모듈입니다. 모듈 이름은 **Getopt::EX** 접두사를 공유하지만, 지금까지는 **Getopt::EX**의 다른 모듈과 독립적으로 작동합니다.

이 모듈의 주요 목적은 초기화와 사양을 한곳에 통합하는 것입니다. 또한 간단한 유효성 검사 인터페이스도 제공합니다.

접근자 메서드는 `is` 파라미터가 주어지면 자동으로 생성됩니다. 동일한 함수가 이미 정의되어 있으면 프로그램에서 치명적인 오류가 발생합니다. 객체가 소멸되면 접근자는 제거됩니다. 여러 객체가 동시에 존재할 때 문제가 발생할 수 있습니다.

# FUNCTION

## **has**

옵션 매개변수는 다음 형식으로 선언합니다.

    has option_name => ( param => value, ... );

예를 들어 정수 값을 매개변수로 사용하며 `-n`으로도 사용할 수 있는 `-- 숫자` 옵션을 정의하려면 다음과 같이 하세요.

    has number => spec => "=i n";

첫 번째 예의 괄호는 명확성을 위한 것으로 생략할 수 있습니다. 접근자는 첫 번째 이름으로 생성됩니다. 이 예제에서 접근자는 `$app->number`로 정의됩니다.

배열 참조가 주어지면 한 번에 여러 이름을 선언할 수 있습니다.

    has [ 'left', 'right' ] => ( spec => "=i" );

이름이 더하기(`+`)로 시작하면 지정된 매개변수가 기존 설정을 업데이트합니다.

    has '+left' => ( default => 1 );

`spec` 파라미터의 경우 첫 번째 파라미터인 경우 레이블을 생략할 수 있습니다.

    has left => "=i", default => 1;

매개변수 수가 짝수가 아닌 경우, 기본 레이블이 맨 앞에 있는 것으로 간주합니다: 첫 번째 매개변수가 코드 참조인 경우 `action`, 그렇지 않은 경우 `spec`입니다.

다음 매개변수를 사용할 수 있습니다.

- \[ **spec** => \] _string_

    옵션 사양을 지정합니다. `spec =>` 레이블은 첫 번째 매개변수인 경우에만 생략할 수 있습니다.

    _string_에서 옵션 사양 및 별칭 이름은 공백으로 구분되며 어떤 순서로든 표시될 수 있습니다.

    정수를 값으로 사용하고 `-s` 및 `--begin`이라는 이름으로도 사용할 수 있는 `--start`라는 옵션을 가지려면 다음과 같이 선언합니다.

        has start => "=i s begin";

    위의 선언은 다음 문자열로 컴파일됩니다.

        start|s|begin=i

    으로 컴파일되며, 이는 `Getopt::Long` 정의를 따릅니다. 물론 이렇게 작성할 수도 있습니다:

        has start => "s|begin=i";

    이름과 별칭에 밑줄(`_`)이 포함된 경우 밑줄 대신 대시(`-`)를 사용하여 다른 별칭 이름을 정의합니다.

        has a_to_z => "=s";

    위의 선언은 다음 문자열로 컴파일됩니다.

        a_to_z|a-to-z=s

    특별히 필요한 것이 없으면 빈(또는 공백만 있는) 문자열을 값으로 지정합니다. 그렇지 않으면 옵션으로 간주되지 않습니다.

- **alias** => _string_

    **alias** 매개변수로 추가 별칭 이름을 지정할 수도 있습니다. `spec` 파라미터와 차이가 없습니다.

        has start => "=i", alias => "s begin";

- **is** => `ro` | `rw`

    접근자 메서드를 생성하려면 `is` 파라미터가 필요합니다. 읽기 전용의 경우 `ro`, 읽기-쓰기의 경우 `rw` 값을 설정합니다.

    읽기-쓰기 접근자에는 lvalue 속성이 있으므로 이를 할당할 수 있습니다. 다음과 같이 사용할 수 있습니다:

        $app->foo //= 1;

    다음과 같이 작성하는 것보다 훨씬 간단합니다.

        $app->foo(1) unless defined $app->foo;

    다음 모든 멤버에 대한 접근자를 만들려면 `configure`를 사용하여 `DEFAULT` 매개 변수를 설정합니다.

        Getopt::EX::Hashed->configure( DEFAULT => [ is => 'rw' ] );

    할당 가능한 접근자를 원하지 않는 경우 `ACCESSOR_LVALUE` 파라미터를 0으로 설정합니다. 접근자는 `new` 시점에 생성되므로 이 값은 모든 멤버에 유효합니다.

- **default** => _value_ | _coderef_

    기본값을 설정합니다. 기본값을 지정하지 않으면 멤버는 `undef`로 초기화됩니다.

    값이 배열 또는 해시 참조인 경우 동일한 멤버를 가진 새 참조가 할당됩니다. 즉, 멤버 데이터가 여러 `new` 호출에 걸쳐 공유됩니다. `new`를 여러 번 호출하여 멤버 데이터를 변경하는 경우 주의하세요.

    코드 참조가 주어지면 **new** 시점에 호출되어 기본값을 가져옵니다. 선언이 아닌 실행 시점에 값을 평가하려는 경우에 효과적입니다. 기본 동작을 정의하려면 **action** 매개변수를 사용합니다.

    SCALAR에 대한 참조가 주어지면 옵션 값은 해시 객체 멤버가 아닌 참조가 나타내는 데이터에 저장됩니다. 이 경우 해시 멤버에 액세스하여 예상 값을 얻을 수 없습니다.

- \[ **action** => \] _coderef_

    매개변수 `action`은 옵션을 처리하기 위해 호출되는 코드 참조를 받습니다. `action =>` 레이블은 첫 번째 파라미터인 경우에만 생략할 수 있습니다.

    호출되면 해시 객체가 `$_`로 전달됩니다.

        has [ qw(left right both) ] => '=i';
        has "+both" => sub {
            $_->{left} = $_->{right} = $_[1];
        };

    이를 `"<>"`에 사용하여 모든 것을 잡을 수 있습니다. 이 경우 사양 매개변수는 중요하지 않으며 필요하지 않습니다.

        has ARGV => default => [];
        has "<>" => sub {
            push @{$_->{ARGV}}, $_[0];
        };

다음 매개변수는 모두 데이터 유효성 검사를 위한 것입니다. 첫 번째 `must`는 일반적인 유효성 검사기이며 무엇이든 구현할 수 있습니다. 나머지는 일반적인 규칙에 대한 지름길입니다.

- **must** => _coderef_ | \[ _coderef_ ... \]

    매개변수 `must`는 옵션 값의 유효성을 검사하기 위해 코드 참조를 받습니다. `action`과 동일한 인수를 받고 부울을 반환합니다. 다음 예제에서 옵션 **--답변**은 42만 유효한 값으로 사용합니다.

        has answer => '=i',
            must => sub { $_[1] == 42 };

    여러 코드 참조가 주어지면 모든 코드가 참을 반환해야 합니다.

        has answer => '=i',
            must => [ sub { $_[1] >= 42 }, sub { $_[1] <= 42 } ];

- **min** => _number_
- **max** => _number_

    인수의 최소 및 최대 한도를 설정합니다.

- **any** => _arrayref_ | qr/_regex_/

    유효한 문자열 매개변수 목록을 설정합니다. 각 항목은 문자열 또는 정규식 참조입니다. 인수는 주어진 목록의 모든 항목과 같거나 일치하는 경우에 유효합니다. 값이 arrayref가 아닌 경우 단일 항목 목록으로 간주됩니다(일반적으로 regexpref).

    다음 선언은 두 번째 선언이 대소문자를 구분하지 않는다는 점을 제외하면 거의 동일합니다.

        has question => '=s',
            any => [ 'life', 'universe', 'everything' ];

        has question => '=s',
            any => qr/^(life|universe|everything)$/i;

    선택적 인수를 사용하는 경우 목록에 기본값을 포함하는 것을 잊지 마세요. 그렇지 않으면 유효성 검사 오류가 발생합니다.

        has question => ':s',
            any => [ 'life', 'universe', 'everything', '' ];

# METHOD

## **new**

초기화된 해시 객체를 가져오는 클래스 메서드.

## **optspec**

`GetOptions` 함수에 전달할 수 있는 옵션 사양 목록을 반환합니다.

    GetOptions($obj->optspec)

`GetOptions`에는 해시 참조를 첫 번째 인자로 제공하여 값을 해시에 저장하는 기능이 있지만, 반드시 필요한 것은 아닙니다.

## **getopt** \[ _arrayref_ \]

호출자의 컨텍스트에 정의된 적절한 함수를 호출하여 옵션을 처리합니다.

    $obj->getopt

    $obj->getopt(\@argv);

위의 예는 다음 코드를 위한 단축키입니다.

    GetOptions($obj->optspec)

    GetOptionsFromArray(\@argv, $obj->optspec)

## **use\_keys** _keys_

해시 키는 `Hash::Util::lock_keys`에 의해 보호되므로 존재하지 않는 멤버에 액세스하면 오류가 발생합니다. 이 함수를 사용하여 사용하기 전에 새 멤버 키를 선언하세요.

    $obj->use_keys( qw(foo bar) );

임의의 키에 액세스하려면 객체의 잠금을 해제하세요.

    use Hash::Util 'unlock_keys';
    unlock_keys %{$obj};

이 동작은 `configure`에서 `LOCK_KEYS` 매개변수를 사용하여 변경할 수 있습니다.

## **configure** **label** => _value_, ...

객체를 생성하기 전에 클래스 메서드 `Getopt::EX::Hashed->configure()`를 사용하면 이 정보가 패키지 호출을 위한 고유 영역에 저장됩니다. `new()`를 호출한 후 패키지 고유 구성이 객체에 복사되고 추가 작업에 사용됩니다. 객체 고유 구성을 업데이트하려면 `$obj->configure()`를 사용합니다.

다음과 같은 구성 매개변수가 있습니다.

- **LOCK\_KEYS** (default: 1)

    해시 키 잠금. 존재하지 않는 해시 항목에 실수로 액세스하는 것을 방지합니다.

- **REPLACE\_UNDERSCORE** (default: 1)

    밑줄이 대시로 대체된 별칭을 생성합니다.

- **REMOVE\_UNDERSCORE** (default: 0)

    밑줄이 제거된 별칭을 생성합니다.

- **GETOPT** (default: 'GetOptions')
- **GETOPT\_FROM\_ARRAY** (default: 'GetOptionsFromArray')

    `getopt` 메서드에서 호출되는 함수 이름을 설정합니다.

- **ACCESSOR\_PREFIX** (default: '')

    지정하면 멤버 이름 앞에 추가되어 접근자 메서드가 됩니다. `ACCESSOR_PREFIX`가 `opt_`로 정의된 경우, 멤버 `파일`에 대한 접근자는 `opt_file`이 됩니다.

- **ACCESSOR\_LVALUE** (default: 1)

    참이면 읽기-쓰기 액세스자는 lvalue 속성을 갖습니다. 이 동작이 마음에 들지 않으면 0으로 설정하세요.

- **DEFAULT**

    기본 매개변수를 설정합니다. `has` 호출 시 인수 매개변수 앞에 DEFAULT 매개변수가 삽입됩니다. 따라서 둘 다 동일한 매개변수를 포함하는 경우 인수 목록의 뒷부분에 있는 매개변수가 우선권을 갖습니다. `+`를 사용한 증분 호출은 영향을 받지 않습니다.

    DEFAULT의 일반적인 용도는 다음 모든 해시 항목에 대한 접근자 메서드를 준비하기 위해 `is`입니다. 재설정하려면 `DEFAULT => []`를 선언합니다.

        Getopt::EX::Hashed->configure(DEFAULT => [ is => 'ro' ]);

## **reset**

클래스를 원래 상태로 재설정합니다.

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

# POD ERRORS

Hey! **The above document had some coding errors, which are explained below:**

- Around line 3:

    Non-ASCII character seen before =encoding in 'Getopt::Long용'. Assuming UTF-8
