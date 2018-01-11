package jp.co.teratech.intern.lightsout.test.util;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.stream.IntStream;

public class P32 {
	// 5*5 のマスでライトを消していくパターンについて検証していく
	public static void main(String args[]) {
		Boolean[] b = {
				false,  true, false,  true, false,
				false, false, false, false, false,
				false, false, false, false, false,
				false, false, false, false, false,
				false, false, false, false, false
		};
		Util.dumpStatOfBoard(new P32().calclate(Arrays.asList(b)).get(0));
	}
	
	/**
	 * 押すべき状態について、一番上段の部分についてのみ考える
	 * 0 0 0 0 0    0: 押下しない
	 * 0 0 0 0 0    1: 押下する
	 * 0 0 0 0 0
	 * 0 0 0 0 0
	 * 0 0 0 0 0
	 * 
	 * 1 行目のが以下のパターンの場合のみについて施行していけば良い。
	 * 2 行目以降の押下順序は機械的に決まっていくので、結果として以下32 パターンについて検証してみれば良い。
	 * 解なしもありうるので、その場合は以下すべてのパターンを実施してみても解は無い。
	 * 別の見解では最初の8 パターンを実施して解答が出ないようであれば、それ以降実施しても解は得られないことが決まる。
	 * ...事前にパターンを決めておいて解答を求めるパターン...
	 * 0 0 0 0 0,
	 * 1 0 0 0 0,
	 * 1 1 0 0 0,
	 * 1 1 1 0 0,
	 * 1 1 1 1 0, 
	 * 1 1 1 1 1,
	 * 1 1 1 0 1,
	 * 1 1 0 1 0,
	 * 1 1 0 1 1, 
	 * 1 1 0 0 1, 
	 * 1 0 1 0 0, 
	 * 1 0 1 1 0,
	 * 1 0 1 1 1, 
	 * 1 0 1 0 1, 
	 * 1 0 0 1 0, 
	 * 1 0 0 1 1, 
	 * 1 0 0 0 1, 
	 * 0 1 0 0 0,
	 * 0 1 1 0 0, 
	 * 0 1 1 1 0, 
	 * 0 1 1 1 1,
	 * 0 1 1 0 1,
	 * 0 1 0 1 0,
	 * 0 1 0 1 1,
	 * 0 1 0 0 1,
	 * 0 0 1 0 0,
	 * 0 0 1 1 0,
	 * 0 0 1 1 1,
	 * 0 0 1 0 1,
	 * 0 0 0 1 0,
	 * 0 0 0 1 1,
	 * 0 0 0 0 1
	 */
	public P32() {}
		
	/**  */
	private static final int NUM_OF_VARIATION = (int)Math.pow(2, Util.WIDTH_OF_BOARD);
	/** 解を求めるのに必要な最小検証回数 */
	private static final int NUM_OF_MINIMUM_EFFORT = (int)Math.pow(2, Util.WIDTH_OF_BOARD - (Util.WIDTH_OF_BOARD - 3));
	// TODO: 最小検証回数はどのように計算すれば求まるのか確信もてず…

	/**
	 * 実行する
	 * @param board 盤の状態
	 */
	public List<List<Boolean>> calclate(List<Boolean> board) {
		return getResults(board);
	}

	/**
	 * 盤の1 行目のパターンから、解答があるかないかを算出する。
	 * 解答ありの場合は、解法のリストを返す。
	 * 
	 * @param board 解答を求めるボードのパターン
	 * @return 解答。解答がない場合はnull を返す
	 */
	public List<List<Boolean>> getResults(List<Boolean> board) {
		
		// TODO: ビット演算のほうがすっきりする
		List<List<Boolean>> results = new ArrayList<List<Boolean>>();
		List<Boolean> patternMap = new ArrayList<Boolean>();			// 盤の1 行目の押下パターン
		int counter = 0;
		
		IntStream.range(0, Util.WIDTH_OF_BOARD).forEach((i) -> patternMap.add(true));	// 一旦最大値(11...1) で初期化
		
		for(int i = 0; i < NUM_OF_VARIATION; ++i) {
			List<Boolean> resultPushedMap = calcResult(
												Util.pushByMap(new ArrayList<Boolean>(board), Util.incPatternMap(patternMap))
												, patternMap);

			if(resultPushedMap != null) {
				// TODO: とりあえず解が1 個以上見つかった時点で終了。
				//       最適解を求める必要があるのであればこれ以降も続ける必要あり
				results.add(resultPushedMap);
				break;
			}
			
			if(counter++ == NUM_OF_MINIMUM_EFFORT) {
				// TODO: 8 回転して解が無いようであれば、これ以上やってもない。
				//       ただし最適解を求める必要がある場合は8 回転以降も続ける必要あり
				break;
			}
		}
		
		return (results.size() == 0? null: results);
	}
	
	/**
	 * 盤の状態から解答を1 件求める。解答がない場合はnull を返す
	 * @param board 盤の状態
	 * @return 解答。どのマスを押せばよいかフラグがたったリスト
	 */
	public List<Boolean> calcResult(List<Boolean> board, List<Boolean> patternMap) {
		// TODO: 引数を複製しない場合、呼び出し元の変数を直接弄ることになるので注意
		// board = new ArrayList<Boolean>(board);

		// 2 行目以降の消去パターンを機械的に検証していく
		ArrayList<Boolean> pushedMap = new ArrayList<Boolean>();
		
		for(int i = Util.WIDTH_OF_BOARD; i < Util.SIZE_OF_BOARD; ++i) {
			if(board.get(i - Util.WIDTH_OF_BOARD)) {
				Util.getExpectedCheckStates(board, i);
				// dumpStatOfBoard(board); // TODO: debug
				pushedMap.add(true);
			} else {
				pushedMap.add(false);
			}
		}
		
		// ライツアウトが解けたかチェック
		if(IntStream.range(0, board.size())
				.filter(i -> board.get(i) == true)
				.findFirst()
				.isPresent()) {
			return null;
		}
		
		// 1 行目と2 行目以降を連結する
		List<Boolean> result = new ArrayList<Boolean>(patternMap);
		result.addAll(pushedMap);

		return result;
	}
}
