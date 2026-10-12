# MimicX Workspace — Claude rules

このディレクトリは Mimic X プロジェクトの **ワークスペース** であり、配下に独立した
git リポジトリを 4 つ保持する構成になっている (`.gitignore` で除外、submodule では
ない)。Claude は通常このディレクトリ (`/Users/ohnaka/work/github/MimicX/`) を CWD
として起動される想定。

## 配下リポジトリ

| ディレクトリ | リモート | 内容 |
|---|---|---|
| `MimicX-firmware/` | `kunichiko/MimicX-firmware` | CH32X035 ファームウェア (C, PlatformIO, ch32v003fun) |
| `MimicX-protocol/` | `kunichiko/MimicX-protocol` | USB-MIDI プロトコル仕様 (docs のみ、コードなし) |
| `MimicX-app/`      | `kunichiko/MimicX-app`      | Flutter アプリ (USB-MIDI ホスト) |
| `MimicX-hardware/` | `kunichiko/MimicX-hardware` | ハードウェア設計 (KiCad / atopile, 参照のみ) |

## ブランチ運用 (全リポジトリ共通)

- **main 一本運用**。常設 develop ブランチは持たない
- リスキーな変更だけ都度 feature ブランチを切る (恒久的な分岐は作らない)
- リリースは main に注釈付きタグ (`vX.Y.Z`) を push して実施
  - firmware: タグ push で GitHub Actions が 3 env マトリックスビルド → GH Release 作成
    → `docs/firmware/firmwares/` に bins を auto-commit
  - app: タグ push で GitHub Actions が iOS / Android ビルド
  - protocol: タグ push のみ (CI なし)
- 外部メンテナーは fork → PR で対応する想定 (upstream に develop は不要)

## クロスリポジトリ開発のヒント

- `git -C MimicX-firmware status` のように `-C` フラグで sub-repo の git 操作を直接行う
- ファイル参照は `MimicX-firmware/src/main.c` のように workspace 起点の相対パスでよい
- 同時編集が多い変更 (例: protocol の SysEx 追加 → firmware ハンドラ → app クライアント)
  は 3 リポをまたいで commit する。リリース順は通常 **protocol → firmware → app**
  (互換性の依存関係に従う)
- 各リポジトリにも個別の `README.md` がある。プロジェクト全体像はそちらと併せて参照

## MimicX-app の変更時に必要なクロスプラットフォーム再確認

app は **Android / iOS / macOS / Windows** の 4 プラットフォームで動く。Dart コードだけ
書いていても、間接的に呼ぶプラグインの実装差で 1 つの OS だけ壊れることが何度かあった
(直近では v1.3.1 で Android だけ MIDI 送信が死ぬ regression を出している)。**実機 4 台で
毎回確認するのは大変なので、Claude は MimicX-app に変更を入れる際、最後に「どの環境で
ユーザが再確認すべきか」を明示すること。**

### 影響判定の目安

| 変更内容 | 再確認が必要な環境 |
|---|---|
| `lib/l10n/` のみ (文言追加・修正) | 言語切り替えチェック程度。OS は 1 台で十分 |
| Pure Dart の純粋な UI / ロジック (`build()` 内のレイアウト、State 計算など) | iOS / Android のどちらか 1 台で十分 (キーボード入力やウィンドウサイズ依存があれば macOS / Windows も) |
| `flutter_midi_command` の呼び出し方変更、`MidiService` / `protocol.dart` / SysEx 周り | **4 環境すべて** |
| `pubspec.yaml` のプラグイン ref / バージョン変更 | **4 環境すべて** (該当プラグインが native を持つ場合) |
| Flutter SDK バージョンアップ | **4 環境すべて** + CI ビルド成功確認 |
| `.../ios/` `.../macos/` `.../android/` `.../windows/` 配下の直接編集 | 当該 OS + 同系統 (例: iOS 触ったら macOS も) |
| `windows_ime.dart` や IME 周り | **Windows + Android** (ライン入力モード) |
| プロトコル仕様変更 (protocol minor up や SysEx 追加) | **4 環境すべて** + firmware バージョン整合性確認 |

