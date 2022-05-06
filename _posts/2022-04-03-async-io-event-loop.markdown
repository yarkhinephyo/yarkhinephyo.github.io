---
layout: post
title: "Generators - The Beginning of Asynchronicity in Python"
date: 2022-04-03 17:00:00 +0800
category: [Tech]
tags: [Python, Concurrency, Software-Engineering]
excerpt: How Python generators are related to the async-await keywords.
---

If you have worked with asynchronous programming in Python, you may have used the `async` and `await` keywords before. It turns out that Python Generators are actually the building blocks of these abstractions. This article explain their relationship in a greater detail.

### Coroutines

For single-threaded asynchronous programming to work in Python, we need a mechanism to "pause" function calls. For example if a particular function involves fetching something from a database, we would like to "pause" the function's execution and schedule something else until the response is received. However in traditional Python functions, the `return` keyword frees up the internal state at the end of invocation...

It turns out that generators in Python can achieve similar purpose! With generators, the `yield` keyword gives up the control of the thread while the internal state is saved until the next invocation. So we can do some multitasking with a scheduler as shown below.

```python
def gen_one():
    print("Gen one doing some work")
    yield
    print("Gen one doing more work")
    yield

def gen_two():
    print("Gen two doing some work")
    yield
    print("Gen two doing more work")
    yield

def scheduler():
    g1 = gen_one()
    g2 = gen_two()
    next(g1)
    next(g2)
    next(g1)
    next(g2)
```

```
>>> scheduler()
Gen one doing some work
Gen two doing some work
Gen one doing more work
Gen two doing more work
```

Coroutine is the term for suspendable functions. As generators cannot take in values like normal functions, new methods are introduced in PEP 342 including `.send()` that allows passing of parameters (and also `.throw()` and `.close()`).

```python
def coroutine_one():
    print("Coroutine one doing some work")
    data = (yield)
    print(f"Received data: {data}")
    print("Coroutine one doing more work")
    yield

cor1 = coroutine_one()
cor1.send(None)
cor1.send("lorem ipsum")
``` 

```
Coroutine one doing some work
Received data: lorem ipsum
Coroutine one doing more work
```

Let's refer to generators as coroutines from now.

### Nested coroutines

Another problem we have is that nested coroutines would not work with current syntax. As shown below, how will `coroutine_three()` call `coroutine_one()` and `coroutine_two()`? It is just a function that has two coroutine objects but has no ability to schedule them!

```python
def coroutine_one():
    print("Coroutine one doing some work")
    yield
    print("Coroutine one doing more work")
    yield

def coroutine_two():
    print("Coroutine two doing some work")
    yield
    print("Coroutine two doing more work")
    yield

# Will not work as intended
def coroutine_three():
    coroutine_one()
    coroutine_two()
```

To solve this, PEP 380 introduces the `yield from` operator. This allows a section of code containing `yield` to be factored out and placed in another generator. So in essence the `yield` calls are "flattened" so that the same scheduler that handles `coroutine_three()` can handle the nested coroutines. Furthermore, if the inner coroutines use `return`, the values can made available to `coroutine_three()`, just like traditional nested functions!

```python
def coroutine_three():
    yield from coroutine_one()
    yield from coroutine_two()

# Equivalent code
# The 'yield' calls in subgenerators are flattened
def coroutine_three():
    print("Coroutine one doing some work")
    yield
    print("Coroutine one doing more work")
    yield
    print("Coroutine two doing some work")
    yield
    print("Coroutine two doing more work")
    yield
```

### Better scheduler function

The previous scheduler in the example interleaves the two coroutines manually. A more automatic implementation will be using a queue as shown below.

```python
from collections import deque

def scheduler(coroutines):
    q = deque(coroutines)
    while q:
        try:
            coroutine = q.popleft()
            results = coroutine.send(None)
            q.append(coroutine)
        except StopIteration:
            pass
```

```
>>> scheduler([coroutine_one(), coroutine_two()])
Coroutine one doing some work
Coroutine two doing some work
Coroutine one doing more work
Coroutine two doing more work
```

### How coroutines help with asynchronous I/O

During I/O operations, a synchronous function will block the main thread until the I/O is ready. To carry out asychronous work on a single thread, a good way is for the scheduler to check all the coroutines in the queue and only allow those which are "ready" to run.

In the example below, `coroutine_four()` has to fetch data through I/O operation. While it is suspended as the kernel populates the read buffer, the scheduler allows other coroutines to occupy the thread. The scheduler only allows `coroutine_four()` to execute again when the I/O is ready.

```python
def fetch_data():
    print("Fetching data awaiting IO..")
    # Suspends coroutine while awaiting IO to be ready
    yield

    # Let's assume that the scheduler only reschedules
    # the coroutine again when IO is ready
    print("Fetching data IO ready..")
    # Mocked data
    return 10

def coroutine_four():
    print("Coroutine four doing some work")
    data = yield from fetch_data() # I/O related coroutine
    print("Coroutine four doing more work with data: " + str(data))
    yield
```

```
>>> scheduler([coroutine_one(), coroutine_four()])
Coroutine one doing some work
Coroutine four doing some work
Fetching data awaiting IO..
Coroutine one doing more work
Fetching data IO ready..
Coroutine four doing more work with data: 10
```

### How does the scheduler check for I/O completion?

In the previous example, the I/O completion is mocked inside the `fetch_data()` coroutine. In reality, how does the scheduler know when the I/O is complete?

This is where [AsyncIO](https://docs.python.org/3/library/asyncio.html) library comes in. It introduces concepts called `Future` and the Event Loop. `Future` objects are just coroutines that track whether the results (such as I/O) are ready or not. The Event Loop is just a for-loop that continuously schedules and runs coroutines, similar to our `scheduler()` function in the examples. At each iteration, the scheduler also [polls](https://man7.org/linux/man-pages/man2/poll.2.html) for I/O operations to see which file descriptors are ready for I/O.

In essence, this is the pseudocode of the Event Loop in `asyncio`.

```
while the event loop is not stopped:
    poll for I/O and schedule reads/writes that are ready
    schedule the coroutines set for a 'later' time
    run the scheduled coroutines
```

### Cleaner code with async-await

Even though coroutines work well with the `yield` keyword of generators, it was not the original intention of the feature. From Python 3.5 onwards, coroutines were made first-class features with the introduction of `async` and `await` keywords.

There are some implementation differences but the main features remain the same. For example, assuming that `fetch_data()` returns an awaitable object, the `coroutine_four()` can be rewritten as shown below.

```python
async def coroutine_four():
    print("Coroutine four doing some work")
    data = await fetch_data()
    print("Coroutine four doing more work with data: " + str(data))
```

The same coroutine methods such as `.send()` will still work but the purpose now a lot clearer!

### Resources

1. [AsyncIO Event Loop by EdgeDB](https://www.youtube.com/watch?v=E7Yn5biBZ58&list=FLQyA0IDUNh2fQuGTZ2CEjug&index=3)
2. [AsyncIO by Real Python](https://realpython.com/async-io-python/)
3. [Yield to Async-await by Mleue](https://mleue.com/posts/yield-to-async-await/)
4. [Event Loop by Lei Mao](https://leimao.github.io/blog/Python-AsyncIO-Event-Loop/)
