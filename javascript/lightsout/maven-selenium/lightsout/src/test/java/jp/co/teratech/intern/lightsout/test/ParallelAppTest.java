package jp.co.teratech.intern.lightsout.test;

import static org.junit.Assert.*;

import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.TimeUnit;
import java.util.stream.IntStream;

import org.junit.After;
import org.junit.AfterClass;
import org.junit.Before;
import org.junit.BeforeClass;
import org.junit.Test;
import org.openqa.selenium.By;
import org.openqa.selenium.WebDriver;
import org.openqa.selenium.WebElement;

import jp.co.teratech.intern.lightsout.driver.MyDriverCreator;
import jp.co.teratech.intern.lightsout.test.util.P32;
import jp.co.teratech.intern.lightsout.test.util.SimultaneousEquation;
import jp.co.teratech.intern.lightsout.test.util.ThroughSearch;
import jp.co.teratech.intern.lightsout.test.util.Util;

/**
 * Unit test for simple App.
 */
public class ParallelAppTest {

//	@Test
//	public void runAllTest() {
//		Class<?>[] cls = {ParallelTest.class};
//		JUnitCore.runClasses(new ParallelComputer(true, true), cls);
//	}

	public static class ParallelTest {
		/** Web ドライバ */
		private WebDriver driver;

		private List<WebElement> lightsOriginal;
		private WebElement startButton;
		private WebElement shuffleButton;

		// メソッド名は英語でも日本語でもOK。JUnit の結果が試験項目書ともなりうるので、それを考えると日本語が無難
		@Test
		public void ゲーム開始後ボタンを押した時に自身と上と左と右と下に位置するボタンの状態が反転することのテスト() {
			int pushPosition		= 12;  	// 押すチェックボックスの位置。盤の中央
			List<Boolean> expected	= Util.getExpectedCheckStates(getCurrentCheckStates(), pushPosition);
			startButton.click();
			lightsOriginal.get(pushPosition).click();
			assertTrue(Util.equalityLights(getCurrentCheckStates(), expected));
		}

		/**
		 * □□■□□ -> □□■□□
		 * □□■□□ -> □□■□■
		 * ■■□■■ -> ■■□□□
		 * □□■□□ -> □□■□■
		 * □□■□□ -> □□■□□
		 */
		@Test
		public void ゲーム開始後右隅のボタンを押した時に自身と上と左と下に位置するボタンの状態が反転することのテスト() {
			int pushPosition		= 14;
			List<Boolean> expected	= Util.getExpectedCheckStates(getCurrentCheckStates(), pushPosition);
			startButton.click();
			lightsOriginal.get(pushPosition).click();
			assertTrue(Util.equalityLights(getCurrentCheckStates(), expected));
		}

		/**
		 * □□■□□ -> □□■□□
		 * □□■□□ -> ■□■□□
		 * ■■□■■ -> □□□■■
		 * □□■□□ -> ■□■□□
		 * □□■□□ -> □□■□□
		 */
		@Test
		public void ゲーム開始後左隅のボタンを押した時に自身と上と右と下に位置するボタンの状態が反転することのテスト() {
			int pushPosition		= 10;
			List<Boolean> expected	= Util.getExpectedCheckStates(getCurrentCheckStates(), pushPosition);
			startButton.click();
			lightsOriginal.get(pushPosition).click();
			assertTrue(Util.equalityLights(getCurrentCheckStates(), expected));
		}

		/**
		 * □□■□□ -> □■□■□
		 * □□■□□ -> □□□□□
		 * ■■□■■ -> ■■□■■
		 * □□■□□ -> □□■□□
		 * □□■□□ -> □□■□□
		 */
		@Test
		public void ゲーム開始後上隅のボタンを押した時に自身と左と右と下に位置するボタンの状態が反転することのテスト() {
			int pushPosition		= 2;
			List<Boolean> expected	= Util.getExpectedCheckStates(getCurrentCheckStates(), pushPosition);
			startButton.click();
			lightsOriginal.get(pushPosition).click();
			assertTrue(Util.equalityLights(getCurrentCheckStates(), expected));
		}

