---
title: "Rust dyn-compatible"
date: 2026-07-24
excerpt: "시스템 디자인은 단순히 서버, 데이터베이스, 캐시를 그림으로 배치하는 작업이 아니다."
tags: rust
---

예전에는 이 개념을 `object safety`라고 불렀고, 지금은 Rust 공식 문서에서 `dyn compatibility`라는 용어를 사용한다.\
쉽게 말하면 이 `trait`을 `dyn Trait`로 사용할 수 있는가를 의미한다.

예를 들어

```rs
trait Animal {
    fn speak(&self);
}
```
는 가능하다.

런타임에서 vtable을 통해 호출할 수 있기 때문이다.
```rs
let animal: Box<dyn Animal>;
```

예를 들어
```rs
trait Foo {
    fn clone(&self) -> Self;
}
```
이 trait은 dyn-compatible하지 않다. `dyn Foo`가 어떤 타입인지 모른다.

이때 fn clone(&self) -> Self