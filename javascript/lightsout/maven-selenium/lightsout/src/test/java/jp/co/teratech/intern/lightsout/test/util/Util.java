package jp.co.teratech.intern.lightsout.test.util;

import java.util.List;
import java.util.ArrayList;
import java.util.stream.IntStream;

import org.openqa.selenium.Alert;
import org.openqa.selenium.WebDriver;
import org.openqa.selenium.support.ui.ExpectedConditions;
import org.openqa.selenium.support.ui.WebDriverWait;

public class Util {
	
	private Util() {}
	
	/** 盤の幅。今のところは5 固定 */
	public static final int WIDTH_OF_BOARD = 5;
	/** 盤のライトの数 */
	public static final int SIZE_OF_BOARD = (int) Math.pow(WIDTH_OF_BOARD, 2);
	
	/**
	 * ゲームが開始されている状態で、ライツアウトのあるボタンを押下した時の盤のあるべき状態を算出する。
	 * @param statesCurrent ボタンを押す前のライツアウトの盤の状態
	 * @param posWillBePushed 押すボタンの位置
	 * @return 算出されたボタンを押した後のライツアウトの盤の状態
	 */
	public static List<Boolean> getExpectedCheckStates(List<Boolean> statesCurrent, int posWillBePushed) {
		return getExpectedCheckStates(statesCurrent, posWillBePushed, true);
	}

	/**
	 * ライツアウトのあるボタンを押下した時の盤のあるべき状態を算出する。
	 * @param statesCurrent ボタンを押す前のライツアウトの盤の状態
	 * @param posWillBePushed 押すボタンの位置
	 * @param hasGameStarted ゲーム開始状態
	 * @return 算出されたボタンを押した後のライツアウトの盤の状態
	 */
	public static List<Boolean> getExpectedCheckStates(
			List<Boolean> statesCurrent, int posWillBePushed, boolean hasGameStarted) {
		
		// List<Boolean> expected = new ArrayList<Boolean>(statesCurrent);
		
		if(hasGameStarted) {
			if(posWillBePushed > (WIDTH_OF_BOARD - 1))
				statesCurrent.set(posWillBePushed - WIDTH_OF_BOARD, !statesCurrent.get(posWillBePushed - WIDTH_OF_BOARD));
			if(posWillBePushed % WIDTH_OF_BOARD != 0)
				statesCurrent.set(posWillBePushed - 1, !statesCurrent.get(posWillBePushed - 1));
			if((posWillBePushed % WIDTH_OF_BOARD) != (WIDTH_OF_BOARD - 1))
				statesCurrent.set(posWillBePushed + 1, !statesCurrent.get(posWillBePushed + 1));
			if(posWillBePushed < Math.pow(WIDTH_OF_BOARD, 2) - WIDTH_OF_BOARD)
				statesCurrent.set(posWillBePushed + WIDTH_OF_BOARD, !statesCurrent.get(posWillBePushed + WIDTH_OF_BOARD));
		}
		statesCurrent.set(posWillBePushed, !statesCurrent.get(posWillBePushed));

		return statesCurrent;
	}

	/**
	 * 盤上のライト全てが等しい状態にあるかを確認する
	 * @param firstParty 甲の盤の状態
	 * @param secondParty 乙の盤の状態
	 * @return 検証結果
	 */
	public static boolean equalityLights(List<Boolean> firstParty, List<Boolean> secondParty) {
		if(firstParty.size() != secondParty.size()) return false;

		return !IntStream.range(0, firstParty.size())
				.filter(i -> !firstParty.get(i).equals(secondParty.get(i)))
				.findFirst()
				.isPresent();
	}
	
	/**
	 * alert ダイアログが存在するかどうか確認する。
	 * @return ダイアログが存在するかどうかの結果
	 */
	public static boolean acceptAlert(WebDriver driver) {
		try {
			Thread.sleep(200);
			WebDriverWait wait = new WebDriverWait(driver, 2);
			wait.until(ExpectedConditions.alertIsPresent());
			Alert alert = driver.switchTo().alert();
			alert.accept();
		} catch(Exception e) {
			return false;
		}
		return true;
	}
	
	/**
	 * パターンマップリストをインクリメントする
	 * @param patternMap インクリメントするパターンマップリスト
	 * @return インクリメント済みパターンマップリスト
	 */
	public static List<Boolean> incPatternMap(List<Boolean> patternMap) {
		patternMap.set(patternMap.size() - 1, !patternMap.get(patternMap.size() - 1));
		
		for(int i = patternMap.size() - 1; i > 0; --i) {	// 最大桁-1 のところまで検証する
			if(!patternMap.get(i)) {
				patternMap.set(i - 1, !patternMap.get(i - 1));
			} else {
				break;
			}
		}
		return patternMap;
	}
	
	/**
	 * 指定された盤を指定されたpattern map で押下していく
	 * @param board 盤
	 * @param map パターン
	 * @return push された後の結果の盤
	 */
	public static List<Boolean> pushByMap(List<Boolean> board, List<Boolean> map) {
		for(int i = 0; i < map.size(); ++i) {
			if(map.get(i)) {
				Util.getExpectedCheckStates(board, i);
			}
		}
		return board;
	}
	
	/**
	 * 盤の状態を出力する
	 * @param board 盤
	 */
	public static void dumpStatOfBoard(List<Boolean> board) {
		for(int i = 0; i < board.size(); ++i) {
			if(i % Util.WIDTH_OF_BOARD == 0)
				System.out.println();

			System.out.print((board.get(i) ? " 1": " 0"));
		}
		System.out.println();
	}

	/**
	 * List<Boolean> な型を2 進数String 形式に変換する。
	 * List<Boolean> はbig endian を想定
	 * @param from 変換対象のList<Boolean>
	 */
	public static String convertToBitString(List<Boolean> from) {
		StringBuilder builder = new StringBuilder();
		int length = from.size();

		for(int i = length - 1; i >= 0; --i) {
			builder.append((from.get(length - 1 - i)? "1": "0"));
			if(i % 8 == 7) builder.append(" ");
		}

		return builder.toString();
	}

	/**
	 * int な型を32 bit 2 進数List<Boolean> な型に変換する。
	 * 変換するときは引数として渡された数値が正の整数であるものとして変換する
	 * @param number 変換対象のint
	 */
	public static List<Boolean> convertToListBoolean(int number, int size) {
		List<Boolean> result = new ArrayList<Boolean>();
		for(int i = 0; i < size; ++i) {
			result.add(0, (i <= 31 && (number & 1) == 1 ? true: false) );
			number >>= 1;
		}

		return result;
	}
}
