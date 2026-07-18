---
title: "The Practice of Programming"
date: 2026-07-18
tags: book
---

**Helping make individual programmers more effective and productive, this book contains practical advice and real-world examples in C, C++, Java, and a variety of special-purpose languages.**

프로그래머를 더욱 효과적이고 생산적으로 만들어 주는 실용적인 프로그래밍 지침서라고 한다.

학기말과 방학을 빌려서 몇년은 미룬 책을 드디어 읽었다. 분량이 많기 때문에 핵심적인 내용만 추려 정리했다.

## 1. Style

코드를 작성할 때, 컴퓨터가 아닌 사람이 읽기 쉽게 작성해야 한다.

- 의미 있는 이름을 사용한다.
- 함수는 짧게 만든다.
- 함수는 한 가지 일만 한다.
- 불필요한 트릭을 쓰지 않는다.
- 일관성을 유지한다.

예를 들어 배열의 평균을 구하는 함수를 작성한다면

나쁜 예:

```cpp
double f(std::vector<int> a) {
    double x = 0;

    for (int i = 0; i < a.size(); i++) {
        x += a[i];
    }

    return a.size() ? x / a.size() : 0;
}
```

좋은 예:

```cpp
double calculate_average(const std::vector<int>& numbers) {
    if (numbers.empty()) {
        return 0.0;
    }

    int sum = 0;

    for (int number : numbers) {
        sum += number;
    }

    return static_cast<double>(sum) / numbers.size();
}
```

누구나 알고는 있지만, 잘 지켜지지 않는 당연한 규칙이다.

## 2. Data Structures & Algorithms

컴퓨터는 근본적으로 데이터 처리 장치다. 떄문에 문제를 해결하기 위한 알고리즘을 미세 최적화하는 것보다, 데이터를 다루는 자료구조를 문제에 맞게 선택하는 것이 더 중요하다.

회원이 차단 목록에 있는지 조회하는 함수를 `vector` 조회 방식으로 만들었다.

```cpp
bool IsBlacklisted(
    const std::vector<std::string>& blacklist,
    const std::string& user
) {
    return std::find(
        blacklist.begin(),
        blacklist.end(),
        user
    ) != blacklist.end();
}
```

이걸 `unordered_set` 기반으로 바꾸면

```cpp
bool IsBlacklisted(
    const std::unordered_set<std::string>& blacklist,
    const std::string& user
) {
    return blacklist.contains(user);
}
```
이렇게나 간결해진다.

## 3. Design

처음부터 완벽한 설계는 불필요하다. 일단 간단하게 만들고, 사용해보고, 고치는 과정을 반복하는 **점진적 개선(iterative refinement)**이 중요하다.

### 3.1. 처음 설계는 거의 틀린다

우리는 처음부터 문제를 완벽하게 이해할 수가 없다. 처음에는 요구사항도, 문제의 본질도 완전히 알 수 없다.

예를 들어 학생 관리 프로그램을 만들어본다고 하면 처음에는 아래와 같이 생각할 수 있다.

```
Student
 ㄴ name
 ㄴ age
 ㄴ grade
```

처음에는 충분하다고 생각할 수도 있는데, 개발하다 보면 복수 전공, 휴학생, 학점 계산 등 다양한 로직의 필요성이 눈에 보일 것이다.

### 3.2. 작은 변경보다 큰 변경 비용이 더 비싸다

처음부터 모든 경우를 고려하려고 하다 보면 아래와 같이 코드가 복잡해진다.

```
if (mode == A) ...
else if (mode == B) ...
else if (mode == C) ...
else if (mode == D) ...
// E, F, G, ......
```