### 出力フォーマット

実装完了の最終応答に、必要なときだけ次の節を含める:

```
## 再確認をお願いします
- [ ] Android: <具体的に何を確認してほしいか>
- [ ] iOS: ...
- [ ] macOS: ...
- [ ] Windows: ...
```

「Pure Dart UI のみ」のように影響が局所的だと判断した場合は、その判断理由を 1 行添えて
チェックリストを省略してよい。**判断に迷ったら 4 環境すべて挙げる方を選ぶ** (見逃しの
コストの方が高い)。

## ファームウェア書き込み

```sh
# atari-joystick 基板の BOOT ボタンを押しながら USB を挿してから:
MimicX-firmware/tools/wchisp_flash.sh joystick
```

DFU 検出までリトライするので操作タイミングに余裕がある。wchisp 実体は
`~/.platformio/packages/tool-wchisp/wchisp` (PlatformIO 同梱、PATH には入っていない)。
書き込み完了後は USB を一度挿し直さないとデバイスが再認識されない。

## バージョン整合性 (現時点 = 2026-10-12)

- protocol: **0.11.0** (v0.11.0 タグ済み。BRIDGE_LINK_INFO 0x0D→0x0E §6.4.7 を追加 —
  ブリッジ (ESP32) が BLE リンクで実際に合意された connection interval / latency /
  supervision timeout / MTU / PHY / RSSI と、要求値・接続直後の値・更新成否を自答する
  診断用コマンド。CH32 の実装は不要 (未対応構成は UNKNOWN_COMMAND)。
  0.10.0 = BRIDGE_REBOOT_BOOTLOADER 0x0C
  §6.4.6 を追加 — ブリッジ (ESP32) を ROM ダウンロードモードで再起動させる開発者向け
  コマンド。マジック "BOT" 必須。ブリッジ自答なので CH32 の実装は不要。無印 ESP32 は非対応。
  CH32 が申告する protocol_version の 0.10 追従は、knownLatest=0.10 のアプリ (v1.8.0〜)
  が行き渡ってから firmware で行う。
  0.9.0 = TOWNS パッド RUN/SELECT = note 21/22 + SOCD ガード、v0.9.0 タグ済み)
- firmware: **v1.3.0** (protocol 0.9 申告のまま。タグ済み。ESP32 ブリッジが
  BRIDGE_LINK_INFO を BLE / USB 両経路で自答 (`platforms/esp32/main/main.c`)。
  iPhone で BLE の入力遅延が報告されたことへの診断用。CH32 は版数のみ更新。
  v1.2.1 = **FM TOWNS での MSX マウス
  モード修正** = (1) STROBE 立ち上がり直後に DMA が D0-D3 を複数本同時に LOW へ落とすと
  STROBE 入力に回り込んで偽エッジになり、DMA ポインタがずれて Y に X が読まれていた
  (右移動が斜め右下になる)。MSX マウスモード時のみ TIM2 入力キャプチャにデジタル
  フィルタ (約 2.7us) を追加。(2) TOWNS は 1 サイクル 4 nibble (2 falling) のため
  3ms アイドルで累積を 0 クリアしており、読み取り直後の CC を取りこぼしていた。
  報告済み分だけ差し引いて残りを持ち越す方式に変更。`-D MSX_DIAG` ビルドで STROBE
  エッジ列を記録して SysEx (0x7D 0x44) でダンプする診断機能あり (CC 0x7F で記録開始)。
  v1.2.0 = USB VID/PID を pid.codes の
  正式値に切り替え = CH32 `0x1209:0x9210` (Mimic X) / ESP32-S3 ブリッジ `0x1209:0x9211`
  (Mimic X Bridge)。BRIDGE_REBOOT_BOOTLOADER の自答を含む (無印 ESP32 は該当レジスタが
  無いため UNKNOWN_COMMAND で非対応)。**protocol_version を 0.10 に上げていない**のは、
  上げると knownLatest=0.9 の現行アプリ全版で接続ごとに「新しいプロトコル」警告が出るため。
  0.10 追従は knownLatest=0.10 の app v1.8.0 が行き渡ってから。Web フラッシャーは v1.2.0 未満の bin を
  削除済みで、`docs/firmware/{index,esp32}.html` の `MIN_VERSION` で一覧から除外している)
