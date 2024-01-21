---
layout: post
title: "Primer to Scale-invariant Feature Transform"
date: 2022-04-13 09:30:00 +0800
category: [Tech]
tags: [Data-Science]
---

Scale-invariant Feature Transform, also known as SIFT, is a method to consistently represent features in an image even under different scales, rotations and lighting conditions. Since the video series by First Principles of Computer Vision covers the details very well, the post covers mainly my intuition. The topic requires prior knowledge on using [Laplacian of Gaussian](https://en.wikipedia.org/wiki/Discrete_Laplace_operator) for edge detection in images.

### Why extract features?

![](/assets/img/2022-04-13-1.jpg)
_Image by First Principles of Computer Vision_

Consider the two images. How can the computer recognize that the object in the left is included inside the image on the right? One way is to use [template-based matching](https://docs.opencv.org/4.x/d4/dc6/tutorial_py_template_matching.html) where the left image is overlapped onto the right. Then some form of similarity measure can be calculated as it is shifted across the right image.

<ins>Problem</ins>: To ensure different scales are accounted for, we would need templates of different sizes. To check for different orientations, we would need a template for every unit of angle. To overcome occlusion, we may even need to split the left image into multiple pieces and check if each of them matches.

![](/assets/img/2022-04-13-2.jpg)

For the example above, our brains recognize the eye and the faces to locate the book. Our eyes do not scan every pixel, and we are not affected by the differences in scale and rotation. Similarly it will be great if we can **1)** extract only interesting features from an image and **2)** transform them into representations that are consistent across different scenes.

### Good requirements for feature representation

<ins>Points of Interest</ins>: Blob-like features with rich details are preferred over simple corners or edges.

<ins>Insensitive to Scale</ins>: The feature representation should be normalized to its size.

<ins>Insensitive to Rotation</ins>: The feature representation should be able to undo the effects of rotation.

<ins>Insensitive to Lighting</ins>: The feature representation should be consistent under different lighting conditions.

### Blob detection - Scale-normalized points of interest

![](/assets/img/2022-04-13-3.jpg)
_Image from Princeton CS429 - 1D edge detection_

In traditional edge detection, a Laplacian operator can be applied to an image through convolution. Edges can be identified from the _ripples_ in the response.

![](/assets/img/2022-04-13-4.jpg)
_Image from Princeton CS429 - 1D blob detection_

If multiple edges are at the right distance, there will be a single strong _ripple_ caused by constructive interference. If this response is sufficiently strong, the location is identified as a <ins>blob</ins> representing a feature. Intuitively, complex features will be chosen compared to simple edges as constructive interferences cannot be produced by single edges.

From the same diagram, we can also see that not all collection of edges result in singular _ripples_ with a particular Laplacian operator. By increasing the <ins>sigma (σ)</ins> of the Laplacian (making the kernel "fatter"), the constructive interference will occur when edges are further apart. If we apply the Laplacian operators many times with varying σ's, blobs of different scales can be identified each time.

![](/assets/img/2022-04-13-5.jpg)
_Image from Princeton CS429 - Increasing σ to identify larger blobs_

Wait but if the σ is larger, the Laplacian response will be weaker (shown above). Intuitively, if the responses by larger blobs are penalized for their sizes. Does that means the selected features will be mostly tiny?

![](/assets/img/2022-04-13-6.jpg)
_Image from Princeton CS429 - Normalized Laplacian of the Gaussian (NLoG)_

We solve this by multiplying the Laplacian response with σ<sup>2</sup> for normalization. (This works out because the Laplacian is the 2nd Gaussian derivative) Intuitively, this means that the response now only indicates the <ins>complexity</ins> of the features without any effect from their sizes.

![](/assets/img/2022-04-13-7.jpg)
_3 x 3 x 3 kernels to find local extremas_

Imagine the Laplacian response represented as a matrix with _x_-_y_ plane for image dimensions and _z_ axis for various σ. We can slide an _n x n x n_ kernel to find the local extremas. The resulting _x_-_y_ coordinates would represent the centers of the blobs and σ would correspond to their sizes.

With this technique, blobs can be extracted to represent complex features with the sizes normalized.

### Countering the effects of rotation

![](/assets/img/2022-04-13-8.jpg)
_Image from Princeton CS429_

To assign an orientation to each feature, it can be divided into smaller windows as shown above. Then the pixel gradient for each window can be computed to produce a histogram of gradient directions. The most prominent direction can be assigned as the <ins>principle orientation</ins> of the feature.

![](/assets/img/2022-04-13-9.jpg)
_Image by Author_

In the example above, blobs are identified in both images representing the same feature. The black arrows are the principle orientations. After rescaling the blob sizes with the corresponding σ's, the effect of rotation is eliminated by aligning with respect to the principle orientations.

### Countering the effects of lighting conditions

![](/assets/img/2022-04-13-10.jpg)
_Image from Princeton CS429 - Pixels to SIFT descriptors_

Instead of comparing each blob directly (pixel-by-pixel), we can produce a unique representation that is invariant to lighting conditions. As shown above, the image can be broken into smaller windows (4 x 4) where each histogram of the gradients is computed. If each histogram only consider 8 directions, there will be 8 dimensions per window. Even with only 16 windows per blob, each feature representation will be of 128 dimensions (16 x 8) which can be robust.

These feature representations are known more formally as <ins>SIFT descriptors</ins>.

### Conclusion

![](/assets/img/2022-04-13-11.jpg)
_Image from OpenCV documentation_

For matching images, SIFT descriptors in two images can be directly compared against one another through similarity measurements. If a large number of them matches, it is likely that the same objects are observed in both images. In practice, nearest neighbor algorithms such as [FLANN](https://github.com/flann-lib/flann) are used to match the features between images.

### Resources

1. [SIFT Detector by First Principles of Computer Vision](https://www.youtube.com/watch?v=IBcsS8_gPzE&list=PL2zRqk16wsdqXEMpHrc4Qnb5rA1Cylrhx&index=16)
2. [Feature Detectors and Descriptors - Princeton CS429](https://www.cs.princeton.edu/courses/archive/fall17/cos429/notes/cos429_fall2017_lecture4_interest_points.pdf)
