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
