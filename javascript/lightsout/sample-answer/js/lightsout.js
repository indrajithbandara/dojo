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

  toggleButton.innerHTML = "Start";

  for(var i = 0, num = lightsList.length; i < num; ++i) {
    //elemList.push(lightsList[i]);

    lightsList[i].onclick = function() {
      executeElement(this);
    }
  }

  function getIndex(element) {
    return lightsList.indexOf(element);
  }

  // Start/Stop ボタンを押した時のイベント
  toggleButton.onclick = function() {
    if(inGame) {
      inGame = false;
      toggleButton.innerHTML = "Start";
    } else {
      if(!isGameOver()) {
        inGame = true;
        toggleButton.innerHTML = "Stop";
      }
    }
  }

  // Shuffle ボタンを押下した時のイベント
  shuffleButton.onclick = function() {

    while(!inGame) {
      for(var i = 0, num = lightsList.length; i < num; ++i) {
        lightsList[i].checked = (Math.floor(Math.random() * 2) % 2 === 0);
      }

      if(!isGameOver()) break;
    }
  }

  function isGameOver() {
    for(var i = 0, num = lightsList.length; i < num; ++i) {
      if(lightsList[i].checked) {
        return false;
      }
    }
    return true;
  }

  function executeElement(element) {
    var index = getIndex(element);
    console.log("This element is index " + index);

    // ゲームがまだ開始していない場合は、四方の反転処理を行わない
    if(!inGame) {
      return;
    }

    // クリックしたところの上のマスの状態を反転する
    var aboveIndex = index - sizeOfBoard;
    if(index > (sizeOfBoard - 1)) {    // index > 4
      if(lightsList[aboveIndex].checked) {
        lightsList[aboveIndex].checked = false;
      } else {
        lightsList[aboveIndex].checked = true;
      }
    }

    // クリックしたところの左のマスの状態を反転する
    var leftIndex = index - 1;
    if((index % sizeOfBoard) !== 0) {    // (index % 5) != 0
      if(lightsList[leftIndex].checked) {
        lightsList[leftIndex].checked = false;
      } else {
        lightsList[leftIndex].checked = true;
      }
    }

    // クリックしたところの右のマスの状態を反転する
    var rightIndex = index + 1;
    if((index % sizeOfBoard) !== 4) {    // (index % 5) != 4
      if(lightsList[rightIndex].checked) {
        lightsList[rightIndex].checked = false;
      } else {
        lightsList[rightIndex].checked = true;
      }
    }

    // クリックしたところの下のマスの状態を反転する
    var belowIndex = index + sizeOfBoard;
    if(index < (Math.pow(sizeOfBoard, 2) - sizeOfBoard)) {   // index < 20
      if(lightsList[belowIndex].checked) {
        lightsList[belowIndex].checked = false;
      } else {
        lightsList[belowIndex].checked = true;
      }
    }

    // ゲームの終了判定を行う
    if(isGameOver()) {
      toggleButton.click();
      alert("おめでとう!");
    }
  }
};

