---
title: "C++ vector push_back() vs emplace_back()"
date: 2026-07-19
excerpt: "대부분의 경우 push_back()이 더 의도가 명확하고, emplace_back()이 반드시 더 좋은 것은 아니다. 그 이유를 알아보자."
tags: cpp
---

옛날에 본 영상 하나가 있었는데, `emplace_back()`을 무작정 옹호하는 내용이였다.\
어떻게 보면 대부분의 경우 `push_back()`이 더 의도가 명확하고, `emplace_back()`이 반드시 더 좋은 것은 아니다.

## 1. 이미 객체가 있는 경우

이미 객체가 있는 경우, `push_back()`이 더 알맞은 선택이다.

```cpp
std::vector<std::string> v;
std::string s = "hello";

v.push_back(s);
v.push_back(std::move(s));
```

이때 `push_back()`이 아닌, `emplace_back()`을 쓰더라도 결과는 거의 동일하다. `emplace_back()`은 전달받은 인자를 그대로 생성자의 인자로 넘겨줄 뿐이므로, 내부적으로 `std::string(s);`를 호출하는 것과 같다.

즉, 이미 객체가 있다면 `push_back()`이 의미를 더 잘 드러낸다.

## 2. 생성자를 직접 호출하는 경우

이때는 `emplace_back()`이 분명히 나은 선택일 것이다.

```cpp
std::vector<std::pair<int, std::string>> v;
v.emplace_back(1, "hello");
```

두 값을 넣는다는 의미를 더 잘 드러낸다.

만약 `push_back()`이라면

```cpp
v.push_back(std::pair<int, std::string>(1, "hello"));
```
처럼 임시 객체를 만들어 넣어야 한다.


## 3. overload 문제

`emplace_back()`은 **perfect forwarding**이라는 템플릿 기법을 사용하기 때문에 생각보다 이상한 생성자가 선택될 수도 있다.

예를 들면, 아래와 같은 코드가 있다.
```cpp
std::vector<std::vector<int>> v;
v.emplace_back(10, 20);
```
우리는 `std::vector<int, int>{10, 20}`을 기대했겠지만, 내부적으론 `std::vector<int>(10, 20)`이 생성된다.

여기서 `push_back()`을 사용한다면
```
v.push_back({10, 20});
```
우리가 원하는 결과가 들어간다.

이처럼 `emplace_back()`은 생성자 오버로드 때문에 의도와 다른 동작을 만들기 쉽다.

## 4. 성능 차이는 대부분 없다

많은 사람들이 `emplace_back()`이 항상 더 빠르다고 생각하지만 대부분 틀린 이야기다.

예를 들면

```cpp
std::string s = "abc";
v.push_back(std::move(s));
v.emplace_back(std::move(s));
```

두 가지 방법 모두 거의 동일한 코드가 생성된다.

또한 아래처럼 임시 객체를 넣는 경우에도

```cpp
v.push_back(A{1,2,3});
```
C++17 이후에는 복사 생략과 이동 최적화 덕분에 `emplace_back()`과 차이가 없는 경우가 많다.

실제로 성능 차이가 나는 대표적인 경우는

```cpp
v.emplace_back(arg1, arg2, arg3);
```

처럼 임시 객체 자체를 만들지 않고, 컨테이너 내부에서 직접 생성할 때다.

## %. 결론

쉽게 말해 이미 객체가 있으면 `push_back()`, 객체를 인라인으로 생성한다면 `emplace_back()`을 쓰면 된다.

```cpp
std::string s = "hello";

v.push_back(s);
v.push_back(std::move(s));

v.emplace_back("hello");
v.emplace_back(10, 'a');

v.emplace_back(s); // 이것도 가능하지만
v.push_back(s);    // 이게 읽기가 더 좋다
```

즉, `emplace_back()`은 `push_back()`의 상위호환이라기보다, 생성자 인자를 직접 전달해 컨테이너 안에서 객체를 생성하고 싶을 때 쓰는 함수다.
