package jp.co.teratech.intern.lightsout.test.util;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

public class SimultaneousEquation {

	public static void main(String args[]) {
		// TODO: 動確
		long start = System.currentTimeMillis();

		Boolean[] b = {
			false,  true, false,  true, false,
			false, false, false, false, false,
			false, false, false, false, false,
			false, false, false, false, false,
			false, false, false, false, false,
		};

//		Boolean[] b = {
//			 true, false, false, false, false,
//			false, false, false, false, false,
//			false, false, false, false, false,
//			false, false, false, false, false,
//			false, false, false, false,  true,
//		};

		List<Boolean> board = Arrays.asList(b);
		SimultaneousEquation sim = new SimultaneousEquation();
		sim.init();                                     // 連立方程式を作成する
		List<Boolean> answer = sim.calculate(board);
		Util.dumpStatOfBoard(answer);
		System.out.println("Time: " + (System.currentTimeMillis() - start) + "ms");
	}

	/** 連立方程式 */
	Expressions simultaneous;

	/**
	 * 連立方程式を構築する
	 */
	public void init() {
		simultaneous = new Expressions();

		// 各ボタンに影響するボタンの式一覧を作成する
		for(int i = 0; i < Util.SIZE_OF_BOARD; ++i) {
			simultaneous.add(new Expression(i));
		}
		simultaneous.debugExpressions();
		simultaneous.formatExpressions();
	}

	/**
	 * 連立方程式から解を求める。解がない場合はnull を返す
	 * @param board 盤の状態
	 * @return 解。どのライトを押せばよいかマーキングされたBoolean リスト
	 */
	public List<Boolean> calculate(List<Boolean> board) {

		// 解があるかどうかを確認する
		for(int index: simultaneous.validationPoints) {
			Expression expression = simultaneous.expressions.get(index);
			boolean notExistence = false;

			for(int i = 0; i < expression.rightMember.size(); ++i) {
				if(expression.rightMember.get(i)) {
					notExistence = (notExistence != board.get(i));
				}
			}

			// ゼロな状態(false) であるかをチェックする。非zeroな状態(true) である場合は解無し
			if(notExistence) {
				return null;
			}
		}

		// 解ありと判定された場合は解を求める
		List<Boolean> result = getPlainBooleanList();
		for(int i : simultaneous.availablePoints) {
			if(board.get(i)) {  // TODO: 有効な式のみを格納したインデックスリストのようなものを作っておけば綺麗かも

				Expression expression = simultaneous.expressions.get(i);

				for(int j = 0; j < expression.rightMember.size(); ++j) {
					result.set(j, (result.get(j) != expression.rightMember.get(j)));
				}
			}
		}

		return result;
	}

	/**
	 * 初期化された盤(Boolean リスト) を取得する。
	 * @return 初期化された盤
	 */
	public static List<Boolean> getPlainBooleanList() {
		return SimultaneousEquation.getPlainBooleanList(false);
	}

	/**
	 * 引数で初期化された盤(Boolean リスト) を取得する。
	 * @param initializer 初期化値
	 * @return 初期化された盤
	 */
	public static List<Boolean> getPlainBooleanList(boolean initializer) {
		Boolean[] b = new Boolean[Util.SIZE_OF_BOARD];
		Arrays.fill(b, initializer);

		return Arrays.asList(b);
	}

	/**
	 * 連立方程式の式一覧
	 */
	static class Expressions {
		// TODO: 記述が面倒なのでprivate によるカプセル化は無しで...

		/** 連立方程式格納リスト */
		protected List<Expression> expressions = new ArrayList<Expression>();
		/** 無効な(有効とはいえない)式を持つマス目リスト。正解を求める事はできないが、解ありor無しを検証できるマス目 */
		protected List<Integer> validationPoints = new ArrayList<Integer>();
		/** 有効な式を持つマス目リスト */
		protected List<Integer> availablePoints  = new ArrayList<Integer>();

		/** 式を連立していく */
		public void add(Expression express) {
			expressions.add(express);
		}

		/**
		 * 各ボタン毎に正規化された連立方程式を作成する
		 */
		public void formatExpressions() {

			for(int i = 0; i < expressions.size(); ++i) {
				List<Expression> effected = getEffectedExpressionFromLeft(i);

				if(effected == null) {
					validationPoints.add(i);
					continue;
				};

				availablePoints.add(i);
				calcSystemOfEquations(effected, i);
			}

			// TODO: 完成した連立方程式をdebug 出力
			System.out.println("------------------------------------------------------");
			this.debugExpressions();
		}

