+++
Categories = []
Tags = []
title = "Go言語のお勉強 その2"
date = "2015-07-29T23:07:42+09:00"
aliases = ["/blog/learning-go-02/"]

+++

今日のまとめ

<!--more-->

## 構造体

```go
type User struct {
  name string
  age int
}

func main() {
   var user1 User
   user1.name = "ichiro"
   // ichiro 0
   fmt.Println(user1.name, user1.age)

   user2 := User{"jiro", 30}
   // jiro 30
   fmt.Println(user2.name, user2.age)

   user3 := User{name: "saburo", age: 20}
   // saburo 20
   fmt.Println(user3.name, user3.age)
}
```

* Goの構造体は以下の特徴を持っている
    * 構造体はフィールド(フィールド名と値の組)の集まりである
    * 構造体にメソッドを定義することができる
    * 構造体に構造体を埋め込むことができる
* `type 構造体名 struct`形式で宣言する．
* `構造体名.フィールド名`でフィールドの値にアクセスすることができる
* フィールドの初期化の方法はいくつかある
    * 構造体を初期化してから順に値を入れる
    * 構造体の初期化時にフィールドの値を列挙する
    * 構造体の初期化時に`フィールド名: 値`を列挙する
* **ここで気付いたけど，変数は始めから何かしらの値が入っているようだ**
* **構造体って初めて扱ったけどvalueに色々な型を持てるハッシュみたいなもの？**

### ポインタ型で初期化

```go
user4 := &User{name: "shiro", age: 15}
// shiro 15
// {shiro 15}
fmt.Println(user4.name, user4.age)
fmt.Println(*user4)
 
user5 := new(User)
user5.name = "goro"
// goro 0
// {goro 0}
fmt.Println(user5.name, user5.age)
fmt.Println(*user5)
```

* `&構造体名`または`new(構造体名)`で初期化するとポインタ型で受け取ることができる．

### 関数による初期化

```go
func newUser(name string, age int) *User {
  u := new(User)
  u.name = name
  u.age = age
  return u
}
 
var user *User = newUser("taro",30)
```

### ネスト構造体

```go
type Foo struct {
  hoge string
  huga string
}

type Bar struct {
  Foo
  huga string
  piyo string
}

user5 := new(User)
user5.name = "goro"
fmt.Println(user5.name, user5.age)
fmt.Println(*user5)

str1 := Foo{hoge: "HOGE", huga: "HUGA"}
str2 := Bar{Foo: str1, huga: "Huga", piyo: "Piyo"}
// HOGE Huga HUGA Piyo
fmt.Println(str2.hoge, str2.huga, str2.Foo.huga, str2.piyo)
```

* フィールドに構造体を指定することで構造体をネストすることができる
* ネストした構造体のフィールドへアクセスするには`str2.Foo.huga`のように指定する
* フィールド名が重複していなければ`str2.huga`のように構造体名を省略できる

### メソッド定義

```go
func (u User) greet() string {
	return "hello, " + u.name
}

u := User{"taro", 30}
fmt.Println(u.greet())
```

* `func (レシーバ名 レシーバの型) メソッド名(引数) 返り値`形式で記述する