		/**
		 * □□■□□ -> □□■□□
		 * □□■□□ -> □□■□□
		 * ■■□■■ -> ■■□■■
		 * □□■□□ -> □□□□□
		 * □□■□□ -> □■□■□
		 */
		@Test
		public void ゲーム開始後下隅のボタンを押した時に自身と上と左と右に位置するボタンの状態が反転することのテスト() {
			int pushPosition		= 22;
			List<Boolean> expected	= Util.getExpectedCheckStates(getCurrentCheckStates(), pushPosition);
			startButton.click();
			lightsOriginal.get(pushPosition).click();
			assertTrue(Util.equalityLights(getCurrentCheckStates(), expected));
		}

		/**
		 * □□■□□ -> ■■■□□
		 * □□■□□ -> ■□■□□
		 * ■■□■■ -> ■■□■■
		 * □□■□□ -> □□■□□
		 * □□■□□ -> □□■□□
		 */
		@Test
		public void ゲーム開始後左上隅のボタンを押した時に自身と右と下に位置するボタンの状態が反転することのテスト() {
			int pushPosition		= 0;
			List<Boolean> expected	= Util.getExpectedCheckStates(getCurrentCheckStates(), pushPosition);
			startButton.click();
			lightsOriginal.get(pushPosition).click();
			assertTrue(Util.equalityLights(getCurrentCheckStates(), expected));
		}

		/**
		 * □□■□□ -> □□■■■
		 * □□■□□ -> □□■□■
		 * ■■□■■ -> ■■□■■
		 * □□■□□ -> □□■□□
		 * □□■□□ -> □□■□□
		 */
		@Test
		public void ゲーム開始後右上隅のボタンを押した時に自身と左と下に位置するボタンの状態が反転することのテスト() {
			int pushPosition		= 4;
			List<Boolean> expected	= Util.getExpectedCheckStates(getCurrentCheckStates(), pushPosition);
			startButton.click();
			lightsOriginal.get(pushPosition).click();
			assertTrue(Util.equalityLights(getCurrentCheckStates(), expected));
		}

		/**
		 * □□■□□ -> □□■□□
		 * □□■□□ -> □□■□□
		 * ■■□■■ -> ■■□■■
		 * □□■□□ -> ■□■□□
		 * □□■□□ -> ■■■□□
		 */
		@Test
		public void ゲーム開始後左下隅のボタンを押した時に自身と上と右に位置するボタンの状態が反転することのテスト() {
			int pushPosition		= 20;
			List<Boolean> expected	= Util.getExpectedCheckStates(getCurrentCheckStates(), pushPosition);
			startButton.click();
			lightsOriginal.get(pushPosition).click();
			assertTrue(Util.equalityLights(getCurrentCheckStates(), expected));
		}

		/**
		 * □□■□□ -> □□■□□
		 * □□■□□ -> □□■□□
		 * ■■□■■ -> ■■□■■
		 * □□■□□ -> □□■□■
		 * □□■□□ -> □□■■■
		 */
		@Test
		public void ゲーム開始後右下隅のボタンを押した時に自身と上と左に位置するボタンの状態が反転することのテスト() {
			int pushPosition		= 24;
			List<Boolean> expected	= Util.getExpectedCheckStates(getCurrentCheckStates(), pushPosition);
			startButton.click();
			lightsOriginal.get(pushPosition).click();
			assertTrue(Util.equalityLights(getCurrentCheckStates(), expected));
		}

		/**
		 * □□■□□ -> □□■□□
		 * □□■□□ -> □■■□□
		 * ■■□■■ -> ■■□■■
		 * □□■□□ -> □□■□□
		 * □□■□□ -> □□■□□
		 */
		@Test
		public void ゲーム開始前にボタンを押した時に自身のみボタンの状態が反転することのテスト() {
			int pushPosition		= 6;
			List<Boolean> expected	= Util.getExpectedCheckStates(getCurrentCheckStates(), pushPosition, false);
			lightsOriginal.get(pushPosition).click();
			assertTrue(Util.equalityLights(getCurrentCheckStates(), expected));
		}

