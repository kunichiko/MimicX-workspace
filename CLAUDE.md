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

## バージョン整合性 (現時点 = 2026-06-02)

- protocol: **0.7.0** (spec 上 draft)
- firmware: **v0.8.0** (protocol 0.7 対応)
- app: **v1.3.0** (protocol 0.7 対応、minMinor=7)

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
