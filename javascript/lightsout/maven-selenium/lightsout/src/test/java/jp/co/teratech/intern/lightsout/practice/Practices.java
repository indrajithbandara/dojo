package jp.co.teratech.intern.lightsout.practice;

import static org.junit.Assert.*;

import java.util.Arrays;
import java.util.concurrent.TimeUnit;

import org.junit.Test;
import org.openqa.selenium.By;
import org.openqa.selenium.WebDriver;
import org.openqa.selenium.WebElement;
import org.openqa.selenium.support.ui.Select;

import jp.co.teratech.intern.lightsout.driver.MyDriverCreator;

/**
 * テスト自動化の練習問題。
 * テスト対象となるhtml ページは"/practices/" ディレクトリ配下にあります。
 */
public class Practices {

	/**
	 * button をクリックする練習
	 * @throws Exception 一般例外
	 */
	@Test
	public void ボタンを押すテスト() throws Exception {
		WebDriver driver = MyDriverCreator.create("/practices/00_button.html");
		try {
			driver.manage().timeouts().pageLoadTimeout(10, TimeUnit.SECONDS);
			WebElement button = driver.findElement(By.id("click_button"));
			button.click();
			WebElement result = driver.findElement(By.id("result"));

			assertEquals(result.getText(), "OK");	// 結果の検証
		} finally {
			Thread.sleep(500);
			if(driver != null) driver.quit();
		}
	}

	/**
	 * チェックボックスを押す練習
	 * @throws Exception 一般例外
	 */
	@Test
	public void チェックボックスを押すテスト() throws Exception {
		WebDriver driver = MyDriverCreator.create("/practices/01_checkbox.html");
		try {
			driver.manage().timeouts().pageLoadTimeout(10, TimeUnit.SECONDS);
			WebElement checkbox = driver.findElement(By.id("click_checkbox"));
			checkbox.click();
			assertTrue(checkbox.isSelected());
		} finally {
			Thread.sleep(500);
			if(driver != null) driver.quit();
		}
	}

	/**
	 * 各div 要素のclass 値を取得する練習
	 * @throws Exception 一般例外
	 */
	@Test
	public void クラスを取得するテスト() throws Exception {
		WebDriver driver = MyDriverCreator.create("/practices/02_class.html");
		try {
			driver.manage().timeouts().pageLoadTimeout(10, TimeUnit.SECONDS);
			WebElement firstElement = driver.findElement(By.id("first"));
			String[] results = firstElement.getAttribute("class").split(" ");
			assertNotEquals(Arrays.asList(results).indexOf("bg_radical_red"), -1);
		} finally {
			Thread.sleep(500);
			if(driver != null) driver.quit();
		}
	}

	/**
	 * テキストフィールドにテキストを入れる練習
	 * @throws Exception 一般例外
	 */
	@Test
	public void テキストフィールドに文字を入れるテスト() throws Exception {
		WebDriver driver = MyDriverCreator.create("/practices/03_input_text.html");
		try {
			driver.manage().timeouts().pageLoadTimeout(10, TimeUnit.SECONDS);
			WebElement textField = driver.findElement(By.id("text_field"));
			textField.sendKeys("Hello World.");
			assertEquals(textField.getAttribute("value"), "Hello World.");
		} finally {
			Thread.sleep(500);
			if(driver != null) driver.quit();
		}
	}

	/**
	 * プルダウンから値を選択する練習
	 * @throws Exception 一般例外
	 */
	@Test
	public void プルダウンから値を選択するテスト() throws Exception {
		WebDriver driver = MyDriverCreator.create("/practices/04_pulldown.html");
		try {
			driver.manage().timeouts().pageLoadTimeout(10, TimeUnit.SECONDS);
			WebElement pulldown = driver.findElement(By.id("area"));
			Select selected = new Select(pulldown);
			selected.selectByVisibleText("北海道");

			assertEquals(selected.getFirstSelectedOption().getText(), "北海道");
		} finally {
			Thread.sleep(500);
			if(driver != null) driver.quit();
		}
	}

	/**
	 * ラジオボタンをクリックする練習
	 * @throws Exception 一般例外
	 */
	@Test
	public void ラジオボタンにチェックを入れるテスト() throws Exception {
		WebDriver driver = MyDriverCreator.create("/practices/05_radio.html");
		try {
			driver.manage().timeouts().pageLoadTimeout(10, TimeUnit.SECONDS);

			// id を指定してチェックする方法 ------------------------------------------
			WebElement target = driver.findElement(By.id("radio_on"));
			target.click();
			// ----------------------------------------------------------------------

			// name を指定してチェックする方法 ----------------------------------------
			//List<WebElement> targets = driver.findElements(By.name("radio"));
			//targets.get(0).click();
			// ----------------------------------------------------------------------

			assertTrue(driver.findElement(By.id("radio_on")).isSelected());
		} finally {
			Thread.sleep(500);
			if(driver != null) driver.quit();
		}
	}

	/**
	 * セレクトリストを選択する練習
	 * @throws Exception
	 */
	@Test
	public void セレクトリストを選択するテスト() throws Exception {
		WebDriver driver = MyDriverCreator.create("/practices/06_selectbox.html");
		try {
			driver.manage().timeouts().pageLoadTimeout(10, TimeUnit.SECONDS);

			WebElement selectList = driver.findElement(By.name("courses"));
			Select selectedSelectList = new Select(selectList);

			// 梅コースを探し、あったらそれをクリックする
			selectedSelectList
					.getOptions()
					.stream()
					.filter(e -> e.getText().equals("梅コース"))
					.findFirst()
					.get()
					.click();

			assertEquals(selectedSelectList.getFirstSelectedOption().getText(), "梅コース");
		} finally {
			Thread.sleep(500);
			if(driver != null) driver.quit();
		}
	}
}
