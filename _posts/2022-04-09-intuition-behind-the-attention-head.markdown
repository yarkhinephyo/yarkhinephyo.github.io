---
layout: post
title: "Intuition Behind the Attention Head of Transformers"
date: 2022-04-09 14:20:00 +0800
category: [Tech]
tags: [Data-Science]
---

Even as I frequently use transformers for NLP projects, I have struggled with the intuition behind the multi-head attention mechanism outlined in the paper - [Attention Is All You Need](https://arxiv.org/abs/1706.03762). This post will act as a memo for my future self.

### Limitation of only using word embeddings

Consider the sequence of words - _pool beats badminton_. For the purpose of machine learning tasks, we can use [word embeddings](https://en.wikipedia.org/wiki/Word_embedding) to represent each of them. The representation can be a matrix of three word embeddings.

If we take a closer look, the word _pool_ has multiple meanings. It can mean a swimming pool, some cue sports or a collection of things such as money. Humans can easily perceive the correct interpretation because of the word _badminton_. However, the word embedding of _pool_ includes all the possible interpretations learnt from the training corpus.

Can we add more context to the embedding representing _pool_? Optimally, we want it to be "aware" of the word _badminton_ more than the word _beats_.

### My intuition behind the self-attention mechanism

Consider that matrix **A** represents the sequence - _pool beats badminton_. There are three words (rows) and the word embedding has four dimensions (columns). The first dimension represents the concept of sports. Naturally, we expect the words _pool_ and _badminton_ to have more similarity in this dimension.

![Matrix-A](/assets/img/2022-04-09-1.jpg)
_Diagram by Author_

```python
A = np.array([
  [0.5, 0.1, 0.1, 0.2],
  [0.1, 0.5, 0.2, 0.1],
  [0.5, 0.1, 0.2, 0.1],
])
```

If we do a matrix multiplication between **A** and **A<sup>T</sup>**, the resulting matrix will be the dot-product similarities between all possible pairs of words. For example, the word _pool_ is more similar to _badminton_ than the word _beats_. In other words, this matrix hints that the word _badminton_ should be more important than the word _beats_ when adding more context to the word embedding of _pool_.

![Similarity](/assets/img/2022-04-09-2.jpg)
_Diagram by Author_

```
A_At = np.matmul(A, A.T)
>>> A_At
array([[0.31, 0.14, 0.3 ],
       [0.14, 0.31, 0.15],
       [0.3 , 0.15, 0.31]])
```

By applying the softmax function across each word, we can ensure that these "similarity scores" add up to 1.0.

The last step is to do another matrix multiplication with matrix **A**. In a way, this step consolidates the contexts of the entire sequence to each embedding in an "intelligent" manner. In the example below, both embeddings of _beats_ and _badminton_ are added to _pool_ but with different weights depending on their similarities with _pool_.

![Result](/assets/img/2022-04-09-3.jpg)
_Diagram by Author_

```
output = np.round(
    np.matmul(softmax(A_At, axis=1), A)
, 2)
>>> output
array([[0.38, 0.22, 0.16, 0.14],
       [0.35, 0.25, 0.17, 0.13],
       [0.38, 0.22, 0.17, 0.13]])
```

Notice that the output matrix has the same dimensions (3 x 4) as the original input **A**. The intuition is that each word vector is now enriched with more information. This is the gist of the <ins>self-attention</ins> mechanism.

### Scaled Dot-Product Attention

The picture below shows the Scaled Dot-Product Attention from the [paper](https://arxiv.org/abs/1706.03762). The core operations are the same as the example we explored. Notice that scaling is added before softmax to ensure stable gradients, and there is an optional masking operation. Inputs are also termed as **Q**, **K** and **V**.

![Result](/assets/img/2022-04-09-4.jpg)
_Image taken from Attention Is All You Need paper_

The Scaled Dot-Product Attention can be represented as `attention(Q, K, V)` function.

![Scaled-dot-product](/assets/img/2022-04-09-5.jpg)
_Diagram by Frank Odom on Medium_

### Adding trainable weights with linear layers

The initial example that we use can be represented as `attention(A, A, A)`, where matrix **A** contains the word embeddings of _pool_, _beats_ and _badminton_. So far there are no weights involved. We can make a simple adjustment to add trainable parameters.

Imagine we have (m x m) matrices **M<sup>Q</sup>**, **M<sup>K</sup>** and **M<sup>V</sup>** where _m_ matches the dimension of word embeddings in **A**. Instead of passing matrix **A** directly to the function, we can calculate **Q** = **A** **M<sup>Q</sup>**, **K** = **A** **M<sup>K</sup>** and **V** = **A** **M<sup>V</sup>** which will be the same sizes as **A**. Then we apply `attention(Q, K, V)` afterwards. In neural network, this is akin to adding a linear layer before each input into the Scaled Dot-Product Attention.

To complete the Single-Head Attention mechanism, we just need to add another linear layer after the output from the Scaled Dot-Product Attention. The idea of expanding to the Multi-Head Attention in the paper is relatively simpler to grasp.

![Single-head](/assets/img/2022-04-09-6.jpg)
_Diagram by Frank Odom on Medium_

### Resources

1. [Series on Attention by Rasa Algorithm Whiteboard](https://www.youtube.com/watch?v=23XUv0T9L5c)
2. [The Illustrated Transformer by Jay Alammer](https://jalammar.github.io/illustrated-transformer/)
