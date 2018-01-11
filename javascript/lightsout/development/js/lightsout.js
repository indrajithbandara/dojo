window.onload = function() {

  /** ライツアウトのチェックボックス要素リスト */
  var lightsList = Array.prototype.slice.call(document.getElementsByClassName("light"));
  /** Start/Stop ボタンオブジェクト */
  var toggleButton = document.getElementById("toggleButton");
  /** Start/Stop ボタンの文字部分 */
  var stringStartAndPause = document.getElementById("stringButtonPlayAndPause");
  /** Start/Stop ボタンのアイコン部分 */
  var iconStartAndPause = document.getElementById("glyphPlayAndPause");
  /** Shuffle ボタンオブジェクト */
  var shuffleButton = document.getElementById("shuffleButton");
  /** king ボタンオブジェクト(ランキング閲覧用ボタン) */
  var kingButton    = document.getElementById("rankingButton");
  /** ストップウォッチ */
  var stopwatch = new StopWatch();

  /** ハート文字のオブジェクト */
  var heartLeft = document.getElementById("heartLeft");
  /** ヒントモードフラグ */
  //var modeHint = false;
  var modeHint = false;
  
  /** ヒントチェック済みライトリスト */
  var lightsHinted = [];

  /** クリア時のモーダル表示ボタン */
  var buttonShowClearModal = document.getElementById("showClearModal");

  /** ボードのサイズ */
  const SIZE_OF_BOARD = lightsList.length;
  /** ボードの幅 */
  const WIDTH_OF_BOARD = Math.sqrt(SIZE_OF_BOARD);
  /** median of board */
  const MEDIAN_OF_BOARD = Math.floor(SIZE_OF_BOARD / 2);
  /** ゲーム中をあらわすフラグ */
  var inGame = false;
  /** クリア済みフラグ */
  var cleared = false;
  /** ハートが落ちたかどうかのフラグ */
  var heartDropped = false;
  /** ランキングオブジェクト */
  var ranking = new Ranking();
  /** 連立方程式オブジェクト */
  var se = new SimultaneousEquation();
  se.init();

  /** ボタンのon 状態 */
  const LIGHT_ON = "light btn btn-success";
  /** ボタンのoff 状態 */
  const LIGHT_OFF = "light btn btn-default";

  /** Start アイコンクラス */
  const GLYPH_ICON_PLAY = "glyphicon glyphicon-play";
  /** Pause アイコンクラス */
  const GLYPH_ICON_PAUSE = "glyphicon glyphicon-pause";

  /** Heart 通常時 */
  const HEART_NORMAL = "heartLeftDefault glyphicon glyphicon-heart";
  /** Heart ゲーム時 */
  const HEART_IN_GAME = "heartLeftDefault glyphicon glyphicon-heart animated infinite flipInY";
  /** Heart が落ちるクラス */
  const HEART_DROP = "heartLeftDefault glyphicon glyphicon-heart animated hinge";

  // ストップウォッチの表示
  stopwatch.show();

  for(var i = 0, num = lightsList.length; i < num; ++i) {
    lightsList[i].onclick = function() {
      executeElement(this);
    }
  }

  /** ボタンの位置を取得する */
  function getIndex(element) {
    return lightsList.indexOf(element);
  }

  /**
   * Start/Stop ボタンを押した時のイベント
   */
  toggleButton.onclick = function() {
    if(cleared) return;

    if(inGame) {
      // ゲームを一時停止する
      stopwatch.stop();
      inGame = false;
      if(!heartDropped) {
        heartLeft.className = HEART_NORMAL;
      }
      stringStartAndPause.innerHTML = "Start";
      iconStartAndPause.className = GLYPH_ICON_PLAY;
    } else {
      if(!isGameOver()) {
        // ゲームを開始する
        inGame = true;
        if(!heartDropped) {
          heartLeft.className = HEART_IN_GAME;
        }
        stringStartAndPause.innerHTML = "Pause";
        iconStartAndPause.className = GLYPH_ICON_PAUSE;
        stopwatch.start();
      }
    }
  }

  heartLeft.onclick = function() {
    if(!inGame && !heartDropped) {
      heartDropped = true;
      heartLeft.className = HEART_DROP;

      // ヒントモード
      modeHint = true;
      var calculated = convertToListFromLightsList();
      setTimeout(function() { showHint(calculated); }, 1400);
    }
  }

  /**
   * ランキング参照ボタンを押した時のイベント
   */
  kingButton.onclick = function() {
    if(cleared !== true && inGame !== true) {
      buttonShowClearModal.click();
      ranking.showCurrentStoredRanking();
    }
  }

  /**
   * ゲーム完了処理
   */
  function finishGame() {
    cleared = true;
    stopwatch.stop();
  }

  /**
   * Shuffle ボタンを押下した時のイベント
   */
  shuffleButton.onclick = function() {

    if(cleared) return;

    if(!inGame) {
      var shuffled = se.shuffle();
      for(var i = 0; i < shuffled.length; ++i) {
        lightsList[i].className = (shuffled[i]? LIGHT_ON: LIGHT_OFF);
      }
      // ヒントモードの場合はヒントを表示する
      if(modeHint) showHint();
    }
  }

  /**
   * ヒントを再表示する
   */
  function showHint(calculated) {
    // ヒントがすでに表示されている場合は、一旦すべてのヒントをクリアする
    for(var i = 0; i < lightsHinted.length; ++i) {
      if(lightsHinted[i]) {
        lightsList[i].innerHTML="";
      }
    }
    lightsHinted.fill(false);

    var board = calculated || convertToListFromLightsList();
    var calcResult = se.calculate(board);

    if(calcResult === null) {
        // 解無し
        lightsList[MEDIAN_OF_BOARD].innerHTML="<span class=\"icomoon icon-crying animated fadeInDown\"></span>";
        lightsHinted[MEDIAN_OF_BOARD] = true;
        return;
    }

    for(var i = 0; i < calcResult.length; ++i) {
      if(calcResult[i]) {
        lightsList[i].innerHTML="<span class=\"icomoon icon-grin animated bounceInDown\"></span>";
      }
    }
    lightsHinted = calcResult;
  }

  /**
   * 盤の点灯状態をboolean の配列で取得する
   */
  function convertToListFromLightsList() {
    var result = new Array(lightsList.length);
    result.fill(false);

    for(var i = 0; i < lightsList.length; ++i) {
      result[i] = (lightsList[i].className === LIGHT_ON? true: false);
    }

    return result;
  }

  /**
   * ゲームオーバーかどうかを判定する
   */
  function isGameOver() {
    for(var i = 0, num = lightsList.length; i < num; ++i) {
      if(lightsList[i].className === LIGHT_ON) {
        return false;
      }
    }
    return true;
  }

  /**
   * 各タイトがクリックされた時の処理
   */
  function executeElement(element) {
    var index = getIndex(element);
    console.log("This element is index " + index);

    if(cleared) return;

    // クリックしたところのマスの状態を反転する
    lightsList[index].className =
        (lightsList[index].className === LIGHT_ON? LIGHT_OFF: LIGHT_ON);

    if(!inGame) {
      if(modeHint) showHint();
      return;
    }

    // クリックしたところの上のマスの状態を反転する
    if(index - WIDTH_OF_BOARD >= 0) {
      lightsList[index - WIDTH_OF_BOARD].className =
          (lightsList[index - WIDTH_OF_BOARD].className === LIGHT_ON? LIGHT_OFF: LIGHT_ON);
    }

    // クリックしたところの右のマスの状態を反転する
    if((index + 1) % WIDTH_OF_BOARD !== 0) {
      lightsList[index + 1].className =
          (lightsList[index + 1].className === LIGHT_ON? LIGHT_OFF: LIGHT_ON);
    }

    // クリックしたところの下のマスの状態を反転する
    if(index + WIDTH_OF_BOARD < Math.pow(WIDTH_OF_BOARD, 2)) {
      lightsList[index + WIDTH_OF_BOARD].className =
          (lightsList[index + WIDTH_OF_BOARD].className === LIGHT_ON? LIGHT_OFF: LIGHT_ON);
    }

    // クリックしたところの左のマスの状態を反転する
    if(index % WIDTH_OF_BOARD !== 0) {
      lightsList[index - 1].className =
          (lightsList[index - 1].className === LIGHT_ON? LIGHT_OFF: LIGHT_ON);
    }

    // ヒントモード且つヒントの部分をクリックした場合はヒントを消していく
    if(modeHint) {
      if(lightsHinted[index]) {
        lightsList[index].innerHTML="<span class=\"icomoon icon-baffled animated bounceOutUp\"></span>";
        lightsHinted[index] = !lightsHinted[index];
      }
    }

    // ゲームの終了判定を行う
    if(isGameOver()) {
      cleared = true;
      if(!heartDropped) {
        heartLeft.className = HEART_NORMAL;
      }
      stopwatch.stop();
      tubularResume();

      setTimeout(function() {
        var clearTime = document.getElementById('time').innerText;
        ranking.showRankingResult(
          clearTime,
          function(localClearTime, localRankInIndex, localRankingRecord) {
            buttonShowClearModal.click();
            ranking.showRankIn(localClearTime, localRankInIndex, localRankingRecord);
          },
          function(localRankingRecord, localRankInIndex) {
            buttonShowClearModal.click();
            ranking.showRanking(localRankingRecord, localRankInIndex);
          }
        );
      }, getMoviePlayTime());
    }
  } /* end of executeElement(element) */
};

