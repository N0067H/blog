---
title: "C++ Compile Time Reflection"
date: 2026-08-05
excerpt: "C++26의 Compile-time Reflection에 대해 알아보자."
tags: lang, cpp
---

이번 Major 업데이트인 C++26에는 **Compile-time Reflection**이라는 기능이 나왔다. 말 그대로 리플렉션을 런타임이 아닌 컴파일타임에 가능하게 해준다. 근데 그러면 리플렉션이 아닌 거 아닌가..?

> 리플렉션(Reflection)이란, 런타임에 객체가 자기 자신의 구조를 얻을 수 있는 스킬을 말한다.

## 0. Intro

C++23까지는 타입의 멤버 이름이나 멤버의 타입, 함수 목록같은 정보를 코드로 알아낼 방법이 없었다. 아래 `Person`처럼 단순한 구조체도 마찬가지다.

```cpp
struct Person {
    std::string name;
    int age;
};
```

코드에서 이 구조체의 멤버 정보를 사용하려면 `#define`같은 매크로나 외부 코드 제너레이팅 툴을 사용하든, 이미 구조체에 객체의 정보가 드러나 있음에도 라이브러리에 멤버 정보를 다시 작성해야 하는 귀찮음이 있었다.

이번 C++26 업데이트는 이런 귀찮음을 해소하기 위해 표준 문법으로 **Reflection Operator(`^^`)**&#8203;를 추가했다.

```cpp
constexpr auto r = ^^Person;
```

`^^` 연산자는 타입이나 함수, 변수 등을 나타내는 메타 객체를 생성한다.

## 1. The Core Type: `std::meta::info`

그럼 `^^`로 가져온 건 정확히 무슨 타입일까?

```cpp
constexpr auto info = ^^Person;
```

여기서 `info`는 실제 `Person` 객체가 아니라, `std::meta::info` 타입의 객체다. Opaque Type이라 내부 멤버를 직접 사용할 수는 없고, `<meta>` 헤더가 제공하는 함수로 다뤄야 한다.

```cpp
members_of(info);
bases_of(info);
enumerators_of(info);
```

예를 들어 `members_of()`는 클래스의 멤버 목록을, `bases_of()`는 상속받은 클래스 목록을, `enumerators_of()`는 `enum`의 멤버들을 반환한다.

## 2. Splicing

객체의 정보를 얻었으니 이제 사용하면 된다. 리플렉션은 메타데이터를 읽는 것뿐만 아니라, 코드를 생성할 수도 있다. 여기서 나오는 게 **Splicing**이라는 문법이다.

Splicing은 `[: ... :]` 문법을 사용한다.

```cpp
obj.[:member:]
```

`member`가 `age`를 나타내는 메타 객체라면, 컴파일러는 위 코드를 아래처럼 치환한다.

```cpp
obj.age
```

메타 객체가 가리키는 대상을 C++ 코드에 끼워 넣는 과정이라고 생각하면 된다.

## 3. Newly Supported

그래서 이걸 어디에 써먹을 수 있을까?

- JSON/XML 직렬화
- ORM(Object-Relational Mapping)
- RPC 코드 생성
- GUI Property Editor
- 자동 비교 연산 및 디버그 출력
- 다양한 메타프로그래밍 기반 라이브러리

등등, 멤버 정보가 필요한 작업에 유용하게 쓸 수 있다.

## 4. vs. Template Metaprogramming

이쯤 되면 Template Metaprogramming(TMP)으로도 하던 일이 아닌가 싶을 수 있다.

TMP는 타입 리스트를 다루거나 타입을 계산하는 일은 원래 잘 했다.

```cpp
std::tuple<int, float, double>
```

하지만 아래처럼 사용자 정의 타입이 있을 때 멤버 이름, 멤버 개수, 접근 제어 등의 정보는 코드에서 가져올 방법이 없었다.

```cpp
struct Person {
    int age;
    std::string name;
};
```

Compile-time Reflection은 컴파일러가 가진 AST 기반 메타데이터를 노출하기 때문에 이런 정보까지 직접 다룰 수 있다. 덕분에 매크로나 외부 코드 제너레이터에 의존하던 작업을 순수 C++로 구현할 방법이 생겼다.

## 5. Wrapping Up

당연한 말이지만 C++20의 Concepts 이후 가장 큰 변화가다. 솔직히 말해서 이번 업데이트도 문법이나 컨셉 자체가 괴랄하긴 하지만, 이건 고질병이라 그러려니 하면서 금방 익숙해질 것 같다. C++ 하면서 이런 문법 하루이틀 보나..

C++ 직렬화 라이브러리인 [Glaze](https://github.com/stephenberry/glaze)에도 리플렉션을 쓰는 실험적인 기능이 생겼다고 한다.
