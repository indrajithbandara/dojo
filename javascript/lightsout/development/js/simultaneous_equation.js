function SimultaneousEquation(sizeOfBoard) {
  var myself = this;
  /** 盤のライトの数 */
  const SIZE_OF_BOARD = sizeOfBoard || 25;
  /** 盤の縦横の数 */
  const WIDTH_OF_BOARD = Math.sqrt(SIZE_OF_BOARD);
  /** 連立方程式の左辺を取り出すインデックス値 */
  const I_EXPRESSION_LEFT = 0;
  /** 連立方程式の右辺を取り出すインデックス値 */
  const I_EXPRESSION_RIGHT = 1;
  /** 連立方程式 */
  var expressions;
  /** 解あり or 無しを判定するための方程式を取得するためのインデックス一覧 */
  var validatePoints = [];
  /** 解を求めるための方程式を取得するためのインデックス一覧 */
  var availablePoints = [];

  /** 連立方程式を作成して整理する */
  this.init = function() {
    expressions = new Array(SIZE_OF_BOARD);
    for(var i = 0; i < expressions.length; ++i) {
      var expressionLeft = new Array(SIZE_OF_BOARD);
      var expressionRight = new Array(SIZE_OF_BOARD);
      expressionLeft.fill(false);
      expressionRight.fill(false);

      myself.getExpectedStatus(expressionLeft, i);
      expressionRight[i] = true;
      expressions[i] = [expressionLeft, expressionRight];
    }

    // 連立方程式を各ボタンごとに整理された形式に変換する
    for(var i = 0; i < expressions.length; ++i) {
      var effected = myself._getEffectedExpressionFromLeft(i);

      if(effected === undefined) {
        validatePoints.push(i);
        continue;
      }

      availablePoints.push(i);
      myself._calcSystemOfEquations(effected, i);
    }

    // myself.dumpExpressions(expressions);  // TODO: debug: 完成した連立方程式を表示する
  }

  /**
   * 連立方程式を用いて解を求める
   * @param 盤の状態
   */
  this.calculate = function(board) {
    // 解があるかどうかを判定する。解が無い場合はreturn null
    var notExistence = false;

    for(var i = 0; i < validatePoints.length; ++i) {
      var right = expressions[validatePoints[i]][I_EXPRESSION_RIGHT]
      for(var j = 0; j < right.length; ++j) {
        if(right[j]) notExistence = (notExistence !== board[j]);
      }

      if(notExistence) return null;
    }

    // 解がある場合は解を求める
    var result = new Array(SIZE_OF_BOARD);
    result.fill(false);

    availablePoints.forEach((index) => {
      if(board[index]) {
        expression = expressions[index];
        for(var i = 0; i < expression[I_EXPRESSION_RIGHT].length; ++i) {
          result[i] = (result[i] !== expression[I_EXPRESSION_RIGHT][i]);
        }
      }
    });

    return result;
  }

  /**
   * 連立方程式を用いて、必ず解のある状態の配置でライトをシャッフルする
   */
  this.shuffle = function() {
    var result = new Array(SIZE_OF_BOARD);
    result.fill(false);
    var expression;

    for(var i = 0; i < availablePoints.length; ++i) {
      expression = expressions[availablePoints[i]][I_EXPRESSION_LEFT];

      if(Math.floor(Math.random() * 2) % 2 === 1) continue;
      for(var j = 0; j < SIZE_OF_BOARD; ++j) {
        if(expression[j]) {
          result[j] = !result[j];
        }
      }
    }

    return result;
  }

  /**
   * 連立方程式を計算する
   * @param effected 影響のある式一覧
   * @param pivotIndex 計算を行うときに元となる式
   */
  this._calcSystemOfEquations = function(effected, pivotIndex) {
    var pivot = expressions[pivotIndex];

    for(var i = 0; i < effected.length; ++i) {
      for(var j = 0; j < effected[i][I_EXPRESSION_LEFT].length; ++j) {
        effected[i][I_EXPRESSION_LEFT][j] = (effected[i][I_EXPRESSION_LEFT][j] != pivot[I_EXPRESSION_LEFT][j]);
        effected[i][I_EXPRESSION_RIGHT][j] = (effected[i][I_EXPRESSION_RIGHT][j] != pivot[I_EXPRESSION_RIGHT][j]);
      }
    }
  }

  /**
   * 連立方程式の中から、左辺の式から、引数に指定した位置のライトに影響のある式一覧を返す
   */
  this._getEffectedExpressionFromLeft = function(position) {
    myself._swapExpressionsIfNessesally(position);

    if(!expressions[position][I_EXPRESSION_LEFT][position]) {
      return undefined;
    }

    var results = [];

    for(var i = 0; i < expressions.length; ++i) {
      if(i === position) continue;

      if(expressions[i][I_EXPRESSION_LEFT][position]) {
        results.push(expressions[i]);
      }
    }

    return (results.length === 0? undefined: results);
  }

  /**
   * 連立方程式の式の順番を入れ替える
   * @param position 入れ替える式の場所
   */
  this._swapExpressionsIfNessesally = function(position) {
    if(!expressions[position][I_EXPRESSION_LEFT][position]) {
      for(var i = position + 1; i < expressions.length; ++i) {
        if(expressions[i][I_EXPRESSION_LEFT][position])  {
          var tmp = expressions[position];
          expressions[position] = expressions[i];
          expressions[i] = tmp;
          break;
        }
      }
    }
  }

  /**
   * あるボタンを押下したときの結果予想を取得する。
   * @param board 押下する盤の状態
   * @param position 押下位置
   */
  this.getExpectedStatus = function(board, position) {
    if(position > (WIDTH_OF_BOARD - 1)) {
      board[position - WIDTH_OF_BOARD] = !board[position - WIDTH_OF_BOARD];
    }
    if(position % WIDTH_OF_BOARD != 0) {
      board[position - 1] = !board[position - 1];
    }
    if((position % WIDTH_OF_BOARD) != (WIDTH_OF_BOARD - 1)) {
      board[position + 1] = !board[position + 1];
    }
    if(position < SIZE_OF_BOARD - WIDTH_OF_BOARD) {
      board[position + WIDTH_OF_BOARD] = !board[position + WIDTH_OF_BOARD];
    }

    board[position] = !board[position];
  }

  /**
   * 連立方程式をコンソール出力する
   * @param expressions 連立方程式の式一覧
   * @param position 出力時に行マークを付ける位置
   */
  this.dumpExpressions = function(expressions, position) {
    var left, right, line;
    var p = position || -1;

    for(var i = 0; i < expressions.length; ++i) {
      line = (p == i? "* ": "  ") + myself.getPadding4Digit(i) + i + ": ";

      left = expressions[i][I_EXPRESSION_LEFT];
      for(var j = 0; j < left.length; ++j) {
        line += (left[j] ? "1" : "0");
      }
      line += " | ";

      right = expressions[i][I_EXPRESSION_RIGHT];
      for(var j = 0; j < right.length; ++j) {
        line += (right[j] ? "1": "0");
      }
    }
  }

  /**
   * debug 出力のための数値パディング
   * @param num padding 対象の数字
   */
  this.getPadding4Digit = function(num) {
    if(num >= 1000)
      return "";
    if(num >= 100)
      return "0";
    if(num >= 10)
      return "00";

    return "000"
  }
}