		/**
		 * □□■□□ -> □□□□□ -> □□□□□ -> □□□□□ -> □□□□□
		 * □□■□□ -> □■□■□ -> □□□■□ -> □□□□□ -> □□□□□
		 * ■■□■■ -> ■■■■■ -> □□□■■ -> □□■□□ -> □□□□□
		 * □□■□□ -> □□■□□ -> □■■□□ -> □■■■□ -> □□□□□
		 * □□■□□ -> □□■□□ -> □□■□□ -> □□■□□ -> □□□□□
		 */
		@Test
		public void ゲームをクリアしたらアラートダイアログが出現すること() {
			List<Boolean> expected	= Util.getExpectedCheckStates(getCurrentCheckStates(), 7);
			expected	= Util.getExpectedCheckStates(expected, 11);
			expected	= Util.getExpectedCheckStates(expected, 13);
			expected	= Util.getExpectedCheckStates(expected, 17);

			startButton.click();
			lightsOriginal.get(7).click();
			lightsOriginal.get(11).click();
			lightsOriginal.get(13).click();
			lightsOriginal.get(17).click();

			assertTrue(Util.acceptAlert(driver));
			assertTrue(Util.equalityLights(getCurrentCheckStates(), expected));
		}

		@Test
		public void シャッフルボタンを押下したら盤の状態が変わること() {
			List<Boolean> before = getCurrentCheckStates();
			shuffleButton.click();
			List<Boolean> after = getCurrentCheckStates();
			assertFalse(Util.equalityLights(before, after));
		}

		/**
		 * □□■□□ -> □□■□□ -> □□■□□
		 * □□■□□ -> □□□□□ -> □□□□□
		 * ■■□■■ -> ■□■□■ -> ■□□□■
		 * □□■□□ -> □□□□□ -> □□□□□
		 * □□■□□ -> □□■□□ -> □□■□□
		 */
		@Test
		public void スタートボタンを押した後にもう一度それを押すとゲームモードから抜けること() {
			List<Boolean> before = getCurrentCheckStates();

			List<Boolean> expectedStatsInGame = Util.getExpectedCheckStates(before, 12);
			startButton.click();
			lightsOriginal.get(12).click();
			List<Boolean> statsInGame = getCurrentCheckStates();
			assertTrue(Util.equalityLights(statsInGame, expectedStatsInGame));

			List<Boolean> expectedStatsOutGame = Util.getExpectedCheckStates(expectedStatsInGame, 12, false);
			startButton.click();
			lightsOriginal.get(12).click();
			List<Boolean> statsOutGame = getCurrentCheckStates();
			assertTrue(Util.equalityLights(statsOutGame, expectedStatsOutGame));
		}

		@Test
		public void おまけ_非ゲームモードでライトをすべて消灯してもゲームクリアとはならいこと且つスタートボタン押してもゲーム開始できないこと() throws Exception {
			List<Boolean> expected	= new ArrayList<Boolean>();
			IntStream.range(0, Util.SIZE_OF_BOARD).forEach(i -> expected.add(false));

			lightsOriginal.get(2).click();
			lightsOriginal.get(7).click();
			lightsOriginal.get(10).click();
			lightsOriginal.get(11).click();
			lightsOriginal.get(13).click();
			lightsOriginal.get(14).click();
			lightsOriginal.get(17).click();
			lightsOriginal.get(22).click();

			assertFalse(Util.acceptAlert(driver));									// ゲームクリアのダイアログが出ていないこと
			assertTrue(Util.equalityLights(getCurrentCheckStates(), expected));		// ライトがすべて消灯している状態

			startButton.click();
			String labelOfStart = startButton.getText();
			assertEquals(labelOfStart, "Start");									// スタートボタンのラベルが"Start" のままであること
		}

		@Test
		public void おまけ_総当り法で解を求めてみる() throws Exception {
			ThroughSearch search = new ThroughSearch(4);
			List<Boolean> answer = search.calculate(getCurrentCheckStates());

			startButton.click();
			IntStream.range(0, lightsOriginal.size())
					.forEach(i -> {
						if(answer.get(i)) {
							lightsOriginal.get(i).click();
						}
					});
			Thread.sleep(500);
		}

