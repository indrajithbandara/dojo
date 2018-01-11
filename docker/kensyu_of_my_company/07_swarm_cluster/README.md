# Docker swarm
通常、Docker では、複数のホストにまたがってコンテナが存在する場合、docker コマンドを実行するたびに-H オプションを付加して接続先を切り替える必要が有りました。
結果として、複数のホスト上にコンテナが散財する場合、docker コマンドで透過的にコンテナを管理することが困難でした。

http://qiita.com/TsutomuNakamura/items/6124ab7d32a58bc93ac7

