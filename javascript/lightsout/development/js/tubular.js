/**
 * tubular
 * http://www.seanmccambridge.com/tubular/
 * 
 * The MIT License (MIT)
 * 
 * Copyright (c) <year> <copyright holders>
 * 
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

//tubular ネタは、当時勉強会に参加されていたkobake さんのアイデアです。<(_ _)>

/** tubular 使用フラグ */
var tubularUseTubular = true;
/** クリア時のムービーの開始位置 */
var tubularMovieStartPoint = 94;
/** ムービーの再生時間(ミリ秒) */
var tubularMoviePlayTime = 8000;
/** tubular 初期化フラグ */
var tubularInited = false;
/** ムービー再生済みフラグ */
var tubularFinished = false;

/**
 * tubular を初期化する
 */
function tubularInit() {

  var tag = document.createElement('script');
  tag.src = "https://www.youtube.com/iframe_api";
  var firstScriptTag = document.getElementsByTagName('script')[0];
  firstScriptTag.parentNode.insertBefore(tag, firstScriptTag);

  var $body = $('body'); // cache body node

  // #tubular-container, #tubular-player, #tubular-shield
  var tubularContainer = '<div id="tubular-container" style="overflow: hidden; position: fixed; z-index: 1; width: 0; height: 0"><div id="tubular-player" style="position: absolute; width: 0; height: 0; border: 0;"></div></div><div id="tubular-shield" style="width: 0; height: 0; z-index: 2; position: absolute; left: 0; top: 0;"></div>';

  $('html,body').css({'width': '100%', 'height': '100%'});
  $body.prepend(tubularContainer);

  window.player;
  window.onYouTubeIframeAPIReady = function() {
    player = new YT.Player('tubular-player', {
      width: document.documentElement.clientWidth,
      height: (Math.ceil(document.documentElement.clientWidth / (16 / 9))),
      videoId: 'OnoNITE-CLc',
      mute: true,
      playerVars: {
        controls: 0,
        showinfo: 0,
        modestbranding: 1,
        wmode: 'transparent'
      },
      events: {
        'onReady': onPlayerReady,
        'onStateChange': onPlayerStateChange
      }
    });
  }

  window.onPlayerReady = function(event) {
    event.target.playVideo();
  }

  window.onPlayerStateChange = function(event) {

    if(!player.isMuted() && !tubularFinished) {
      player.mute();
    }

    if(event.data !== YT.PlayerState.PAUSED
          && event.data === YT.PlayerState.PLAYING
          && !tubularFinished) {
      event.target.seekTo(tubularMovieStartPoint);
      player.pauseVideo();
    }
  }

  window.stopVideo = function() {
    player.stopVideo();
  }
}
// TODO: 開発中は、重たいので、コメントアウトしておく
// tubular 初期化処理
// setTimeout を使うのは、ローカルファイルでWorker が使用できないため
// アニメーション処理とtublar 初期化処理が重ならないようにする
if(tubularUseTubular) {
  setTimeout('if(!tubularInited) {tubularInited = true; tubularInit();}', 900);
}

/**
 * play 時間を取得する
 */
function getMoviePlayTime() {
  if(!tubularUseTubular || !tubularInited
      || window.player === undefined || player.playVideo === undefined) {
    // Youtube のインスタンス生成に失敗している場合は再生させない
    return 0;
  }
  return tubularMoviePlayTime;
}

/**
 * tubular を再開する
 */
function tubularResume() {

  if(!tubularUseTubular || !tubularInited
      || window.player === undefined || player.playVideo === undefined) {
    // Youtube Player のインスタンス生成に失敗している場合は再生しない
    return;
  }

  $("#tubular-container, #tubular-player, #tubular-shield").css({
    "width": document.documentElement.clientWidth,
    "height": ( Math.ceil(document.documentElement.clientWidth / (16 / 9)) )
  });

  if(player.isMuted()) player.unMute();  // ミュートを解除
  tubularFinished = true;                // クリアステートをtrue に設定

  // 動画を再開し、停止時間を設定する
  player.playVideo();
  setTimeout(
    function() {
      // TODO: iframe を先に消してからstop を呼び出してしまうと
      //       "Uncaught TypeError: Cannot read property 'postMessage' of null" エラーメッセージが出る。
      //       原因はDOM のレンダリングが終了する前にYoutube player のロードが開始されてしまうため。
      //       置き換え対象のiframe が存在しない状態でYoutube Player の初期化をしてビデオをplay, stop, change すると
      //       このようなエラーが出るようになる。
      stopVideo();
      $("#tubular-container, #tubular-player, #tubular-shield").remove();
    }, tubularMoviePlayTime
  );
}

