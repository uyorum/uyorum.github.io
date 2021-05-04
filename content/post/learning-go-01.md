+++
Categories = []
Tags = []
title = "Go言語のお勉強 その1"
date = "2015-07-29T00:30:49+09:00"
aliases = ["/blog/learning-go-01/"]

+++

Go言語を勉強中．今日やったことまとめ．

<!--more-->

## 参考
* [ドキュメント - The Go Programming Language](http://golang-jp.org/doc/)
* [golang ｜ シリーズ ｜ Developers.IO](http://dev.classmethod.jp/series/golang-2/)

## プログラムの構造

``` go
package main

import (
  "fmt"
  "strconv"
)

func func1 {
  // definition of function

}

func main {
  // main operation

}
```

* プログラムを実行するとまず`main`が実行される．
* `import`  
    使用するパッケージを指定する．ここで指定したがプログラム内で使用していないと実行時に警告が出力される．  
    括弧でまとめてimportすることができる．上記の例は以下と等価

```go
import "fmt"
import "strconv"
```

## 変数の宣言

```go
var int1 int
var int2 int = 1
var int3 = 2
var str1, str2 string
var str1, str2 = "hoge", "huga"

func func1 {
  boo := false
}
```

* `var 変数名 型`の形式で宣言する．
* 宣言と同時に初期化することもできる．その場合は型の指定を省略でき，右辺の型が自動的に使用される．
* `,`区切りで複数の変数を同時に宣言することもできる．
* 関数内に限り`:=`を使用することで`var`を省略できる．

### 定数

```go
const PI float64 = 3.14
//PI = 3.141592 <-エラー

const (
  const1 = "string"
  const2 = 10
)

const (
  x = iota
  y = iota
  z
)

// 0 1 2 0
fmt.Println(x, y, z, x)
```

* `const 変数 [型] = 値`の形式で宣言する．
* 変数と異なり，宣言と同時に初期化しないとエラーになる．
* `const (   )`を使うことでまとめて宣言することもできる．
    * 値を省略すると上と同じ値が代入される．
* `iota`は連番が生成される．

## 関数

```go
func inc1(i int) int {
  i++
  fmt.Println("inc1: i = " + strconv.Itoa(i))
  return i
}
```

* `func 関数名(引数 引数の型[, 引数 引数の型[, ...]]) [返り値の型]`の形式で宣言する

```go
func split(sum int) (x, y int) {
    x = sum * 4 / 9
    y = sum - x
    return
}

// 7 10
fmt.Println(split(17))
```

* 関数の宣言時に返り値で変数を指定することで`return`時に変数を省略できる．

### 可変長引数

```go
func fArgs(strArgs ...string) {
  for index, value := range strArgs {
    fmt.Println(index, value)
  }
}

// 0 Go
// 1 Java
// 2 Ruby
fArgs("Go", "Java", "Ruby")
```

* 引数の型に`...`をつけることで可変長変数をとる関数を宣言できる
* 配列に格納される．(Array? Slice?)

## ポインタ

```go
func inc2(i *int) {
	*i++
	fmt.Println("inc2: i = " + strconv.Itoa(*i))
}

num := 10
inc1(num)          // inc1: i = 11
fmt.Println(num)   // 10
num = 10
inc2(&num)         // inc2: i = 11
fmt.Println(num)   // 11
```

* `*型`形式で記述することで「指定した型を持つ値を指すポインタ」が渡される．
* `*ポインタ名`形式で記述することで「そのポインタが指す値」が渡される．
* `&変数名`形式で記述することで「その変数のポインタ」が渡される．
* inc2はポインタを関数に渡しているため，関数の外でも値が変更されたままになる．
* Goでは引数の渡し方はすべて値渡し．ここで行なっているのは「参照の値渡し」である．
    * 値がメモリ上でコピーされないのでメモリの節約になる．

今日はここまで．
