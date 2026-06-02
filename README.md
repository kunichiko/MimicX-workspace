# MimicX Workspace

Mimic X プロジェクト全体のメタ情報を集めたワークスペースリポジトリ。

Mimic X は、スマートフォン (Flutter アプリ) と USB-MIDI 接続できる小型アダプタを介して、レトロ PC (X68000 / MSX / ATARI 互換機など) の HID デバイス (キーボード / ジョイスティック / マウス) をエミュレートするプロジェクト。

## 構成リポジトリ

| リポジトリ | 役割 |
|---|---|
| [MimicX-firmware](https://github.com/kunichiko/MimicX-firmware)  | CH32X035 マイコンファームウェア (C, PlatformIO) |
| [MimicX-protocol](https://github.com/kunichiko/MimicX-protocol)  | USB-MIDI 経由の HID 制御プロトコル仕様 |
| [MimicX-app](https://github.com/kunichiko/MimicX-app)            | Flutter 製ホストアプリ (iOS / Android / desktop) |
| [MimicX-hardware](https://github.com/kunichiko/MimicX-hardware)  | 基板設計 (KiCad / atopile) |

## ディレクトリ配置

本ワークスペースは 4 つの sub-repository を sibling として保持する。各 sub-repo は **submodule ではなく独立 git リポジトリ** で、本 workspace の git では `.gitignore` で除外している。

```
MimicX/                       ← この workspace リポジトリ
├── CLAUDE.md                 ← Claude Code 用のルール
├── README.md                 ← 本ファイル
├── scripts/
│   └── clone-all.sh          ← 新環境用 sub-repo bootstrap
├── MimicX-firmware/          ← (.gitignore)
├── MimicX-protocol/          ← (.gitignore)
├── MimicX-app/               ← (.gitignore)
└── MimicX-hardware/          ← (.gitignore)
```

## セットアップ

```sh
# 1. workspace 自体を clone
git clone https://github.com/kunichiko/MimicX-workspace.git MimicX
cd MimicX

# 2. sub-repo を bootstrap
./scripts/clone-all.sh
```

## 関連リンク

- Web フラッシャー (CH32X035 のブラウザ書込ツール): <https://kunichiko.github.io/MimicX-firmware/firmware/>
- ファームウェアリリース: <https://github.com/kunichiko/MimicX-firmware/releases>
- アプリリリース: <https://github.com/kunichiko/MimicX-app/releases>

## ライセンス

各サブリポジトリの `LICENSE` を参照。
