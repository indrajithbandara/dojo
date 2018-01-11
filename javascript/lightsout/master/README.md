# プログラミング研修用課題ライツアウト
プログラミングはどんなものかを軽く体験するための、JavaScript によるゲーム作成課題です。
本課題を通して、プログラミングの難しさ、楽しさ、作業の工程といったものを体験できることを期待しています。

# ライツアウトのゲームのルール
5 * 5 の形に並んだ、プレイヤーがあるライトを押すと自身とその上下左右4 個のライトの点灯状態が一緒に反転するという法則にしたがって、並んでいるライトすべてを消灯させることを目的としたゲームです。
詳しい説明については、下記Wikipedia に掲載されています。
``` Wikipedia:ライツアウト
https://ja.wikipedia.org/wiki/ライツアウト
```

# 謝辞
この課題のアイデアは、NobuyaIshikawa 氏のjQuery-intro-work の一部の問題を参考にしています。
この場を借りて感謝の意を表させていただきます<(_ _)>

# 課題
lightsout.html を適当なWeb ブラウザで開くと、5 * 5 のチェックボックスのマスが出てきます。
lightsout.html はjs/lightsout.js からJavaScript のソースコードを読み取り、動的な処理を行うことができるようになっています。
本課題では、js/lightsout.js のJavaScript ソースコード内にある"FIXME:" と書かれている箇所の問題を解いていって、LightsOut のゲームを完成させてください。
課題解答の優先順位の目安としては以下の通りです。
- クリックしたところの上/右/下/左 のマスの状態を反転する
- ゲームの終了判定を行う
- 一方的にON にすることしかできないので、必要に応じてtrue/false を反転させる
- ゲームがまだ開始していない場合は周りのボタンを反転しない
- チェックボックスの状態をシャッフルする

