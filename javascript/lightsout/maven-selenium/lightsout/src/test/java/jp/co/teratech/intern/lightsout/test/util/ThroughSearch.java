package jp.co.teratech.intern.lightsout.test.util;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.stream.IntStream;

public class ThroughSearch {

	/** 解答を検証していくThread プール */
	private PlayerThread[] players;

	public ThroughSearch() throws Exception {
		this(Runtime.getRuntime().availableProcessors());
	}

	public ThroughSearch(int numOfThread) throws Exception {

		if((numOfThread < 1) || !((numOfThread & (numOfThread - 1)) == 0)) {
			throw new Exception("numOfThread passed is not power of 2 (" + numOfThread + ")");
		}

		players = new PlayerThread[numOfThread];
	}

	/**
	 * 解答を求める
	 * @param board 盤の状態
	 */
	public List<Boolean> calculate(List<Boolean> board) {

		PackedBoolean found = new PackedBoolean(false);

		for(int i = 0; i < players.length; ++i) {
			players[i] = new PlayerThread(i, players.length, found, board);
		}

		long start = System.currentTimeMillis();
		for(int i = 0; i < players.length; ++i) {
			players[i].start();
		}

		for(int i = 0; i < players.length; ++i) {
			try {
				// FIXME: for spurious wakeup
				players[i].join();
			} catch (InterruptedException e) {
				e.printStackTrace();
			}
		}

		if(!found.result) {
			System.out.println("The answers could not be found ...[" + (System.currentTimeMillis() - start) + "ms]");
			return null;
		}

		System.out.println("finished[" + (System.currentTimeMillis() - start) + "ms]");
		for(int i = 0; i < players.length; ++i) {
			if(players[i].result != null)
				return players[i].result;
		}

		return null;	// TODO: 到達不能
	}

	/**
	 * ライツアウトのボタンを押すためのスレッド
	 */
	static class PlayerThread extends Thread {
		/** スレッドID。押すべきライトの位置を算出しやすいようにList<Boolean> で持つようにする */
		private long id;
		/** 盤の状態解を求める */
		private List<Boolean> board;
		/** 次に押すべきライトのインデックス */
		private List<Boolean> pushIndex;
		/** pushIndex の長さ */
		private int lenOfPushIndex;
		/** スレッドの数(2進数形式のリスト) */
		private long numOfThread;
		/** スレッド数から算出された下駄上げ値。インクリメント時に処理を簡素化するために利用 */
		private int clog;
		/** 解を発見したかどうかのフラグ */
		protected PackedBoolean bool;
		/** 結果格納リスト */
		protected List<Boolean> result;

		public PlayerThread(int id, int numOfThread, PackedBoolean result, List<Boolean> board) {
			this.id             = (long)id;
			this.board          = new ArrayList<Boolean>(board);
			this.numOfThread    = (long)numOfThread;
			this.pushIndex      = Util.convertToListBoolean(id, Util.SIZE_OF_BOARD);
			this.bool           = result;
			this.lenOfPushIndex = pushIndex.size();

			// FIXME: numOfThread の数が2 のべき乗でないと今のところ正確に動かない(incPushIndexByPowerOfTwo メソッド)
			int tmpClog = numOfThread;
			for(int i = 0; i < 31; ++i) {
				if((tmpClog & 1) == 1) {
					this.clog = i + 1;
					break;
				}
				tmpClog >>= 1;
			}
		}

		public void run() {
			System.out.println("Thread_" + id + " was started.");
			long count = 0;

			// TODO: long では 7 * 7 までしか確認できない。最適解を求めるにはbool.result フラグで辞めてはならない
			long max = (long)Math.pow(2, Util.SIZE_OF_BOARD);
			for(long i = (long)id; !bool.result && i < max; i += numOfThread, ++count) {
				//System.out.println("Thread_" + id + ": " + Util.convertToBitString(pushIndex));
				result = getResults(board, pushIndex);

				if(result != null) {
					System.out.println("Thread_" + id + " found the answer.");
					setFlag(true);
					break;
				}
				incPushIndex();
			}
			System.out.println("Thread_" + id + " was finished(" + count + " count)");
		}

		/**
		 * 発見フラグを設定する
		 */
		public synchronized void setFlag(Boolean found) {
			// TODO: とりあえず解を求めるだけであればsynchronized にする必要も無い...
			this.bool.result = found;
		}

		/**
		 * push index をインクリメントする。
		 */
		public void incPushIndex() {
			pushIndex.set(lenOfPushIndex - clog, !pushIndex.get(lenOfPushIndex - clog));

			// 繰り上がり判定と繰り上がり処理を行う
			if(!pushIndex.get(lenOfPushIndex - clog)) {
				for(int i = 1 + clog; i < lenOfPushIndex; ++i) {
					pushIndex.set(lenOfPushIndex - i, !pushIndex.get(lenOfPushIndex - i));
					if(pushIndex.get(lenOfPushIndex - i)) {
						break;
					}
				}
			}
		}

		/**
		 * 盤の1 行目のパターンから、解答があるかないかを算出する。
		 * 解答ありの場合は、解法のリストを返す。
		 *
		 * @param board 解答を求めるボードのパターン
		 * @return 解答。解答がない場合はnull を返す
		 */
		public List<Boolean> getResults(List<Boolean> board, List<Boolean> pushPattern) {

			// ボタンを押していくパターンを決定する。
			// 盤の末尾の方からインクリメントしていく方式とする。
			//long counter = 0;
			List<Boolean> cloneOfBoard = new ArrayList<Boolean>(board);
			List<Boolean> result = Util.pushByMap(cloneOfBoard, pushPattern);
			return isCleared(result) ? pushPattern: null;
		}

		/**
		 * 結果を確認する。
		 * 1 つでも点灯している箇所があればクリアできていないということ(null を返す)
		 * @param board
		 * @return
		 */
		public boolean isCleared(List<Boolean> board) {
			// 全てがfalse である場合、全て消灯したということ
			if(IntStream.range(0, board.size())
					.filter(i -> board.get(i) == true )
					.findFirst()
					.isPresent()) {
				return false;
			}

			return true;
		}
	}

	static class PackedBoolean {
		protected boolean result;
		public PackedBoolean(boolean result) {
			this.result = result;
		}
	}



	// 5*5 のマスでライトを消していくパターンについて検証していく
	public static void main(String args[]) {
		Boolean[] b = {
				false,  true, false, false, false,
				false, false, false, false, false,
				false, false, false, false, false,
				false, false, false, false, false,
				false, false, false, false, false
		};
		List<Boolean> board = Arrays.asList(b);
		List<Boolean> result = null;

		try {

			ThroughSearch searcher = new ThroughSearch(16);
			result = searcher.calculate(board);
		} catch (Exception e) {
			e.printStackTrace();
		}

		if(result != null) {
			Util.dumpStatOfBoard(result);
		}

	}
}
