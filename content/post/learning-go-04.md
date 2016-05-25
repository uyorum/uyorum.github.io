+++
Categories = []
Tags = []
title = "Go言語のお勉強 その4"
date = "2015-08-02T22:17:45+09:00"

+++

4日目

<!--more-->

## データ型
### Array

```go
var a1 [5]int
fmt.Println(a1)		// [0 0 0 0 0]
a1[0] = 2
fmt.Println(a1)		// [2 0 0 0 0]

var a3 [2][3]int
fmt.Println(a3)		// [[0 0 0] [0 0 0]]

a2 := [4]string{"hoge", "huga", "foo", "bar"}
fmt.Println(a2)		// [hoge huga foo bar]
fmt.Println(a2[:3])	// [hoge huga foo]
fmt.Println(a2[2:3])	// [foo]
fmt.Println(a2[2:])	// [foo bar]
fmt.Println(len(a2))	// 4
```

* `[要素数]型`でArray型を表現する
* 宣言と同時に初期化するには`[要素数]型{ 値を列挙 }`で表現する
* 多重配列も利用可能
    * `[n1][n2]type`は`[n1]([n2]type)`と等価
* 値へアクセスするには`変数名[インデックス]`と表現する
    * インデックスは0から始まる
* :を使うことで範囲を指定してアクセスすることもできる
* 後からサイズを変更することはできない
    * そういったときは`Slice`を使う

### Slice

```go
var s1 []int
fmt.Println(s1)			// []
s2 := []int{10, 20, 30, 40, 50}
fmt.Println(s2)			// [10 20 30 40 50]
var s3 []int = make([]int, 3, 4)
fmt.Println(s3)			//[0 0 0]
s3[3] = 1
fmt.Println(s3)			//[0 0 0]

s4 := a2[:]			// a2 == [hoge huga foo bar]
fmt.Println(s4)			// [hoge huga foo bar]
a2[1] = "piyo"
fmt.Println(s4)			// [hoge piyo foo bar]

var s4 []int = make([]int, 3, 4)
fmt.Println(s4)			//[0 0 0]
fmt.Println(len(s4))		// 3
fmt.Println(cap(s4))		// 4
s4 = s4[:cap(s4)]		// 長さを拡張
fmt.Println(s4)			// [0 0 0 0]

s4 = []int{10, 20, 30, 40}
s5 := make([]int, len(s4), (cap(s4) + 1))
copy(s5, s4)
fmt.Println(len(s5), cap(s5))	// 4, 5
fmt.Println(s5)				// [10 20 30 40]

s6 := append(s5, 50, 60)
fmt.Println(s6)				// [10 20 30 40 50 60]
```

* `[]型`で表現する
* Sliceの各要素には値へのポインタが格納される
* ArrayからSliceを生成することができる
    * 同様にSliceからSliceを生成することもできる
* Sliceは組み込みのmake関数でも生成することができる
    * `make([]型, 長さ, 容量)`で表現する
    * 容量は省略することもでき，その場合は長さと同じ値が自動で設定される
* Sliceの長さはその容量まで拡張することができる
* 容量を拡張するにはmake関数でより大きい容量を指定してSliceを再生成する
* SliceからSliceへ値をコピーするにはcopy関数を使う
    * `copy(dst, src)`
* append関数を使うと容量と長さの拡張を自動で行なってくれる
* 要素を削除する関数は用意されていないので自分で作る必要がある

### Map

```go
m1 := make(map[string]int)
m1["x"] = 10
m1["y"] = 20
fmt.Println(m1["x"])			// 10

delete(m1, "x")
fmt.Println(m1)					// map[y:20]
fmt.Println(m1["x"])			// 0

m2 := map[string]int{"x": 10, "y": 20}
// Undefined
if _, ok := m2["z"]; ok {
	fmt.Println("Defined")
} else {
	fmt.Println("Undefined")
}
```

* いわゆる連想配列
* `make(map[Keyの型]Valueの型)`
    * Keyには`function`, `Map`, `Slice`型を使用することができない
* 要素を消すにはdelete関数を使う
* `map[Key]`には戻り値が2つある
    * 1つめは指定したキーに対応する値
    * 2つめには値が定義されていたらtrue，未定義の場合はfalseが返る
* MapはArrayやSliceと異なり各要素に順番がない

### range

```go
array1 := [...]int{10, 20, 30}
slice1 := append(array1[:], 40, 50)
map1 := map[string]int{"hoge": 10, "huga": 20}

// index: 0 value: 10
// index: 1 value: 20
// index: 2 value: 30
for i, v := range array1 {
	fmt.Println("index:", i, "value:", v)
}

// index: 0 value: 10
// index: 1 value: 20
// index: 2 value: 30
// index: 3 value: 40
// index: 4 value: 50
for i, v := range slice1 {
	fmt.Println("index:", i, "value:", v)
}

// key: hoge value: 10
// key: huga value: 20
for k, v := range map1 {
	fmt.Println("key:", k, "value:", v)
}
```

* Array, Slice, Mapなどの各要素に対するループ処理を実行するときに使う
* `range 変数`で2つの戻り値が返る
    * 1つめはインデックス(Mapの場合はキー)
    * 2つめは値
* Mapは要素に順番を持たないので実行する度に順番が異なる

ここまではほとんど[ここ](http://dev.classmethod.jp/series/golang-2/)をなめただけ．  
あとは公式ドキュメントとか本とか見ながら細かいところ勉強していこうと思う．
