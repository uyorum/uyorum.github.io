+++
Categories = []
Tags = ["Golang"]
title = "Go言語のお勉強 その3"
date = "2015-08-02T01:19:12+09:00"
aliases = ["/blog/learning-go-03/"]

+++

今日の分．

<!--more-->

## 制御構文
### if

```go
x := false
if x == true {
	fmt.Println("x is true")
} else {
	fmt.Println("x is false")
}

rand.Seed(time.Now().UnixNano())
// [0, 10)の乱数(整数)を生成
if y := rand.Intn(10); y < 5 {
	fmt.Println(y, "is less than 5")
} else if y > 5 {
	fmt.Println(y, "is greater than 5")
} else {
	fmt.Println(y, "is equal to 5")
}
fmt.Println(y)		// undefined: y
```

* `if 条件式 {trueの場合の処理}`のように書く
* 条件式を`( )`で囲む必要はない
* `else`や`else if`が使える
* `変数名 := 値; 条件式`のように書くことで条件式部分で変数を宣言することもできる
    * ここで定義した変数はif文の中でのみ有効

### for

```go
for i := 0; i < 10; i++ {
	fmt.Println(i)
}
```

* `for Expression1; Expression2; Expression3 {処理内容}`のように書く
    * Expression1はforループの開始前に呼ばれる
    * Expression2は処理開始前に呼ばれ，trueならば処理が実行される
    * Expression3は処理終了時に呼ばれる
* Expression1とExpression3は省略可能
    * Goにはwhileループがないがforで代用できる

### switch

```go
i := 5
// i is 5
// i is greater than 4
switch i {
case 1:
	fmt.Println("i is 1")
case 2, 3, 4:
	fmt.Println("i is 2, 3 or 4")
case 5:
	fmt.Println("i is 5")
	fallthrough
default:
	fmt.Println("i is greater than 4")
}

switch {
case i % 15 == 0:
	fmt.Println("FizzBuzz")
case i % 3 == 0:
	fmt.Println("Fizz")
case i % 5 == 0:
	fmt.Println("Buzz")
default:
	fmt.Println(i)
}
```

* `switch 変数 { case 値: 処理内容 }`のように書く
* 値は,区切りで複数書くこともできる
* マッチした場合は処理を実行してswitch文を抜ける
    * `fallthrough`を書くことでひとつ下のcaseの処理も実行することができる
* どのcaseにも一致しなかった場合はdefaultが実行される
    * defaultは省略でき，省略した場合defaultでは何もしない
* 値に等しいかどうかだけでなく，不等式なども使うことができる

## インターフェース

```go
// インターフェースを宣言
// メソッド名と引数，戻り値のみ定義する
type Interface1 interface {
	returnVariable() string
}

// ひとつめの構造体を定義
// インターフェース内で定義したメソッドreturnVariableを実装する
type Struct1 struct {
	var1 string
}
func (s Struct1) returnVariable() string {
	return "valiable: " + s.var1
}

// ふたつめの構造体を定義
// こちらでもインターフェース内で定義したメソッドを実装する
type Struct2 struct {
	var1 string
}
func (s Struct2) returnVariable() string {
	return s.var1 + " is the variable of this"
}

func printVariable(i Interface1) {
	fmt.Println(i.returnVariable())
}

func main() {
	s1 := Struct1{var1: "hoge"}
	s2 := Struct2{var1: "huga"}

	// Struct1，Struct2ともにInterface1型として扱える
	printVariable(s1)      // valiable: hoge
	printVariable(s2)      // huga is the variable of this
}
```

* `type インターフェース名 interface`形式で宣言する
* インターフェース内で定義したメソッドを全て実装するとでインターフェースを利用できるようになる

### 空インターフェース

```go
var x interface{}
num := 0
str := "hello"
// Integer
x = num
fmt.Printf("%d\n", x)
// String
x = str
fmt.Printf("%s\n", x)
```

* 1つもメソッドを定義しないインターフェースを「空インターフェース」と呼ぶ
* 空のインターフェースには何の機能もないが，空インターフェース型の変数には任意の型の値を格納することができる

### 型アサーション

```go
func isString(a interface{}) bool {
	_, ok := a.(string)
	return ok
}

func printType(a interface{}) {
	switch value := a.(type) {
	case int:
		fmt.Printf("int %d\n", value)
	case string:
		fmt.Printf("string %s\n", value)
	default:
		fmt.Printf("other")
	}
}

func main() {
	var y interface{} = 10
	i1, i2 := y.(int)
	fmt.Println(i1, i2)            // 10 true

	var j1 interface{} = 1
	var j2 interface{} = "hoge"
	fmt.Println(isString(j1))      // false
	fmt.Println(isString(j2))      // true
	printType(j1)                  // int 1
	printType(j2)                  // string hoge
}
```

* `インターフェース型変数.(型名)`で`変数に格納された値, boolean`が返る
    * booleanには，変数に格納された値の型が引数に与えた型に一致する場合にtrueが格納される
* 空インターフェースに格納した値の型を特定するのに利用する