		/**
		 * 連立方程式の解を解く
		 * @param expressions 連立方程式
		 * @return
		 */
		public void calcSystemOfEquations(List<Expression> effectedExpressions, int pivotIndex) {
			Expression pivot = expressions.get(pivotIndex);

			for(Expression effectedExpression : effectedExpressions) {
				// pivotIndex のExpression とeffectedExpression の排他論理和を求める。
				// 計算後の式は、effectedExpression 参照先に直接入れ込む
				for(int i = 0; i < effectedExpression.leftMember.size(); ++i) {
					effectedExpression.leftMember.set(i, effectedExpression.leftMember.get(i) != pivot.leftMember.get(i));
					effectedExpression.rightMember.set(i, effectedExpression.rightMember.get(i) != pivot.rightMember.get(i));
				}
			}
		}

		/**
		 * 必要に応じて式をswap する。
		 * 連立方程式のindex (引数)行目が、消去対象となる(index 番目の)ライトを未知数としていない場合
		 * 他の行にある消去対象となる(index 番目の)ライトを未知数としている式を
		 * index 行目の式と交換する。
		 * @param index 連立方程式の行数及び消去対象のライト
		 */
		public void swapExpressionsIfNessesally(int index) {
			if(expressions.get(index).leftMember.get(index) == false) {
				// 指定したインデックスと、ボタンのインデックスが異なる場合は、swap する。
				// 例) 2番目のExpression なのに、2番目のライトがtrue になっていない。
				//       -> 2番目のExpression と2番目以降のExpression で2番目のライトがtrue になっているExpression とswap する

				for(int i = index + 1; i < expressions.size(); ++i) {
					if(expressions.get(i).leftMember.get(index) == true) {
						Expression tmp = expressions.get(index);
						expressions.set(index, expressions.get(i));
						expressions.set(i, tmp);
						break;
					}
				}
			}
		}

		/**
		 * 連立方程式の解を求めるため、指定したライトの位置に影響のある式を返す。
		 * 影響のあり/なしは式の左辺から判断する。
		 * @param position ライトの位置
		 * @return 影響のある式のリスト
		 */
		public List<Expression> getEffectedExpressionFromLeft(int position) {

			// TODO: debug. swap 前に結果を出力してみる
			System.out.println("- dump the expression which might be swapped -");
			this.debugExpressions(position);

			swapExpressionsIfNessesally(position);

			// TODO: debug. 計算前に結果を出力してみる
			System.out.println("- dump the expression which has swapped -");
			this.debugExpressions(position);

			if(!expressions.get(position).leftMember.get(position)) {
				// 式がpivot として使えない(式の左辺に消去対象のライトが未知数になっていない)のであれば、
				// 連立方程式が成り立たない(連立方程式の未知数部分が無い==左辺が0)となるので
				// その式の計算は成り立たない。
				return null;
			}

			List<Expression> results = new ArrayList<Expression>();

			for(int i = 0; i < expressions.size(); ++i) {
				if(i == position) continue;

				if(expressions.get(i).leftMember.get(position)) {
					results.add(expressions.get(i));
				}
			}

			return (results.size() == 0 ? null: results);
		}

		/**
		 * 連立方程式の内容をデバッグ出力する
		 */
		public void debugExpressions() {
			debugExpressions(-1);
		}

		/**
		 * 連立方程式の内容をデバッグ出力する
		 * @param position マーカーを付けるポジション
		 */
		public void debugExpressions(int position) {
			Expression expression;
			for(int i = 0; i < expressions.size(); ++i) {

				System.out.print((i == position? "* ": "  "));
				System.out.printf("%04d:", i);

				expression = expressions.get(i);
				for(int j = 0; j < expression.leftMember.size(); ++j) {
					if(j % Util.WIDTH_OF_BOARD == 0) System.out.print(" ");
					System.out.print((expression.leftMember.get(j) ? "1": "0"));
				}
				System.out.print(" | ");
				for(int j = 0; j < expression.rightMember.size(); ++j) {
					if(j % Util.WIDTH_OF_BOARD == 0) System.out.print(" ");
					System.out.print((expression.rightMember.get(j) ? "1": "0"));
				}
				System.out.println();
			}
		}
	}

	/**
	 * 1 つの式
	 */
	static class Expression {
		// TODO: 記述が面倒なのでprivate によるカプセル化は無しで...

		/** 式のインデックス。何番目のボタンを解くために使う式か判別するためのインデックス */
		protected int index = -1;
		/** 連立方程式の左辺 */
		protected List<Boolean> leftMember = new ArrayList<Boolean>();
		/** 連立方程式の右辺 */
		protected List<Boolean> rightMember = new ArrayList<Boolean>();

		public Expression() {
			this(-1);
		}

		public Expression(int index) {
			this.index = index;
			for(int i = 0; i < Util.SIZE_OF_BOARD; ++i) {
				leftMember.add(false);
				rightMember.add(false);
			}

			if(index >= 0) {
				Util.getExpectedCheckStates(leftMember, index);
				rightMember.set(index, true);
			}
		}
	}

}
