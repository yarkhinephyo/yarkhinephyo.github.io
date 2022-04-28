---
layout: post
title: "Quick History of JavaScript Module Ecosystem"
date: 2022-04-07 11:02:00 +0800
category: [Tech]
tags: [JavaScript, Software-Engineering]
---

### IIFE - Initial Concept of JS Modules

Immediately-invoked Function Expression are anonymous functions that wrap around code blocks to be imported. In the example below, the inner function `sayHi()` cannot be accessed outside the anonymous function. The anonymous function itself also does not have a name so it does not pollute the global scope.

{% highlight javascript %}
// script1.js
(function () {
    var userName = "Steve";
    function sayHi(name) {
        console.log("Hi " + name);
    }
    sayHi(userName);
})();
{% endhighlight %}

If this script is included as shown below, no variable name collision can occur with other scripts such as `script2.js`.

{% highlight html %}
<!DOCTYPE html>
<html>
    <head>
        <title>JavaScript Demo</title>
        <script src="script1.js"></script>
        <script src="script2.js"></script>
    </head>
    <body>
        <h1>IIFE Demo</h1>
    </body>
</html>
{% endhighlight %}

### Problems with IIFE

What if `script2.js` wants to use the `sayHi()` function defined in `script1.js`? We can pass a common global variable through the two IIFE modules as shown below.

{% highlight javascript %}
// script1.js
(function (window) {
    function sayHi(name) {
        console.log("Hi " + name);
    }
    window.script1 = { sayHi };
})(window);
{% endhighlight %}

{% highlight javascript %}
// script2.js
(function (window) {
    function sayHiBye(name) {
        window.script1.sayHi(name);
        console.log("Bye " + name);
    }
    var userName = "Jenny";
    sayHiBye(userName);
})(window);
{% endhighlight %}

This solves the immediate problem, but generates other issues.

If we reorder `script1.js` and `script2.js`, the code will break as the `window` object will not have the `script1` object by the time `script2.js` starts to load.

There is also the problem of what common variable to pass between the two IIFE. One company may use the `window` object but another may create a new `app` object in the global scope. No strict standards means incompatiblity issues.

### CommonJS - Solving the problems of IIFE

[CommonJS](https://en.wikipedia.org/wiki/CommonJS) is a series of specifications for development of JavaScript applications in non-browser environments. One of the specifications is the API for importing and exporting of modules. This is where `require()` and `module.exports` are introduced.

There is no more need for passing around a global variable or wrapping an anonymous function around every code blocks for export.

{% highlight javascript %}
// script1.js
function sayHi(name) {
    console.log("Hi " + name);
}
module.exports.sayHi = sayHi;
{% endhighlight %}

{% highlight javascript %}
// script2.js
script1 = require("./script1.js");
function sayHiBye(name) {
    script1.sayHi(name);
    console.log("Bye " + name);
}
var userName = "Jenny";
sayHiBye(userName);
{% endhighlight %}

However, CommonJS was not meant for the browser environment. The specifications also do not support asychronous loading of the modules which is important in the browser environment for the user experience.

### Module Bundler - CommonJS style modules in the Browser

Module bundlers such as [Webpack](https://webpack.js.org/) solves the incompatibility problem by bundling CommonJS modules for usage in the browser. The modules are loaded into a single `bundle.js` file such that individual dependencies are satisfied, which can be loaded onto the page with the a single `<script>` tag.

For the example above, webpack can produce a single `bundle.js` with `script2.js` as an entry. The bundle will include `script1.js` first as it understands the dependency graph. By including the `bundle.js` into HTML as shown below, the abovementioned problems with CommonJS are fixed.

{% highlight html %}
<!DOCTYPE html>
<html>
    <head>
        <title>JavaScript Demo</title>
        <script src="bundle.js"></script>
    </head>
    <body>
        <h1>Webpack Demo</h1>
    </body>
</html>
{% endhighlight %}

### ES6 - Module system as part of JavaScript standard

[ES6](https://www.w3schools.com/js/js_es6.asp) is a JavaScript standard introduced in 2015 that finally introduced a module system for JavaScript in the browsers. ES6 modules utilize `import` and `export` keywords. Unlike CommonJS, webpack is not necessary for browser compatibility. We only need to add a `type="module"` attribute inside the HTML `<script>` tag and everything will work out of the box.

{% highlight html %}
<!DOCTYPE html>
<html>
    <head>
        <title>JavaScript Demo</title>
        <script type="module" src="script2.js"></script>
    </head>
    <body>
        <h1>ES6 Demo</h1>
    </body>
</html>
{% endhighlight %}

{% highlight javascript %}
// script1.js
function sayHi(name) {
    console.log("Hi " + name);
}
export default { sayHi };
{% endhighlight %}

{% highlight javascript %}
// script2.js
import script1 from './script1.js';
function sayHiBye(name) {
    script1.sayHi(name);
    console.log("Bye " + name);
}
var userName = "Jenny";
sayHiBye(userName);
{% endhighlight %}

### Why are bundlers still used for browser scripts?

<ins>Backward Compatibility</ins>: ES6 modules are not recognized in the older versions of the browsers. Bundlers allow developers to work with the more modern ES6 syntax while the code remains compatible with older browsers.

<ins>Size Reduction</ins>: Minifying code with bundlers reduces file sizes which will lead to faster page loads.

<ins>Code Splitting</ins>: Bundlers can split code into chunks which can then be loaded on demand or in parallel.

<ins>Caching Support</ins>: Webpack can be configured to name the bundles with the hash of their contents. Browsers will only fetch scripts from the server if the hashes no longer match.

### Resources

1. [JavaScript Modules by uidotdev](https://www.youtube.com/watch?v=qJWALEoGge4)
2. [ES6 Modules in the Browser by David Gilbertson](https://david-gilbertson.medium.com/es6-modules-in-the-browser-are-they-ready-yet-715ca2c94d09)
3. [JavaScript Module Systems Showdown by Auth0](https://auth0.com/blog/javascript-module-systems-showdown/)