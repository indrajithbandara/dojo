function Ranking() {

  /** 自分自身のインスタンス */
  var myself = this;
  /** IndexedDB インスタンス */
  var db;
  /** 最大レコード数 */
  const MAX_RECORD_NUM = 3;
  /** データストア名 */
  const DATA_STORE_NAME = "ranking";
  /** ブラウザのサポートしているIndexedDB */
  window.indexedDB = window.indexedDB
      || window.mozIndexedDB || window.webkitIndexedDB || window.msIndexedDB;

  /**
   * Ranking DB の初期化
   */
  function rankDbInit() {

    if(!window.indexedDB) return;

    // (database name, database version)
    console.log("The version of ranking database is " + parseInt(myself.getCurrentDBVersion(), 10));
    var request = window.indexedDB.open("RankingDB", parseInt(myself.getCurrentDBVersion(), 10) );

    request.onerror = function(event) {
      // Do something with request.errorCode
      alert("Can't use database. Error code: " + event.target.errorCode);
    }

    request.onsuccess = function(event) {
      // Do something with request.result
      db = event.target.result;
    }

    request.onupgradeneeded = function(event) {
      db = event.target.result;

      // TODO: Debug. Create an objectStrore for this database
      // console.log(db.objectStoreNames);

      if(db.objectStoreNames.contains(DATA_STORE_NAME)) {
        db.deleteObjectStore(DATA_STORE_NAME);
      }

      var objectStore = db.createObjectStore(
        DATA_STORE_NAME, {keyPath: "rank", autoIncrement: false}
      );
    }
  }

  /**
   * ランクインしていたら、データを更新する
   */
  this.showRankingResult = function(time, callbackIfRankIn, callbackShowRanking) {
    var transaction = db.transaction([DATA_STORE_NAME], "readonly");
    var objectStore = transaction.objectStore(DATA_STORE_NAME);
    var results     = [];
    var counter     = 0;
    var rankInIndex = 0;

    transaction.oncomplete = function(event) {
      console.log("showRankingResult.transaction.oncomplete");
    }

    transaction.onerror = function(event) {
      console.log("showRankingResult.transaction.onerror");
    }

    transaction.onabort = function(event) {
      console.log("showRankingResult.transaction.onabort");
    }

    objectStore.openCursor().onsuccess = function(event) {
      var cursor = event.target.result;
      counter++;

      if(cursor) {
        // DB 内にレコードが存在する場合

        if(rankInIndex === 0 && cursor.value.time > time) {
          // ランクインした場合は新しいレコードをランキングに挿入する

          rankInIndex = counter;
          results.push(
            {rank: rankInIndex, time: time, name: undefined, date: myself.getDateString()});

          if(results.length < MAX_RECORD_NUM) {
            cursor.value.rank = rankInIndex + 1;
            results.push(cursor.value);
          }
        } else {
          // DB 内にレコードが存在しない場合

          if(results.length < MAX_RECORD_NUM) {
            results.push(cursor.value);
          }
        }
        cursor.continue();
      } else {
        // DB から取得するレコードがこれ以上ない場合

        if(rankInIndex === 0 && results.length < MAX_RECORD_NUM) {
          // レコード最大数に達していない時だけ新しくランキングを追加する

          rankInIndex = counter;
          results.push({rank: rankInIndex, time: time, name: undefined, date: myself.getDateString()});
        }
        console.log('All of data has gotten as below.');
        console.log(results);

        if(rankInIndex !== 0) {
          // ランクインしていた場合は名前入力画面を表示する。また、DB も更新する
          callbackIfRankIn(time, rankInIndex, results);
        } else {
          // ランクインしていない場合は、ランキングのみ表示する
          callbackShowRanking(results, rankInIndex);
        }
      }
    } /* end of objectStore.openCursor().onsuccess */
  }

  /**
   * 現在DB 内に格納されているランキングを見る
   */
  this.showCurrentStoredRanking = function() {
    var transaction = db.transaction([DATA_STORE_NAME], "readonly");
    var objectStore = transaction.objectStore(DATA_STORE_NAME);
    var results     = [];

    objectStore.openCursor().onsuccess = function(event) {
      var cursor = event.target.result;
      if(cursor) {
        results.push(cursor.value);
        cursor.continue();
      } else {
        myself.showRanking(results, 0);
      }
    }
  }

  /**
   * rank を指定してデータをDB からデータを取得する
   */
  this.getRankingDataByRank = function(rank) {
    var transaction = db.transaction([DATA_STORE_NAME], "readonly");
    var objectStore = transaction.objectStore(DATA_STORE_NAME);

    var request = objectStore.get(rank);

    request.onerror = function(event) {
      console.log("getRankingDataByRank onerror");
    };
    request.onsuccess = function(event) {
      console.log("getRankingDataByRank onsuccess. Result of search by rank \""
        + rank + "\" is: time->" + request.time + ", name->" + request.name + ", date->" + request.date);
    }
  }

  /**
   * 新しいランキングデータに沿ってDB のランキング情報を更新する
   */
  this.updateRankingAlong = function(newRankingRecord, newRankInIndex) {
    for(var i = 0; i < newRankingRecord.length; i++) {
      if(i >= newRankInIndex - 1) {
        myself.addOrUpdateData(
          i + 1,
          newRankingRecord[i].time,
          newRankingRecord[i].name,
          newRankingRecord[i].date
        );
      }
    }
  }

  /**
   * データを追加する。すでに同じrank でデータが追加されている場合は、更新する
   */
  this.addOrUpdateData = function(rank, time, name, date) {
    var objectStore = db.transaction([DATA_STORE_NAME], "readwrite").objectStore(DATA_STORE_NAME);
    var request = objectStore.get(rank);

    request.onerror = function(event) {
      console.log("addOrUpdateData request.onerror");
    }

    request.onsuccess = function(event) {
      var data = request.result;

      if(data === undefined) {
        // 該当のrank のデータが存在しない場合は新規追加する

        var requestAdd = objectStore.add({
          rank: rank, time: time, name: name, date: date
        });

        requestAdd.onerror = function(event) {
          console.log("addOrUpdateData.requestAdd.onerror");
        }
        requestAdd.onsuccess = function(event) {
          console.log("addOrUpdateData.requestAdd.onsuccess");
        }
      } else {
        // 該当のrank のデータが存在する場合は更新する

        data.time = time;
        data.name = name;
        data.date = date;
        var requestUpdate = objectStore.put(data);

        requestUpdate.onerror = function(event) {
          console.log("addOrUpdateData.requestUpdate.onerror");
        }
        requestUpdate.onsuccess = function(event) {
          console.log("addOrUpdateData.requestUpdate.onsuccess");
        }
      }
    }
  }

  /**
   * ランキングを表示する
   */
  this.showRanking = function(rankingData, rankHighlight) {

    var recordNum = 0;

    $('#modalHeader, #modalBody').empty();

    $('#modalHeader').prepend(
      '<button type="button" class="close" data-dismiss="modal">&times;</button>' +
      '<h4 class="modal-title">Today\'s Ranking</h4>'
    );

    $('#modalBody').prepend(
      '<table class="table table-striped">' +
      '  <thead id="rank-table-thead">' +
      '    <tr>' +
      '      <th>Rank</th>' +
      '      <th>Time</th>' +
      '      <th>Name</th>' +
      '      <th>Date</th>' +
      '      <th>&nbsp;</th>' +
      '    </tr>' +
      '  </thead>' +
      '  <tbody id="rank-table-tbody"></tbody>' +
      '</table>'
    );

    for(var i = 0; i < MAX_RECORD_NUM; ++i) {
      var record = rankingData[i];
      var rank = 1 + i;
      recordNum++;
      if(record !== undefined) {
        // データが含まれている場合は、そのデータで表示を更新する
        console.log(rankingData[i]);

        $('#rank-table-tbody').append(
          '<tr id="record-' + rank + '" style="visibility: hidden;">' +
          '  <td id="record-rank-' + rank + '" style="vertical-align: middle;">' + record.rank + '</td>' +
          '  <td id="record-time-' + rank + '" style="vertical-align: middle;">' + record.time + '</td>' +
          '  <td id="record-name-' + rank + '" style="vertical-align: middle;">' + record.name + '</td>' +
          '  <td id="record-date-' + rank + '" style="vertical-align: middle;">' + record.date + '</td>' +
          '  <td id="record-delete-' + rank + '" style="vertical-align: middle;">' +
          '    <button id="record-delete-button-' + rank + '" class="btn btn-danger" type="button">Delete</button>' +
          '  </td>' +
          '</tr>'
        );
      } else {
        // データが含まれていない場合はダミーユーザを表示する
        console.log("Rank of " + (i + 1) + " has not registerd yet. Anonymous user will be inserted. [Time:" + myself.getDateString() + "]");
        $('#rank-table-tbody').append(
          '<tr id="record-' + rank + '" style="visibility: hidden;">' +
          '  <td id="record-rank-' + rank + '" style="vertical-align: middle;">' + rank + '</td>' +
          '  <td id="record-time-' + rank + '" style="vertical-align: middle;">99:59:59:999</td>' +
          '  <td id="record-name-' + rank + '" style="vertical-align: middle;">(´-ω-`)ドヤァッ!</td>' +
          '  <td id="record-date-' + rank + '" style="vertical-align: middle;">9999 12/31 23:59:59</td>' +
          '  <td id="record-delete-' + rank + '" style="vertical-align: middle;">' +
          '    <button class="btn btn-danger" style="visibility: hidden;" type="button">&nbsp;</button>' +
          '  </td>' +
          '</tr>'
        );
      }
    }

    // アニメーション
    for(var i = 0; i < recordNum; i++) {
      setTimeout(
        '$("#record-' + (i + 1) + '").addClass("animated fadeIn");' +
        '$("#record-' + (i + 1) + '").css("visibility", "visible");',
        i * 200 + 100
      );
    }
    for(var i = 0; i < recordNum; i++) {
      $('#record-delete-button-' + (i + 1)).click(function() {
        this.className = 'btn btn-danger animated bounceOutUp';
        this.onclick = function() {};
      });
    }
  }

  /**
   * プレイヤーの記録がランクインした場合、名前入力モーダルを表示する
   */
  this.showRankIn = function(timeString, rankInIndex, rankingRecord) {

    $('#modalHeader, #modalBody').empty();

    $('#modalHeader').prepend(
      '<button type="button" class="close" data-dismiss="modal">&times;</button>' +
      '<h4 class="modal-title">Congratulation!</h4>'
    );

    $('#modalBody').prepend(
      '<div style="padding-left: 4px;">' +
      'Your score ' + timeString + ' was ranked in!<br />' +
      'Please tell me your name.' +
      '</div>' +
      '<div class="input-group" style="margin-top: 6px;">' +
      '  <input id="rankInUserName" type="text" class="form-control" placeholder="Your name...">' +
      '  <span class="input-group-btn">' +
      '    <button class="btn btn-default" id="submitToRanking" type="button">Go!</button>' +
      '  </span>' +
      '</div>'
    );

    $('#submitToRanking').click(function() {
      // 入力された名前を取得する

      rankingRecord[rankInIndex - 1].name = $('#rankInUserName').val();
      myself.updateRankingAlong(rankingRecord, rankInIndex);
      myself.showRanking(rankingRecord, rankInIndex);
    });
  }

  this.getDateString = function() {
    var date = new Date();
    return date.getFullYear() + ' '
        + (date.getMonth()   < 9?  '0' + (date.getMonth() + 1): date.getMonth()) + '/'
        + (date.getDate()    < 10? '0' + date.getDate(): date.getDate()) + ' '
        + (date.getHours()   < 10? '0' + date.getHours(): date.getHours()) + ':'
        + (date.getMinutes() < 10? '0' + date.getMinutes(): date.getMinutes()) + ':'
        + (date.getSeconds() < 10? '0' + date.getSeconds(): date.getSeconds());
  }

  /**
   * DB のバージョンを返す(本日の日付形式)
   */
  this.getCurrentDBVersion = function() {
    var date = new Date();
    return date.getFullYear()
        + (date.getMonth()   < 9?  '0' + (date.getMonth() + 1): date.getMonth())
        + (date.getDate()    < 10? '0' + date.getDate(): date.getDate());
  }

  // DB の初期化
  rankDbInit();

  return this;
}