		@Test
		public void おまけ_総当り法且つマルチスレッドで解を求めてみる() throws Exception {
			ThroughSearch search = new ThroughSearch(4);
			List<Boolean> answer = search.calculate(getCurrentCheckStates());

			startButton.click();
			IntStream.range(0, lightsOriginal.size())
					.forEach(i -> {
						if(answer.get(i)) {
							lightsOriginal.get(i).click();
						}
					});
			Thread.sleep(500);
		}

		@Test
		public void おまけ_総当り法且つマルチスレッドで解なしの判定をする() throws Exception {

			lightsOriginal.get(2).click();		// 解なしの状態を作成する

			ThroughSearch search = new ThroughSearch(4);
			List<Boolean> answer = search.calculate(getCurrentCheckStates());

			assertNull(answer);
			Thread.sleep(500);
		}

		@Test
		public void おまけ_32通り中8通り解法で解ありの状態までシャッフルしてクリアする() throws Exception {
			P32 p32 = new P32();

			List<List<Boolean>> answers = null;
			while(answers == null) {
				shuffleButton.click();
				answers = p32.calclate(getCurrentCheckStates());
			}

			// 解答の候補から1 つを適当に選んで解答する(最小手数とは限らない)
			List<Boolean> answer = answers.get(0);
			startButton.click();
			IntStream.range(0, lightsOriginal.size())
					.forEach(i -> {
						if(answer.get(i)) {
							lightsOriginal.get(i).click();
						}
					});

			// クリア
			Thread.sleep(500);
		}

		@Test
		public void おまけ_32通り中8通り解法で解無しを判定する() throws Exception {
			lightsOriginal.get(2).click();		// 解なしの状態を作成する

			P32 p32 = new P32();

			List<List<Boolean>> answers = p32.calclate(getCurrentCheckStates());
			assertNull(answers);
			Thread.sleep(500);
		}


		@Test
		public void おまけ_連立方程式による解法で解ありの状態までシャッフルしてクリアする() throws Exception {
			SimultaneousEquation simultaneous = new SimultaneousEquation();
			simultaneous.init();
			simultaneous.calculate(getCurrentCheckStates());

			List<Boolean> answer = null;

			while(answer == null) {
				shuffleButton.click();
				answer = simultaneous.calculate(getCurrentCheckStates());
			}

			startButton.click();

			for(int i = 0; i < answer.size(); ++i) {
				if(answer.get(i)) lightsOriginal.get(i).click();
			}

			// クリア
			Thread.sleep(500);
		}

		@Test
		public void おまけ_連立方程式による解法で解無しを判定する() throws Exception {
			lightsOriginal.get(2).click();		// 解なしの状態を作成する

			SimultaneousEquation simultaneous = new SimultaneousEquation();
			simultaneous.init();
			List<Boolean> answer = simultaneous.calculate(getCurrentCheckStates());

			assertNull(answer);
			Thread.sleep(500);

		}

		/**
		 * 現在のライツアウトの盤の状態を取得する
		 * @return 現在の盤の状態
		 */
		public List<Boolean> getCurrentCheckStates() {
			return getStates(lightsOriginal);
		}

		/**
		 * ライツアウトのチェック状態を取得する
		 * @param elements ライツアウトチェックボックスWebElement のList
		 * @return チェック状態リスト
		 */
		public List<Boolean> getStates(List<WebElement> elements) {
			List<Boolean> result = new ArrayList<Boolean>();
			elements.stream().map(e -> e.isSelected()).forEach(e -> result.add(e));

			return result;
		}

		@Before
		public void setUp() {
			driver = MyDriverCreator.create();
			driver.manage().timeouts().pageLoadTimeout(10, TimeUnit.SECONDS);
			lightsOriginal	= driver.findElements(By.className("light"));
			startButton		= driver.findElement(By.id("toggle"));
			shuffleButton	= driver.findElement(By.id("shuffle"));

//				try {
//					Thread.sleep(200);
//				} catch (InterruptedException e) { e.printStackTrace(); }
		}

		@After
		public void tearDown() {
//				try {
//					Thread.sleep(200);
//				} catch (InterruptedException e) { e.printStackTrace(); }

			if(driver != null) driver.quit();
		}

		@BeforeClass
		public static void beforeClass() {}

		@AfterClass
		public static void afterClass() {}
	}
}
