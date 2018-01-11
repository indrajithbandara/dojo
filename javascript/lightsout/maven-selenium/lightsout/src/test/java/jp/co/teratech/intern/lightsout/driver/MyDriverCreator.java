package jp.co.teratech.intern.lightsout.driver;

import java.io.File;
import java.io.IOException;

import org.openqa.selenium.WebDriver;
import org.openqa.selenium.chrome.ChromeDriver;

/**
 * ドライバクラス
 */
public class MyDriverCreator {

	static {
		try {
			System.setProperty(
				"webdriver.chrome.driver"
				, new File(".").getCanonicalFile() + "/driver/chromedriver"
							+ (System.getProperty("os.name").startsWith("Windows") ? ".exe": "")
			);
		} catch (IOException e) {
			e.printStackTrace();
			System.exit(1);
		}
	}

	/**
	 * デフォルトのWeb ドライバを作成する
	 * @return Web ドライバ
	 */
	public static WebDriver create() {
		return MyDriverCreator.create("/html/lightsout.html");
	}

	/**
	 * 指定したLocation で、デフォルトのWeb ドライバを作成する
	 * @param htmlLocation Location
	 * @return Web ドライバ
	 */
	public static WebDriver create(String htmlLocation) {
		String url = "file://"
				+ new File(new File(".").getAbsolutePath()).getParent()
				+ htmlLocation;

		// TODO: 今回はChrome だけ試験できれば良い
		WebDriver driver = new ChromeDriver();
		driver.get(url);

		return driver;
	}
}
