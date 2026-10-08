---
title: "C++ Compile Time Reflection"
date: 2026-08-05
excerpt: "C++26의 Compile-time Reflection을 소개합니다."
tags: lang, cpp
---

이번 글에서는 C++26에 새로 추가된 **Compile-time Reflection**을 소개해보려고 합니다. C++의 메타프로그래밍 방식을 크게 바꾸는 기능입니다. 어떤 정보를 얻을 수 있고, 그걸 어떻게 코드에 활용하는지 살펴보겠습니다.

## 0. Intro

먼저 기존 C++에서 어떤 점이 불편했는지부터 보겠습니다. 타입의 멤버 이름, 타입, 함수 목록 같은 정보를 언어 차원에서 얻을 방법이 없었습니다. 아래처럼 간단한 구조체라도 마찬가지입니다.

```cpp
struct Person {
    std::string name;
    int age;
};
```

이 구조체의 멤버 정보를 활용하려면 이전까지는 매크로나 코드 생성기, 혹은 라이브러리마다 별도의 등록 과정을 거쳐야 했습니다.

이제 C++26에서는 **Reflection Operator(`^^`)**&#8203;를 통해 타입의 메타 정보를 가져올 수 있습니다. 사용 방법은 아래처럼 꽤 간단합니다.

```cpp
constexpr auto r = ^^Person;
```

`^^` 연산자는 타입이나 함수, 변수 등을 나타내는 메타 객체를 생성합니다.

## 1. The Core Type: `std::meta::info`

그럼 `^^`로 가져온 메타 정보가 어떤 타입인지 조금 더 자세히 보겠습니다.

```cpp
constexpr auto info = ^^Person;
```

여기서 `info`는 실제 `Person` 객체가 아니라 `std::meta::info` 타입의 opaque한 메타 객체입니다. 내부 표현에는 직접 접근할 수 없고, Reflection API를 통해서만 사용할 수 있다는 뜻입니다.

이 메타 객체를 질의 함수에 전달하면 다양한 정보를 얻을 수 있습니다. 어떤 정보를 조회할지는 사용하는 함수에 따라 달라집니다.

```cpp
members_of(info);
bases_of(info);
enumerators_of(info);
```

예를 들어 `members_of()`는 클래스의 멤버 목록을, `bases_of()`는 상속받은 기반 클래스를, `enumerators_of()`는 enum의 열거자를 반환합니다.

## 2. Splicing

이렇게 얻은 메타 정보를 실제 코드에 활용하는 방법도 보겠습니다. Reflection의 핵심은 메타 정보를 읽는 데서 끝나는 것이 아니라, 그 정보를 이용해 새로운 코드를 생성하는 것입니다. 이때 사용하는 기능이 **Splicing**입니다.

Splicing은 `[: ... :]` 문법을 사용합니다.

```cpp
obj.[:member:]
```

여기서 `member`가 `age`를 나타내는 메타 객체라면, 컴파일러는 위 코드를 아래처럼 치환합니다.

```cpp
obj.age
```

즉, 메타 객체로 얻은 정보를 다시 실제 C++ 코드에 연결하는 과정입니다. 이게 바로 Splicing입니다.

## 3. Newly Supported

그럼 이런 기능이 어디에 유용한지도 보겠습니다. 예를 들어 다음과 같은 구조체가 있다고 해봅시다.

```cpp
struct Person {
    std::string name;
    int age;
};
```

이 구조체를 JSON으로 직렬화한다고 하면, Reflection을 활용하는 라이브러리에서는 아래처럼 작성할 수 있습니다.

```cpp
serialize(person);
```

함수 하나만 호출해도 컴파일 타임에 `name`, `age` 등의 멤버를 자동으로 순회하여 직렬화 코드를 생성할 수 있습니다. 타입마다 멤버 목록을 따로 등록할 필요가 없어지는 셈입니다.

이 외에도 Reflection을 이용하면 다음과 같은 작업을 별도의 등록 과정 없이 구현할 수 있습니다.

- JSON/XML 직렬화
- ORM(Object-Relational Mapping)
- RPC 코드 생성
- GUI Property Editor
- 자동 비교 연산 및 디버그 출력
- 다양한 메타프로그래밍 기반 라이브러리

## 4. vs. Template Metaprogramming

여기까지 보면 기존 Template Metaprogramming(TMP)과는 뭐가 다른지 궁금할 수 있습니다. TMP도 타입을 조작하는 데 매우 강력했습니다.

예를 들어 아래와 같은 타입 리스트를 다루거나 타입 계산을 수행하는 것은 TMP의 대표적인 활용 사례입니다.

```cpp
std::tuple<int, float, double>
```

하지만 아래처럼 사용자 정의 타입이 있을 때, 멤버 이름, 멤버 개수, 접근 지정자 등의 정보는 언어 차원에서 알 수 없었습니다.

```cpp
struct Person {
    int age;
    std::string name;
};
```

반면 C++26 Reflection은 컴파일러가 가지고 있는 AST 기반 메타데이터를 노출하므로 이러한 정보까지 직접 다룰 수 있습니다. 차이는 계산 능력보다 접근할 수 있는 정보의 범위에 있는 셈입니다. 덕분에 기존에는 매크로나 코드 생성기로 해결하던 문제들을 순수 C++만으로 구현할 수 있게 되었습니다.

## 5. Wrapping Up

이렇게 타입 정보를 가져오는 것부터 실제 코드에 활용하는 것까지 간단히 살펴봤습니다. 개인적으로는 C++20의 Concepts 이후 가장 큰 변화라고 생각합니다.

특히 직렬화, ORM, RPC, GUI 프레임워크처럼 메타데이터를 많이 활용하는 분야에서는 매크로나 외부 코드 생성기에 대한 의존도를 크게 줄일 수 있을 것 같습니다.

실제로 C++ 직렬화 라이브러리인 Glaze 역시 C++26 Reflection을 활용한 실험적인 기능을 추가하며 이를 적극적으로 활용하기 시작했다고 합니다.