전부 다 고려했지만, 실제로는 A와 B만 필요한 경우가 많다. 필요해질 때 추가하면 코드도 단순하고, 잘못된 가정을 할 가능성도 줄어드는데, 이를 흔히 **YAGNI(You Aren't Gonna Need It)** 원칙이라고도 한다.

### 3.3. 피드백이 최고의 설계 방법이다

설계할 때는 몰랐지만, 코드를 직접 써 보면서 알게 되는 것들이 있다.

예를 들어 아래와 같이 API를 설계했다고 하자.

```cpp
db.insert(user);
```

처음에는 좋아 보였지만, 실제로 써 보니

```cpp
db.insert(user);
db.commit();
```

을 매번 호출해야 해서 불편하다.

그러면
```
db.insert(user);
```
호출 한번으로 자동 커밋하도록 바꿀 수도 있다.

### 3.4. 리팩토링은 실패가 아니라 과정이다

코딩을 처음 접하면 처음부터 예쁘게 해야 한다는 강박이 있는 경우가 있다. 하지만 경험이 많은 개발자라면 일단 돌아가게 만들고, 이해가 생긴 후 구조를 개선한다는 접근을 한다.

최댓값을 찾는 함수를 일단 돌아가게, 단순무식하게 구현한다면 아래와 같이 반복+분기로 작성할 수 있다.

```cpp
int find_max(const std::vector<int>& numbers) {
    int m = numbers[0];

    for (int i = 1; i < numbers.size(); i++) {
        if (numbers[i] > m) {
            m = numbers[i];
        }
    }

    return m;
}
```
처음에는 동작하는 것이 목표였기 때문에 특별한 추상화는 없다.\
여기서 최댓값을 찾는다는 의도가 STL에서 제공하는 알고리즘 함수와 정확히 일치한다는 것을 알 수 있다.

```cpp
int find_max(const std::vector<int>& numbers) {
    return *std::max_element(numbers.begin(), numbers.end());
}
```

즉, 이렇게 리팩토링이 가능하다.

### 3.5. 소프트웨어는 계속 변한다

현실에서는 요구사항이 계속 바뀐다. 새로운 기능 추가, 버그 수정, 성능 개선, 사용자 피드백 반영 등. 한번에 완벽한 설계를 만들려고 하기보다, 변화하기 쉬운 구조를 유지하는 것이 더 중요하다.

## 4. Interfaces

구현보다 중요한 건 인터페이스다. 좋은 API는 사용하기 쉽고, 실수하기는 어렵고, 내부 구현을 숨긴다.

예를 들어 정수 벡터에 새로운 값을 집어넣는 코드를 보자.
```cpp
std::vector<int> vec;
vec.push_back(10);
```
이런 코드를 사용할 때 우리는 벡터가 메모리를 언제 재할당하는지, 용량(capacity)을 어떻게 늘리는지, 기존 원소를 어떻게 이동하는지 알 필요가 없다. `push_back`이라는 인터페이스가 이런 구현 세부사항을 모두 감춰 주기 때문이다.

만약 추상화가 없었다면 `push_back`의 인터페이스(시그니처)는 아마 이렇게 끔찍했을 것이다.
```cpp
void push_back(
    int*& data,
    std::size_t& size,
    std::size_t& capacity,
    int value
);
```

사용자는 값을 추가하기 위해 벡터의 내부 상태(data, size, capacity)까지 직접 관리해야 한다.\
좋은 인터페이스는 사용자의 부담을 줄이고, 실수할 여지를 없애며, 구현을 바꿔도 사용 코드는 그대로 둘 수 있게 만든다.

## 5. Debugging

아마 대부분의 초보 개발자는 아래와 같은 방법을 사용할 것이다.
```
코드 수정 -> 실행 -> 기도
```
가끔은 이런 식의 삽질이 문제를 해결하기도 하지만, 개인적으론 영 별로다.

버그는 다음 순서로 접근하는 것이 훨씬 효과적이다.

```cpp
재현 -> 가설 -> 실험 -> 원인 확인
```

- **재현:** 언제, 어떤 조건에서 버그가 발생하는지 확인한다.
- **가설:** 원인이 될 만한 부분을 추측한다.
- **실험:** 최소한의 변경으로 검증한다.
- **원인 확인:** 실제 원인을 확인한 후 수정한다.

내 경험상 가장 어려운 단계는 버그를 안정적으로 재현하는 것이다. 재현이 되지 않으면 가설도 세우기 어렵고, 실험 결과 역시 신뢰하기 힘들다. 반대로 재현만 확실하다면 원인을 찾는 과정은 훨씬 수월해진다.

## 6. Testing

테스트는 버그픽스가 아닌, 신뢰를 위한 것이다.\
엣지케이스나 NULL, 엄청 큰 입력, 예외 상황 등을 테스트하고 검증해야 한다.

예를 들어 `max()` 함수를 구현했다면 다음과 같은 테스트를 작성할 수 있다.
```cpp
EXPECT_EQ(max({1, 2, 3}), 3);
EXPECT_EQ(max({5}), 5);
EXPECT_EQ(max({-3, -1, -5}), -1);
EXPECT_EQ(max({INT_MIN, INT_MAX}), INT_MAX);
EXPECT_THROW(max({}), std::invalid_argument);
```

정상적인 경우뿐 아니라, 실패하거나 경계에 있는 경우까지 검증해야 코드에 대한 신뢰도가 올라간다.

## 7. Performance

측정하기 전에는 최적화하면 안 된다. 많은 사람들이 병목이 있다고 추측하는 부분은 실제 병목과 다른 경우가 많다. 직감에 의존한 최적화는 시간만 낭비하고, 오히려 코드를 더 복잡하게 만들기도 한다.

최적화의 순서는 아래와 같다.
```
프로그램 작성 -> 측정 -> 병목 발견 -> 그 부분만 최적화
```

성능이 느리다는 이유만으로 캐시를 추가하거나, 큐를 도입하거나, 복잡한 자료구조로 바꾸는 경우가 있다. 하지만 프로파일링을 해 보면 실제 병목은 전혀 다른 함수나 I/O, 데이터베이스, 네트워크 통신인 경우도 흔하다.

최적화는 필요한 곳에만, 측정 결과를 근거로 수행해야 한다.

## 8. Portability

운영체제나 컴파일러에 의존하면 안 된다. 또한, 단일 플랫폼에서만 돌아가는 코드를 작성하거나 특정 컴파일러만 지원하는 문법은 최소화해야 한다.

가장 대표적으로 타입의 크기 계산 문제다.
```cpp
int x;
static_assert(sizeof(int) == 4);
```

다음은 WinAPI에 의존하는 경우다.
```cpp
Sleep(1000);
```

마지막으로 컴파일러 확장인데, 대부분이 가장 처음 접했던 `scanf_s()` 정도가 있다.
```
scanf_s("%d", &x);
```

가능한 아래처럼 표준 라이브러리 기능을 우선 사용하는 것이 좋다.
```cpp
std::int32_t value;
std::this_thread::sleep_for(std::chrono::seconds(1));
std::cin >> value;
```
플랫폼에 종속된 코드는 꼭 필요한 경우에만 사용하는 것이 바람직하다.


## 9. Notation

복잡한 문제는 곧바로 코드로 옮기려 하지 말고, 먼저 좋은 표기법을 만드는 것부터 시작하면 쉬워진다.

예를 들어 좌표를 x1, x2, x3, y1, y2, y3처럼 흩어져 표현하는 것보다

```cpp
struct Point {
    int x;
    int y;
};
```

처럼 의미를 담은 자료형으로 표현하면 코드의 의도가 훨씬 명확해진다.

## %. 총평

AI의 영향으로 이런 내용이 요즘 개발 트렌드와는 다소 거리가 있어 보일 수도 있다. 하지만 원칙 자체는 여전히 유효하고, 한 번쯤은 차분히 읽어볼 가치가 있는 책이라고 생각한다.

특히 아직 프로그래밍에 익숙하지 않은 사람이라면 흔히 저지르는 실수를 돌아보고, 좋은 개발 습관을 익히는 데 큰 도움이 될 것 같다.
