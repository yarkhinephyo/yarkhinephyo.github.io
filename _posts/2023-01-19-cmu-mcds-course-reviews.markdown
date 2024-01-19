---
layout: post
title: "CMU MCDS Course Reviews"
date: 2023-01-19 10:00:00 +0800
category: [School]
tags: [Other]
---

Over the last 1.5 years, I studied Master of Computational Data Science (MCDS) at Carnegie Mellon University. Inspired by blogs such as [fanpu.io](fanpu.io) and [wanshenl.me](wanshenl.me), I am going to outline my experiences for each course to hopefully help future students.

### Summer 2022

- <strong>15513 - Introduction to Computer Systems</strong>
  As someone who does not have a systems background, this course was transformational. It started with the foundation of how hardware instructions work and build up to computer memory, processes and threads. I took it with a full time internship but fortunately the class was asynchronous. I watched the lectures on weekday nights and worked on the projects on the weekends. The workload was manageable except for weeks of Malloc Lab which were heavier. For graduate students, this course was only 6 units so the tuition fee was only half the normal cost. Doing well in this course is compulsory for MCDS students who wish to choose the Systems concentration. Notable projects include:
  - Bomb lab: Reading through assembly code to decode its purpose.
  - Malloc lab: Building a memory allocator where throughput and memory fragmentation is graded.
  - Tsh lab: Building a simple shell to manage processes.
  - Proxy lab: Web server to serve and cache static files concurrently.

### Fall 2022

- <strong>10601 - Introduction to Machine Learning</strong>
  This course focused on how each type of machine learning models work from the ground-up, aka all mathematics. There were 3 written exams and homeworks with written and programming components. I spent more effort on the written components and preparing for the exams. The programming contained straightforward instructions and were not too complex. For students with more machine learning background, the course code for the PhD level version is 10701.
- <strong>11631 - Data Science Seminar</strong>
  A compulsary course for MCDS students. The focus was on reading and writing scientific papers. Every week students critique data science papers and submit paper summaries. There was also a component where students read the papers of the senior MCDS batch and critique them. Personally, I felt that the selected readings were too focused on the human-computer-interaction concentration of MCDS and did not include the other two concentrations (analytics and systems). The workload was the lowest compared to the other courses in the semester.
- <strong>11637 - Foundation of Computational Data Science</strong>
  There were some overlaps with 10601 in terms of the machine learning content. However, this course included the surrounding infrastructure around a machine learning model such as data processing and deploying the models. The course was asynchronous where students read the lectures on their own time which provided flexibility in terms of scheduling. The projects were time-consuming but not as technically complex as the systems related courses. Personally, I did not learn much more than the basic ML engineering experiences that I already had from internships.
- <strong>15645 - Database Systems</strong>
  The most exciting course for the semester. I got to build components of the [Bustub](https://github.com/cmu-db/bustub) database system. The professor, Andy Pavlo, was also very engaging which led to a lot of participation during class. The contents ranged from the low level concepts such as how the database interacts with the disk and optimizing query plans to higher level concepts such as how distributed databases work. The projects were in C++ and emphasized on multi-threading support. Optimizations could lead to higher ranks on the leaderboard and extra credits. As someone without any C++ experience, this course had the most difficult projects for the semester but after investing significant amount of time, it was still possible to achieve top 10 leaderboard ranking. My lecture notes can be found [here](https://github.com/yarkhinephyo/15-445-database-systems-notes). Notable projects include:
  - Storage Index: B+ tree data structure with concurrent protocols.
  - Query Execution: Iterator query processing model and query plan optimization.
  - Concurrency Control: Lock-based concurrency control with different isolation levels.

### Spring 2023

- <strong>05839 - Interactive Data Science</strong>
  The course was about visualization techniques in data science. The students have to read the lecture slides before attending the lectures afterwards. Contents included drawing charts, interpreting them and using frameworks to deploy them. There was also a final project where students could choose almost any dataset and draw visualizations in Streamlit. In my opinion, this was not sufficiently challenging for a graduate level course that was compulsory for MCDS students. A more appropriate audience would be freshmen students with not a lot of programming background.
- <strong>11634 - Capstone Planning Seminar</strong>
  MCDS students would have to work on a capstone project spanning two semesters. This course covered how to produce documentations for a data science project and also helped the students to match with project mentors. Generally, the contents provided a good structure to plan out the capstone projects from scratch. However, a lot of documentation was required for submission with tight deadlines and this took some time away from the actual discussions of the projects.
- <strong>15640 - Distributed Systems</strong>
  It was an introductory course on how to design and implement scalable distributed systems. The Spring version was taught in C and Java unlike the Fall version which was in Golang. I was fortunate to be taught by Professor Satya who implemented Andrew File System. The projects included implementing RPC, a distributed caching system, a scalable web service and the two-phased commit protocol. Some ideas overlap with 15645 such as transactions and logging. The projects were easier too. I spent about half the time on each project compared to 15645. My lecture notes can be found [here](https://github.com/yarkhinephyo/15-440-distributed-systems-notes).
- <strong>15719 - Advanced Cloud Computing</strong>
  Rather than how to use cloud technologies, the course covered how each type is implemented. I really liked the course as now I have a clearer understanding on the abstractions behind services on the cloud providers. For a better understanding, I really recommend going through the original papers provided as the compulsory reading materials as the lecture notes condenses them too much. It would also be helpful for system design interviews as the papers explains the complexities behind each system very well. In terms of assessment, the exams tested the application of each concept in scenarios. The projects on Spark were challenging but the other projects on Terraform and Kubernetes were easy for a "systems course". For MCDS students who took 15513, the course can be taken to replace 15619 - Cloud Computing.

### Fall 2023

- <strong>11632 / 11635 - Data Science Capstone</strong>
  The time was meant for implementing the proposals that were submitted during 11634. Weekly standups had to be submitted in the form of videos and google forms. Every few weeks, the teams had to present the updates to Professor Nyberg. One recommendation is to be very particular about planning, especially to have roadmaps with timelines and task assignments. The workload varies extremely widely across each team. The same mentors are usually involved with multiple batches of MCDS students so I would highly recommend talking to the previous teams beforehand.
- <strong>15641 - Computer Networks</strong>
  One of my favourite courses in CMU. Professor Sherry is a very friendly and engaging person which led to a lot of participation in class. The contents included a deep dive into each layer of TCP-IP model and network security.  Even though I took a networking class before during undergraduate, I still found the projects exciting to work on. People could choose to work in pairs, but it was still very manageable to work on them alone. It was more challenging than 15640 but less than 15645. Projects were in C and included:
  - Mixnet: Distributed spanning tree with link state routing to transport frames across nodes.
  - TCP: Implementing features of TCP over UDP sockets. Writing 3-way handshake, flow control and congestion control from scratch really made the concepts stuck in my head.
  - HTTP: Single-threaded HTTP server with Linux [epoll](https://man7.org/linux/man-pages/man7/epoll.7.html) to handle multiple clients.
- <strong>17663 - Programming Language Pragmatics</strong>
  The course spent about 60% on formally proving the properties of programming languages and 40% on the compiler implementation. As someone with little theory background, this was the toughest course for the semester. The proofs had to be written in [SASyLF](https://www.cs.cmu.edu/~aldrich/SASyLF/) which checked the correctness during compilation. This short feedback loop made the learning process easier. The compiler was to be written in OCaml and transforms a subset of TypeScript into WebAssembly code. As a systems student, this component was a lot more engaging to me but I can now  also appreciate the importance of formal reasoning. From my impression, it seemed that the other undergraduate students with more theory background found the course relatively easy.
