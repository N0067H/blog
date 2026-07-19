---
title: "C++ map contains vs find"
date: 2026-07-19
excerpt: "C++의 표준 라이브러리인 std::map, std::unordered_map에서 contains()와 find()의 차이를 정리했다."
tags: cpp
---

C++의 표준 라이브러리인 `std::map`, `std::unordered_map`에서 `contains()`와 `find()`의 차이를 정리했다.

## 1. map & unordered_map

`std::map`과 `std::unordered_map`은 모두 Key-Value 형태의 연관 컨테이너지만 내부 구현이 다르다.

- `std::map`은 일반적으로 Red-Black Tree로 구현되며, 키가 항상 정렬된 상태를 유지한다.
- `std::unordered_map`은 Hash Table로 구현되며, 키의 순서를 보장하지 않는다.

```cpp
std::map<std::string, std::string> contacts;
std::unordered_map<std::string, Point> users;
```

## 2. Key를 조회하는 방법

### 2.1. operator[]

가장 단순한 방법이다.
```cpp
auto phone = contacts["SeungYeop"];
```
이 방법은 해당 키가 존재하지 않으면 새로운 키를 저장한다.\
따라서 단순히 존재 여부만 확인하려는 경우에는 불필요한 삽입과 생성이 발생할 수 있으므로 주의해야 한다.

### 2.2. find() 함수

C++20 이전에는 키의 존재 여부를 확인할 때 가장 많이 사용하던 방법이다.

```cpp
auto it = contacts.find("SeungYeop");

if (it != contacts.end()) {
    std::cout << "Found\n";
} else {
    std::cout << "Not Found\n";
}
```

`find()`는 키를 찾으면 해당 원소를 가리키는 iterator를 반환하고, 찾지 못하면 `end()`를 반환한다.

값을 바로 사용할 예정이라면 `find()`가 가장 효율적인 선택이다.

```cpp
if (auto it = contacts.find("SeungYeop"); it != contacts.end()) {
    std::cout << it->second << '\n';
}
```

탐색을 한 번만 수행하기 때문이다.

### 2.3. contains() 함수

C++20에 추가된 함수다.

```cpp
if (contacts.contains("SeungYeop")) {
    std::cout << "Found\n";
} else {
    std::cout << "Not Found\n";
}
```
반환값이 `bool`이라 존재 여부만 확인할 때는 `find()`보다 코드가 훨씬 간결하다.

하지만 값을 바로 사용할 예정이라면 주의해야 한다.

```cpp
if (contacts.contains("SeungYeop")) {
    std::cout << contacts["SeungYeop"] << '\n';
}
```
위 코드는 `contains()`에서 한 번 탐색하고, `operator[]`에서 다시 한 번 탐색한다.\
즉, 같은 키를 두 번 조회하게 된다.

## %. 여담
사소한 내용이지만, 가장 좋아하는 언어인 C++에 대해 조금씩이라도 기록을 남기고 싶어 정리했다.\
최근에는 Spring과 Rust를 주로 공부하다 보니 C++를 다룰 시간이 많이 줄었는데, 가끔은 이렇게 기본 라이브러리나 언어 자체를 다시 살펴보는 것도 재미있는 것 같다.