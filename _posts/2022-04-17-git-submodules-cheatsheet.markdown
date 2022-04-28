---
layout: post
title: "Git Submodules Cheatsheet"
date: 2022-04-17 00:30:00 +0800
category: [Tech]
tags: [Software-Engineering]
---

[Git Submodules](https://git-scm.com/book/en/v2/Git-Tools-Submodules) allows one Git repository to be a subdirectory of another. I keep forgetting the commands so I have created a 2-minute refresher for my future reference.

### Adding a submodule

To add a submodule to a project, run the command as shown below. Git will clone the submodule to the path provided and create a new `.gitmodules` file to store the information.

```
git submodule add <remote-url> <path-to-module>
```

Note that the `<path-to-module>` is now tracked by the parent repository as a commit ID instead of a subdirectory of contents. Treat it as a <ins>file</ins> for all practical purposes.

```
git add <path-to-module> .gitmodules
git commit -m "Added submodule"
```

### Pushing an updated submodule

Only the submodule's commit ID is inspected by the parent repository. When the submodule's commit is modified, the parent repository will react similarly to how a file has been modified. Add the modified "file" to staging and commit as usual.

```
git add <path-to-module>
git commit -m "Updated submodule"
```

### Pulling an updated submodule

After pulling changes from the parent repository, only the submodule's tracked commit ID will be updated, not its <ins>contents</ins>. Manually update the contents of the submodule to synchronize with the updated commit ID.

```
# This updates the commit IDs of submodules
git pull origin main

# Update the contents of the submodules
git submodule update --init --recursive
```

### Cloning a repository containing submodules

Add a `--recursive` flag.

```
git clone --recursive <module>
```

### Resources

1. [Git Tools Submodules by Git Scm](https://git-scm.com/book/en/v2/Git-Tools-Submodules)