- app: **v1.9.0** (1.9.0+34、v1.9.0 タグ済み。**通信診断画面** (`lib/link_diagnostics_page.dart`)
  を追加 = デバイス一覧カードの 📶 から、HEART_BEAT の往復時間 200 回 (20〜40ms ランダム間隔)
  と BRIDGE_LINK_INFO (ブリッジ単体の往復 + リンク合意値) を計測し、英語固定書式の
  レポートをコピーできる。knownLatest=0.11。開発者の iPhone 15 Pro (iOS 27) では
  interval 30→15ms 受理 / 2M PHY / RTT 中央値 32ms で、報告者の遅延は未再現
  (報告者の計測結果待ち)。v1.8.0 は未タグのまま v1.9.0 に包含。
  v1.9.0 リリース後に main で **最小 iOS を 15.0 に引き上げ済み (未リリース)** =
  ITMS-90068 (2027-04 以降 15.0 未満は提出不可) 対応 + Xcode 27 が 13.0 をエラーに
  するため。実機へは `fvm flutter build ios --release` → `xcrun devicectl device install app`)
- app v1.8.0 (旧, 未タグ): pubspec 1.8.0+33。
  protocol 0.10 対応 (knownLatest=0.10、機能対応は不要で版数のみ)、minMinor=7。**macOS のリモート入力とゲームパッド背景動作**を追加 =
  別アプリ (RetroCastX) の画面を見ながら X68000 を操作できるようにする。
  (a) `gamepads_darwin` フォークで `shouldMonitorBackgroundEvents` を有効化し、
  最前面でなくてもパッド入力を受け取る。(b) 仮想 MIDI 宛先 `MimicX Remote Input` を
  公開し、別アプリから転送された物理キーをローカルのキーボードと同じ経路で実機へ送る
  (`protocol.dart` の sub-id 0x02。USB HID usage を 7bit×4 で受け、
  `PhysicalKeyboardKey.findKeyByCode()` から既存の `_physicalKeyMap` に直結)。
  RetroCastX 側の実装指示書は `RetroCastX/docs/mimicx-remote-input.md`。
  **識別スキャンから own-virtual を除外**しないと自分の仮想ポートを叩いて接続を壊す点に注意。
  あわせて方向判定を十字キー/スティックで独立化 + デッドゾーン、操作画面での BLE
  スキャン停止、ダイアログ表示中の接続喪失で Navigator が壊れる不具合の修正、
  flutter_midi_command フォークを 6c343c0 へ更新を含む。
  **iOS / Android / Windows 未確認**)
- app v1.7.2 (旧): **Windows で MSVC ランタイムを app-local
  同梱** = VC++ 2015-2022 再頒布可能パッケージ未インストールの素の Windows で
  `mimicx.exe` が「VCRUNTIME140_1.dll が見つからない」で起動できない問題を解消。
  `windows/CMakeLists.txt` に `InstallRequiredSystemLibraries` を追加し、Flutter の
  install 時に `VCRUNTIME140.dll` / `VCRUNTIME140_1.dll` / `MSVCP140.dll` 等を exe と
  同じ Release フォルダへコピー。Inno Setup は Release 配下を丸ごと拾うので `.iss` /
  workflow は無変更、portable zip・installer 両方に反映。Universal CRT は Windows 10+
  が OS 標準で持つため非同梱。`PrivilegesRequired=lowest` の per-user インストールと
  両立 (管理者昇格不要)。Windows 実機で起動中プロセスが app-local から
  `VCRUNTIME140_1.dll` を読むことを確認済み。v1.7.1 の Windows アイドル CPU 約8% 解消
  (`gamepads_windows` fork に `Sleep(8)`)・v1.7.0 の Combined 両画面同時生存
  (IndexedStack, 瞬時切替 + ゲームパッド/物理キーボード両画面対応, LED オレンジ化解消)・
  電源 OFF アダプタの一覧プルーニング・v1.6.x の iOS/macOS BLE 接続安定化を含む)

