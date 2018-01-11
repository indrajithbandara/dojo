$ORIGIN example.com.
$TTL 86400
@	IN	SOA	example.com. root.example.com (
								20170705		; serial number
								1D				; refresh after 1 day
								1H				; retry after 1 hour
								1W				; expire after 1 week
								3H				; minimum TTL of 3 hour
				)
				;; プライマリDNSサーバ
				IN      NS      dns.example.com.
				;; セカンダリDNSサーバ(必要に応じて)
				;; IN      NS      dns2.xxx.co.jp.

				;; プライマリMAILサーバ(必要に応じて)
				;; IN      MX 10   mail1.xxx.co.jp.
				;; セカンダリMAILサーバ(必要に応じて)
				;; IN      MX 20   mail2.xxx.co.jp.

gitlab			IN	A	192.168.1.41
drone			IN	A	192.168.1.42
dns				IN	A	192.168.1.43