# 技術的な内容について
lightsout.html を開くと以下のような5 * 5 のチェックボックスが出てきます。  
![LightsOut初期画面](https://raw.githubusercontent.com/TsutomuNakamura/LightsOut/master/img/LightsOut_01.png)  

左上から順に0 ~ 24 のインデックスが割り当てられています。
いずれかのチェックボックスをクリックすると、そのチェックボックスのindex が取得できるようになっているので、そこから4 方のボタンのインデックスを導き出すことができます。

## JavaScript の基本的な技術要素について
### 配列
配列とはデータ構造の一種で複数(0、1個も可)のデータが連続的に格納されたデータ構造です。配列の中の特定のデータにアクセスするには添字を使用します。

```JavaScript
// 配列の定義
// プログラムでは、イコール(=) は等しいという意味ではなく代入
var some_array = ["要素1", "要素2", "要素3"];

// 配列の2 番目の要素にアクセスして内容を表示する。
// 配列の添字は0 から開始するので2 番目の要素にアクセスする場合は添字1 を使用する
console.log(some_array[1]);
```

### 条件分岐(if 構文)
if 構文を使用することで、条件によって処理を分岐させることができます。  

* if 構文の書式
```JavaScript
if(条件式1) {
    // 条件式1 がtrue だった場合の処理
} else if(条件式2) {    // (任意)
    // 条件式2 がtrue だった場合の処理
} else {
    // 上記のいずれにも該当しない場合の処理
}
```

* if 構文の例
```JavaScript
var result = 2 + 10;
if(result > 10) {
    console.log("Greater than 10");
} else if(result === 10) {
    console.log("Equal 10");
} else {
    console.log("Smaller than 10");
}
```

* 実行結果例
```JavaScript
Greater than 10
```

### 繰り返し(for 構文)
for 構文を使用することで、一定の条件を満たす間、処理を繰り返すことができます。

* for 構文の書式
```JavaScript
for(初期値; 繰り返し条件; 継続処理) {
    // 処理
}
```

上記の構文に従って"Hello world!" を10 回出力するプログラムは、例えば次のように書くことができます。
```JavaScript
var loopNum = 10;
for(var i = 0; i < loopNum; i++) {
    // "i < loopNum" の条件を満たす間、この処理が実行される。
    // 一番右の項の"i++" はloop が1 回実行されるごとに"i++" 処理が
    // 1 回実行されるということで、
    // "i++" は、現在のi の値に1 を加算するという処理になる。
    console.log("Hello world!");
}
```

この構文を利用して、配列の内容全てに対してアクセスするには、次のようにすることで出木ます。
```JavaScript
var elements = ["element0", "element1", "element2"];
for(var i = 0; i < elements.length; i++) {
    // elements.length でelements 配列のサイズを取得することができる。
    // 今回の例の場合は、3 が返ってくる。
    // elements 要素の値に1 つずつアクセスして、すべて出力する。
    console.log("element[" + i + "] is " + elements[i]);
}
```

出力例
```
element[0] is element0
element[1] is element1
element[2] is element2
```

### 関数(メソッド)
JavaScript やその他のプログラムでは、複数の処理から成り立つ一連の処理を一つの関数として定義することができます。
"retrun" キーワードを使用することで、処理を関数の呼び出し元に返すと同時に特定の値を返すことができるようになります。  
関数の書式は以下のようになります。
```JavaScript
// 関数の定義
function getTommorowDate(引数) {
    return 戻り値
}

// 関数呼び出し
var result = getTommorowDate(引数);
```

例として、現在の次の日(文字列) を取得する場合は、次のように関数を定義して呼び出します。
```JavaScript
// 関数の定義。
// 現在日時の1 日先の文字列を"YYYY MM/DD HH:mm:ss" 形式で取得する
function getTommorowDate() {
    var tommorowDate = new Date();
    tommorowDate.setSeconds(1 * 60 * 60 * 24);

    var year = 1900 + tommorowDate.getYear();
    var month = 1 + tommorowDate.getMonth();
    var date = tommorowDate.getDate();

    // return キーワードを使うことで、関数より出し元に処理を戻し、
    // また'year + "/" + month + "/" + date' の値を呼び出し元に返す
    return year + "/" + month + "/" + date;
}

// getTommorowDate() 関数を使うことで一連の処理を完結な記述で
// 取得することができるようになる。
var result = getTommorowDate();
console.log("The result is " + result);
```

関数に引数を渡し、処理内容を動的に変更することができます。
```JavaScript
// 関数の定義。
// 現在日時の1 日先の文字列を"YYYY MM/DD HH:mm:ss" 形式で取得する
// 引数に指定した日数後の日付を取得する。
function getSomeDate(dateDrift) {
    var someDate = new Date();
    someDate.setSeconds(1 * 60 * 60 * 24 * dateDrift);

    var year = 1900 + someDate.getYear();
    var month = 1 + someDate.getMonth();
    var date = someDate.getDate();

    return year + "/" + month + "/" + date;
}

var result = getSomeDate(10);  // 10 日後の日時を取得する
console.log("The result is " + result);
```

### 組込みオブジェクト
JavaScript には組込みオブジェクトと呼ばれる、JavaScript 側で既に用意されているオブジェクトがあります。
その中で便利な算術処理を行うMath オブジェクトというものがあります。
Math オブジェクトを使用することで誰でも複雑な算術処理を簡単に使うことができるようになります。  
  
便利なMath オブジェクトに組み込まれている関数としては、例えば以下のようなものがあります。

#### Math.floor(num)
引数として与えられた数以下の最大の整数を返します。主に少数の小数点以下を切り捨てる場合に使用します。
```JavaScript
console.log(Math.floor(3.14));    // -> 3
```

#### Math.pow(base, exponent)
baseを exponent 乗した値を返します。
```JavaScript
console.log(Math.pow(2, 4));    // -> 16
```

その他のMath 組込みオブジェクトに関する関数としては、下記リンクのようなものがあります。  
[MDN Mathオブジェクト](https://developer.mozilla.org/ja/docs/Web/JavaScript/Reference/Global_Objects/Math)
  
余談になりますが、Math オブジェクト以外にもArray(配列)やString(文字列)もJavaScript の組込みオブジェクトになります。
