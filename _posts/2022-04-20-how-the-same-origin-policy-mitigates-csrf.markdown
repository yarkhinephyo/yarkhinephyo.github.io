---
layout: post
title: "How the Same-Origin Policy Mitigates CSRF"
date: 2022-04-20 09:30:00 +0800
category: [Tech]
tags: [Software-Engineering]
---

### What is CSRF?

A cross site request forgery (CSRF) attack occurs when a web browser is tricked into executing an unwanted action in an application that a user is logged in.

For example, User A may be logged onto _Bank XYZ_ in the browser which uses cookies for authentication.
Let's say the a transfer request like this -

``` 
GET http://bank-zyz.com/transfer?from=UserA&to=UserB&amt=100 HTTP/1.1
```

Then a malicious actor can embed a request with similar signatures inside an innocent looking hyperlink.

```html 
<a href="http://bank-xyz.com/transfer?from=UserA&to=MaliciousActor&amt=10000 HTTP/1.1></a>
```

If User A clicks on the hyperlink, the web browser sends the request together with the session cookie.
The funds are then unintentionally transferred out of User A's account.

### When the same-origin-policy does not help with CSRF

The [same-origin policy](https://developer.mozilla.org/en-US/docs/Web/Security/Same-origin_policy) prevents a page from accessing results of cross domain requests.
It prevents a malicious website from accessing another website's resources such as static files and cookies.

Even though the policy prevents cross-origin <ins>access</ins> of resources, it does not prevent the requests from being sent.

In the _Bank XYZ_ example, a `GET` request with relevant cookies triggers the server to transfer the funds before returning the 200 OK response.
As shown in the diagram below, the same-origin policy only prevents the access of resouces, which in this case is reading the HTTP response.
Since the request (with cookies) can still be sent, the hyperlink can still trigger the transfer of funds.

![GET request sequence](/assets/img/2022-04-20-1.jpg)
_Image by Author - The policy would only prevent a cross-origin access of HTTP response (Step 3)_

**Note**: For more complex HTTP requests, a preflight `OPTIONS` request is sent beforehand to check for relevant [CORS](https://developer.mozilla.org/en-US/docs/Web/HTTP/CORS) headers.
In that scenario, an unexpected cross-origin request will not reach _Bank XYZ's_ website at all.

### How the same-origin-policy actually mitigates CSRF

To prevent CSRF, _Bank XYZ_ can generate an unpredictable token for each client which is validated in the subsequent requests.
For example, a hidden HTML field can allow the token to be included in subsequent form submissions.

```html
<input type="hidden" name="csrf-token" value="CIwNZNlR4XbisJF39I8yWnWX9wX4WFoz" />
```

Other websites running in User A's browser do not have <ins>access</ins> to the form field due to the same-origin-policy.
So malicious scripts from other origins can no longer make the same request to transfer funds.

### Resources

1. [StackOverFlow on why SOP is not enough not prevent CSRF](https://stackoverflow.com/questions/33261244/why-same-origin-policy-isnt-enough-to-prevent-csrf-attacks)
2. [CSRF by Imperva](https://www.imperva.com/learn/application-security/csrf-cross-site-request-forgery/)