---
title: MacOS 使用 Homebrew 管理多個 Golang 版本
date: 2021-01-30 17:03:16
tags:
- Golang
- Homebrew
- MacOS
categories:
- Golang
---

在網路上很多文章使用 `brew switch` 來切換 Golang 的 version，但是在 brew v2.6.0 後 `brew switch` 指令已經被廢棄（[https://brew.sh/2020/12/01/homebrew-2.6.0/](https://brew.sh/2020/12/01/homebrew-2.6.0/)）。

<!-- More -->

首先，先確認我們的 golang 是由 homebrew 管理。

```bash
which go
/usr/local/bin/go

ls -l /usr/local/bin/go
lrwxr-xr-x  1 justin  admin  28 Jan 30 16:37 /usr/local/bin/go -> ../Cellar/go/1.15.7_1/bin/go
```

如果 `which go` 看到的路徑是 `/usr/local/go` 的話，那麼當初的 golang 應該是透過下載安裝而不是由 Homebrew 管理的，可以直接 `rm -rf /usr/local/go` 刪除。

接著用 Homebrew 安裝最新版本的 golang。

```bash
brew install go

brew info go
go: stable 1.15.7 (bottled), HEAD
....
```

假設我們要安裝 v1.14 版本的 golang，則一樣用 homebrew 來安裝，指令為 `brew install go@v?`。

```bash
brew install go@v1.14

ls /usr/local/Cellar | grep "go"
go
go@1.14
```

可以看到兩個版本的 go 已經安裝完成。

看下現在的 golang 版本：

```bash
go version
go version go1.15.7 darwin/amd64
```

顯示為 `go1.15.7`，若要切換成 `v1.14` 的版本，可以用以下指令：

```bash
brew link --force --overwrite go@1.14

go version
go version go1.14.14 darwin/amd64

which go
/usr/local/bin/go

ls -l /usr/local/bin/go
lrwxr-xr-x  1 justin  admin  32 Jan 30 16:51 /usr/local/bin/go -> ../Cellar/go@1.14/1.14.14/bin/go
```

可以看到 `go` 指令的 symbolic link 已經被切換成 `go@1.14` 的版本。

若要切換回最新版本，則使用以下指令：

```bash
brew unlink go && brew link go

go version
go version go1.15.7 darwin/amd64

ls -l /usr/local/bin/go
lrwxr-xr-x  1 justin  admin  28 Jan 30 16:53 /usr/local/bin/go -> ../Cellar/go/1.15.7_1/bin/go
```

可以看到 `go` 指令的 symbolic link 已經被切換回最新版本。
