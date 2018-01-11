window.onload = function() {

  /** ライツアウトのチェックボックス要素リスト */
  var lightsList = Array.prototype.slice.call(document.getElementsByClassName("light"));
  /** Start/Stop ボタンオブジェクト */
  var toggleButton = document.getElementById("toggle");
  /** Shuffle ボタンオブジェクト */
  var shuffleButton = document.getElementById("shuffle");
  /** ボードのサイズ */
  var sizeOfBoard = 5;
  /** ゲーム中をあらわすフラグ */
  var inGame = false;

  toggleButton.innerHTML = "Start";    /* Start ボタンの文字を設定する */

  /**
   * それぞれのチェックボックスにイベントを登録する。
   */
  for(var i = 0, num = lightsList.length; i < num; ++i) {
    lightsList[i].onclick = function() {
      executeElement(this);
    }
  }

  /**
   * チェックボックスのインデックスを取得する
   */
  function getIndex(element) {
    return lightsList.indexOf(element);
  }

  /**
   * Start/Stop ボタンを押下した時の処理
   * inGame フラグのtrue/false を切り替える
   */
  toggleButton.onclick = function() {
    // FIXME: 現状では一方的にON にすることしかできないので、
    //        Start/Stop ボタンをクリックすることで、inGame フラグがtrue/false に切り替わるようにする。
    ////      inGame が既にON になっているときには、OFF になるように、
    ////      inGame が既にOFF になっているときには、ON になるようにし、
    ////      その時のボタンの文字列の表示もわかりやすいものに切り替わるようにする。
    inGame = true;
  }

  /**
   * Shuffle ボタンを押下した時のイベント
   */
  shuffleButton.onclick = function() {
    // FIXME: 各ボタンのチェック状態をシャッフルする
    ////      ランダムな値を返す関数を使用すると便利。
  }

  /**
   * ゲームが終了しているか判定する。
   * ゲームが終了している場合は、return true を、
   * ゲームが終了していない場合は、return false を返す。
   */
  function isGameOver() {
    // FIXME: ゲームの終了判定を行う
    ////      ゲーム終了条件は、すべてのチェックボックスのチェックがOFF になっている時
    // return true or false
  }

  function executeElement(element) {

    var index = getIndex(element);

    // FIXME: ゲームがまだ開始していない場合は周りのボタンを反転しない
    ////      ゲームの状態がゲーム中ではない場合は、処理をreturn する。

    // FIXME: クリックしたところの上のマスの状態を反転する
    //        左上から順番に... 0〜24 のindex が割り当てられるので、
    //        クリックしたところの上のマス目のindex を四則演算で求めることができる。
    //
    ////      クリックしたところの上のボタンの状態を確認し
    ////      そこが既にチェックされている状態であればチェックを解除し、
    ////      まだチェックされていない状態であればチェックを入れる。
    ////
    ////      5 * 5 のマスになっているので、
    ////      一番左上のチェックボックスはindex[0] となり、
    ////      一番上のチェックボックスはindex[4] となり、
    ////      一番下のチェックボックスはindex[24] となる。
    ////      チェックしたボタンの上のボタンを求めるには、
    ////      例えばチェックしたボタンがindex[12] だとすると…

    // FIXME: クリックしたところの左のマスの状態を反転する
    ////
    ////      クリックしたところの左のボタンの状態を確認し
    ////      そこが既にチェックされている状態であればチェックを解除し、
    ////      まだチェックされていない状態であればチェックを入れる。
    ////
    ////      5 * 5 のマスになっているので、
    ////      一番左上のチェックボックスはindex[0] となっているので
    ////      例えばチェックしたボタンがindex[12] だとすると…

    // FIXME: クリックしたところの右のマスの状態を反転する
    ////
    ////      クリックしたところの右のボタンの状態を確認し
    ////      そこが既にチェックされている状態であればチェックを解除し、
    ////      まだチェックされていない状態であればチェックを入れる。
    ////
    ////      5 * 5 のマスになっているので(以下略)

    // FIXME: クリックしたところの下のマスの状態を反転する
    ////
    ////      クリックしたところの下のボタンの状態を確認し
    ////      そこが既にチェックされている状態であればチェックを解除し、
    ////      まだチェックされていない状態であればチェックを入れる。
    ////
    ////      5 * 5 のマスになっているので(以下略)

    // FIXME: ゲームの終了判定を行う
    //        isGameOver() メソッドに実装する
    ////      isGameOver() メソッドにゲームが終了しているかどうかの判定を実装し、
    ////      ゲームが終了している場合(true) はゲームを終了し、
    ////      ゲームが終了していない場合(false) はゲームを続行する。
    ////      ゲーム終了時は、終了のメッセージを何かしらの方法で表示するようにする。

  }
};