## フォーク依存 (pubspec の ref)

- `flutter_midi_command` (iOS/macOS/Android): kunichiko/FlutterMidiCommand
  `6c343c0` (fix/ble-connect-timeout) — SPM 対応 + Android 接続待ち除去 +
  iOS/macOS の connect タイムアウト/stale プルーニング + Android stale プルーニング +
  **iOS/macOS の MethodChannel 二重応答の解消** (`disconnectDevice` の末尾に
  無条件の `result(nil)` があり必ず 2 回応答していた / native・virtual の接続成功時に
  `ongoingConnections` を消していなかった)。修正前は起動時の識別フローの切断ごとに
  "Message responses can be sent only once" がログに出ていた
- `flutter_midi_command_windows`: kunichiko/flutter_midi_command_windows
  `3bb2b88` (fix/winmm-stability) — winmm 安定化 + BLE readiness + 不在デバイスの
  プルーニング/connect ガード。**ボンド自動修復 (自動 unpair) は撤去済み** —
  アプリは Windows のペアリング状態を自動操作しない (誤 unpair→クラッシュ→
  再ペアリング不能の連鎖事故のため)。ボンド不一致は案内ダイアログで手動対応
- `gamepads_windows` (Windows のみ): kunichiko/gamepads (monorepo, `packages/gamepads_windows`)
  `79a826e` (mimicx/winmm-busyloop-fix) — dependency_overrides で git url+path pin。
  winmm ポーリングループ (`read_gamepad`) の sleepless busy-loop に `Sleep(8)` (~125Hz)
  を追加し、ジョイスティック列挙時にアイドルで 1 コア張り付き = 約8% CPU だったのを
  0.5% に解消。**winmm を維持する** — upstream の修正 (0.3.0) は WinRT/GameInput への
  全面書き換えで `gameinput.dll` にロード時リンクし **Win10 で DLL 不在だと起動不能**
  (+ ビルドに Windows SDK 26100+ 必須) になるため採用しない (`gamepads: 0.1.8` を
  pin している理由そのもの)。イベント形式は winmm のまま不変なので `lib/gamepad_input.dart`
  は無変更
- `gamepads_darwin` (macOS のみ): kunichiko/gamepads (monorepo, `packages/gamepads_darwin`)
  `c6dd3b8` (mimicx/darwin-background-events) — `GCController.shouldMonitorBackgroundEvents
  = true` を立てて **最前面でなくてもゲームパッド入力を受け取る**。macOS Big Sur 11.3
  以降の既定は NO で、非フォアグラウンドでは入力が一切配送されない。別アプリ
  (RetroCastX = 実機のアナログRGB映像を Mac に表示する自作アプリ) の画面を見ながら
  パッドで実機を操作するために必要。Dart 側は無変更
  - **ref が `gamepads_windows` と別なのは意図的**。windows は winmm 実装を維持するため
    `79a826e` (古い upstream 系列) に留める必要があり、darwin は upstream main 系列で
    ないと 0.1.2+4 の `getFixedKey` (Switch Pro の +/- が `buttonMenu`/`buttonOptions`
    で飛ぶ修正) が入らない。0.1.2+2 に落とすと**プロコンの + = MD6B START が効かなくなる**
  - 両フォークとも `resolution: workspace` を除去済み。これが残っていると git+path
    参照時にモノレポ全体のワークスペース解決に巻き込まれ、host の pubspec.lock が
    広範囲にダウングレードされる

app / firmware は同時にバージョンアップしない場合があるが、protocol minor を超える
差は接続不可となる (app 側で `MinSupportedProtocol.meets()` 判定)。

## 新環境セットアップ

```sh
# 1. workspace 自体を clone
git clone https://github.com/kunichiko/MimicX-workspace.git MimicX
cd MimicX

# 2. sub-repo を bootstrap
./scripts/clone-all.sh
```
