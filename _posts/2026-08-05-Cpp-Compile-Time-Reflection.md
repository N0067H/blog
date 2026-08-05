---
title: "C++ Compile Time Reflection"
date: 2026-08-05
excerpt: "C++26에 새로 추가된 Compile-time Reflection은 C++의 메타프로그래밍 방식을 크게 바꾸는 기능이다."
tags: cpp
---

C++26에 새로 추가된 **Compile-time Reflection**은 C++의 메타프로그래밍 방식을 크게 바꾸는 기능이다.

## C++26 Reflection의 핵심

기존 C++에서는 타입의 멤버 이름, 타입, 함수 목록 같은 정보를 언어 차원에서 얻을 방법이 없었다.

```cpp
struct Person {
    std::string name;
    int age;
};
```

이전까지는 매크로나 코드 생성기, 혹은 라이브러리마다 별도의 등록 과정을 거쳐야만 이러한 정보를 활용할 수 있었다.

C++26에서는 **Reflection Operator(`^^`)**를 통해 타입의 메타 정보를 가져올 수 있다.

```cpp
constexpr auto r = ^^Person;
```

`^^` 연산자는 타입이나 함수, 변수 등을 나타내는 메타 객체를 생성한다.

## 메타 객체 (std::meta::info)

```cpp
constexpr auto info = ^^Person;
```

여기서 `info`는 실제 `Person` 객체가 아니라 `std::meta::info` 타입의 opaque한 메타 객체이다. 즉, 내부 표현에는 직접 접근할 수 없으며, Reflection API를 통해서만 사용할 수 있다.

이 메타 객체를 질의 함수에 전달하면 다양한 정보를 얻을 수 있다.

```cpp
members_of(info);
bases_of(info);
enumerators_of(info);
```

예를 들어 `members_of()`는 클래스의 멤버 목록을, `bases_of()`는 상속받은 기반 클래스를, `enumerators_of()`는 enum의 열거자를 반환한다.

## Splicing

Reflection의 핵심은 메타 정보를 읽는 것이 아니라, 그 정보를 이용해 새로운 코드를 생성하는 것이다. 이를 **Splicing**이라고 한다.

Splicing은 `[: ... :]` 문법을 사용한다.

```cpp
obj.[:member:]
```

여기서 `member`가 `age`를 나타내는 메타 객체라면 컴파일러는 이를

```cpp
obj.age
```

로 치환한다.

즉, 메타 객체를 실제 C++ 코드로 다시 삽입하는 과정이 바로 Splicing이다.

## 이제 가능한 것들

예를 들어 다음과 같은 구조체가 있다고 하자.

```cpp
struct Person {
    std::string name;
    int age;
};
```

이제 JSON 라이브러리에서는

```cpp
serialize(person);
```

처럼 함수 하나만 호출해도 컴파일 타임에 `name`, `age` 등의 멤버를 자동으로 순회하여 직렬화 코드를 생성할 수 있다.

이 외에도 Reflection을 이용하면 다음과 같은 작업을 별도의 등록 과정 없이 구현할 수 있다.

* JSON/XML 직렬화
* ORM(Object-Relational Mapping)
* RPC 코드 생성
* GUI Property Editor
* 자동 비교 연산 및 디버그 출력
* 다양한 메타프로그래밍 기반 라이브러리

## Template Metaprogramming과의 차이

기존 Template Metaprogramming(TMP)은 타입을 조작하는 데 매우 강력했다.

예를 들어

```cpp
std::tuple<int, float, double>
```

같은 타입 리스트를 다루거나 타입 계산을 수행하는 것은 TMP의 대표적인 활용 사례이다.

하지만

```cpp
struct Person {
    int age;
    std::string name;
};
```

처럼 사용자 정의 타입의 멤버 이름, 멤버 개수, 접근 지정자 등의 정보는 언어 차원에서 알 수 없었다.

반면 C++26 Reflection은 컴파일러가 가지고 있는 AST 기반 메타데이터를 노출하므로 이러한 정보까지 직접 다룰 수 있다. 덕분에 기존에는 매크로나 코드 생성기로 해결하던 문제들을 순수 C++만으로 구현할 수 있게 되었다.

## 결론

개인적으로는 C++20의 Concepts 이후 가장 큰 변화라고 생각한다.

특히 직렬화, ORM, RPC, GUI 프레임워크처럼 메타데이터를 많이 활용하는 분야에서는 매크로나 외부 코드 생성기에 대한 의존도를 크게 줄일 수 있을 것 같다.

실제로 C++ 직렬화 라이브러리인 Glaze 역시 C++26 Reflection을 활용한 실험적인 기능을 추가하며 이를 적극적으로 활용하기 시작했다고 한다.
