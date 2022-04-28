---
layout: post
title: "Choosing Between UTF Encodings"
date: 2022-04-27 12:07:00 +0800
category: [Tech]
tags: [Software-Engineering]
---

Have you occasionally chosen a character encoding such as UTF-8 during reading and writing files while wondering its purpose? I have! This post explains various UTF (Unicode Transformation Format) algorithms such as UTF-8, UTF-16, UTF32 and how to choose between them.

### Unicode character set

[Unicode](https://unicode.org/standard/WhatIsUnicode.html) character set defines a unique number for almost all characters used in modern texts today. The standard ensures that given a number, also known as a [code point](https://developer.mozilla.org/en-US/docs/Glossary/Code_point), different softwares will decode it as the same character.

| Character | Decimal Representation | Code (Read Hexadecimal) |
| --------- | ---------------------- | ----------------------- |
| A         | 65                     | U+41                    |
| B         | 66                     | U+42                    |
| 我        | 25105                  | U+6211                  |
| 😋        | 128523                 | U+1F60B                 |

The Unicode character set ranges from 0x0 to 0x10FFFF (21-bits range).

### UTF-32

UTF stands for Unicode Transformation Format. It encodes integer code points into byte representations on a machine. For example, if 4 bytes are allocated to a character at each time, four-byte representations are shown below.

| Character | Byte Representation (Read Hexadecimal) |
| --------- | -------------------------------------- |
| A         | 0x00000041                             |
| B         | 0x00000042                             |
| 我        | 0x00006211                             |
| 😋        | 0x0001F60B                             |

This is exactly what UTF-32 does. It pads every code point with zeros into 32 bits. This is more than sufficient for the 21-bits range of Unicode character set.

However, the approach is space-inefficient. For example, if there are only English letters in a document (U+41 to U+7A), only one byte is necessary to represent each character. However, UTF-32 will still pad with three bytes to form four-byte representations, resulting as 300% increase in storage.

### UTF-16

UTF-16 mitigates the problem by representing U+0 to U+FFFF with two bytes and U+10000 to U+10FFFF with four bytes.

Characters from almost all modern languages are found in the first 2<sup>16</sup> code points (See [Basic Multilingual Plane](https://en.wikipedia.org/wiki/Plane_(Unicode)#Basic_Multilingual_Plane)). If a document only contains these code points, UTF-16 will mainly use two-byte representations instead, meaning storage is cut by 50% from using UTF-32.

To represent larger code points, UTF-16 employs a concept called [surrogate pairs](https://stackoverflow.com/questions/496321/utf-8-utf-16-and-utf-32). High surrogates are code points from U+D800 to U+DBFF and low surrogates are code points from U+DC00 to U+DFFF. There are no character mappings at these ranges and <ins>they only have meaningful representations when paired</ins>. The example below may present a clearer picture.

```
High surrogate --> U+D800 to U+DBFF --> 110110 concat with any 10 bits
Low surrogate  --> U+DC00 to U+DFFF --> 110111 concat with any 10 bits

Character: 😋
Unicode  : U+1F60B
Binary   : 0b11111011000001011

Binary padded 20-bits: 0b00011111011000001011
                         <--- A --><--- B -->
                         (10 bits)  (10 bits)

High surrogate: 110110 concat A = 1101100001111101 (16 bits)
Low surrogate : 110111 concat B = 1101111000001011 (16 bits)
```

If a decoder sees a two-byte representation starting with `110110` or `110111` bits, it can infer that this is part of a surrogate pair and immediately identify the other surrogate. The binary representation of the original character can be reconstructed afterwards.

### UTF-8

[ASCII](https://www.asciitable.com/) characters compose the first 2<sup>7</sup> code points. Most of the time when coding or writing English articles, you may mostly end up using these characters. As these code points can be represented with one byte, two-byte representations of UTF-16 still results in wasted storage.

Depending on the range of Unicode character set, UTF-8 uses one, two, three or four-byte representations. The encoding pseudocode is shown below.

```
if code point < 2^7             # Covers ASCII
  pad with zeros till 8 bits
  1st byte = 8 bits

else if code point < 2^11       # Covers other Latin alphabets
  pad with zeros till 11 bits   # (5 + 6)
  1st byte = "110" concat 5 bits
  2nd byte = "10" concat 6 bits

else if code point < 2^16       # Covers Basic Multilingual Plane
  pad with zeros till 16 bits   # (4 + 6 + 6)
  1st byte = "1110" concat 4 bits
  2nd byte = "10" concat 6 bits
  3rd byte = "10" concat 6 bits

else if code point < 2^21       # Covers 21-bit Unicode range
  pad with zeros till 21 bits   # (3 + 6 + 6 + 6)
  1st byte = "11110" concat 3 bits
  2nd byte = "10" concat 6 bits
  3rd byte = "10" concat 6 bits
  4rd byte = "10" concat 6 bits
```

As texts encoded in ASCII never appear as multi-byte sequences, UTF-8 can be used to decode it directly. The backward compatibility is one of the reasons why it has been adopted at a large scale.

### How to choose between UTF-8, UTF-16, UTF-32

If backward compatibility to ASCII is preferred and most characters are English text, UTF-8 is a good choice.

If most characters are from non-English languages, UTF-16 is preferred because it uses two-byte representations for Basic Multilingual Plane as compared to UTF-8 which uses three-byte representations.

UTF-32 is rarely used but in theory, the fixed-width encoding without transformations allows faster encoding and decoding of characters.

### Resources

1. [UTF-8 vs UTF-16 vs UTF-32 on StackOverflow](https://stackoverflow.com/questions/496321/utf-8-utf-16-and-utf-32)
2. [How UTF-16 encodes 21-bit unicode](https://news.ycombinator.com/item?id=17771635)
3. [Unicode Encoding! by EmNudge](https://www.youtube.com/watch?v=uTJoJtNYcaQ)