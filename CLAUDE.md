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

## バージョン整合性 (現時点 = 2026-08-01)

- protocol: **0.10.0** (main にコミット済み、**タグ未**。BRIDGE_REBOOT_BOOTLOADER 0x0C
  §6.4.6 を追加 — ブリッジ (ESP32) を ROM ダウンロードモードで再起動させる開発者向け
  コマンド。マジック "BOT" 必須。ブリッジ自答なので CH32 の実装は不要で、CH32 が申告する
  protocol_version の 0.10 追従は次回 firmware リリースに同乗させればよい。
  0.9.0 = TOWNS パッド RUN/SELECT = note 21/22 + SOCD ガード、v0.9.0 タグ済み)
- firmware: **v1.1.0** (protocol 0.9 対応。タグ済み)
- app: **v1.7.2** (protocol 0.9 対応、minMinor=7。**Windows で MSVC ランタイムを app-local
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
