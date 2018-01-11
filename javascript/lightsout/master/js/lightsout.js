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
    inGame = true;
  }

  /**
   * Shuffle ボタンを押下した時のイベント
   */
  shuffleButton.onclick = function() {
    // FIXME: 各ボタンのチェック状態をシャッフルする
  }

  /**
   * ゲームが終了しているか判定する。
   * ゲームが終了している場合は、return true を、
   * ゲームが終了していない場合は、return false を返す。
   */
  function isGameOver() {
    // FIXME: ゲームの終了判定を行う
    // return true or false
  }

  function executeElement(element) {

    var index = getIndex(element);

    // FIXME: ゲームがまだ開始していない場合は周りのボタンを反転しない

    // FIXME: クリックしたところの上のマスの状態を反転する
    //        左上から順番に... 0〜24 のindex が割り当てられるので、
    //        クリックしたところの上のマス目のindex を四則演算で求めることができる。

    // FIXME: クリックしたところの右のマスの状態を反転する

    // FIXME: クリックしたところの左のマスの状態を反転する

    // FIXME: クリックしたところの下のマスの状態を反転する

    // FIXME: ゲームの終了判定を行う
    //        isGameOver() メソッドに実装する

  }
};

