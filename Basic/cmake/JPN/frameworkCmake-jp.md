# framework.cmake ドキュメント

## 概要

`framework.cmake` は macOS/Apple 環境でシステムフレームワークをプロジェクトにリンクするための設定ファイルです。macOS 15.1（Sequoia）で利用可能な全フレームワークの包括的なリストを提供します。

## ファイル情報

| 項目 | 内容 |
|------|------|
| プロジェクト | CMake テンプレートプロジェクト |
| 作者 | mitsuruk |
| 作成日 | 2025/11/26 |
| ライセンス | MIT License |
| 対象 OS | macOS 15.1 (24B83) "Sequoia" |

---

## インクルードガード

```cmake
include_guard(GLOBAL)
```

このファイルは `include_guard(GLOBAL)` を使用して、複数回インクルードされても一度だけ実行されるようにしています。

**必要な理由：**

- `target_link_libraries` の重複呼び出しを防止
- 同一フレームワークの重複リンクを回避
- リンカーエラーや警告を防止

---

## 基本構造

```cmake
target_link_libraries(${PROJECT_NAME} PRIVATE
    # "-framework フレームワーク名"
    # 使用したいフレームワークのコメントアウトを外す
)
```

すべてのフレームワークはコメントアウトされた状態で提供されます。必要なフレームワークのコメントアウトを外して使用してください。

---

## フレームワーク一覧

### SwiftUI 統合フレームワーク

| フレームワーク | 説明 |
|-------------|------|
| `_AppIntents_AppKit` | AppIntents と AppKit の統合 |
| `_AppIntents_SwiftUI` | AppIntents と SwiftUI の統合 |
| `_AVKit_SwiftUI` | AVKit と SwiftUI の統合 |
| `_CoreData_CloudKit` | CoreData と CloudKit の統合 |
| `_MapKit_SwiftUI` | MapKit と SwiftUI の統合 |
| `_PhotosUI_SwiftUI` | PhotosUI と SwiftUI の統合 |
| `_SwiftData_SwiftUI` | SwiftData と SwiftUI の統合 |

### コアシステムフレームワーク

| フレームワーク | 説明 |
|-------------|------|
| `Foundation` | 基本データ型、コレクション、OS 機能 |
| `CoreFoundation` | C ベースの基盤フレームワーク |
| `CoreServices` | ファイルシステム、メタデータ、起動サービス |
| `System` | 低レベルシステムインターフェース |
| `Security` | 暗号化、認証、キーチェーン |

### UI/アプリケーションフレームワーク

| フレームワーク | 説明 |
|-------------|------|
| `AppKit` | macOS アプリケーション UI |
| `SwiftUI` | 宣言的 UI フレームワーク |
| `Cocoa` | AppKit + Foundation の統合 |
| `Carbon` | レガシー UI フレームワーク |

### グラフィックス/メディアフレームワーク

| フレームワーク | 説明 |
|-------------|------|
| `Metal` | 低レベル GPU アクセス |
| `MetalKit` | Metal ヘルパー |
| `MetalPerformanceShaders` | GPU 最適化シェーダー |
| `OpenGL` | レガシー 3D グラフィックス |
| `OpenCL` | GPU コンピューティング |
| `CoreGraphics` | 2D グラフィックス |
| `CoreImage` | 画像処理 |
| `QuartzCore` | アニメーション、コンポジティング |
| `SceneKit` | 3D シーン管理 |
| `SpriteKit` | 2D ゲームエンジン |
| `RealityKit` | AR/VR 体験 |

### オーディオ/ビデオフレームワーク

| フレームワーク | 説明 |
|-------------|------|
| `AVFoundation` | オーディオ/ビデオ処理 |
| `AVKit` | メディアプレーヤー UI |
| `CoreAudio` | 低レベルオーディオ |
| `CoreMedia` | メディアパイプライン |
| `VideoToolbox` | ハードウェアビデオ処理 |
| `AudioToolbox` | オーディオ処理ツール |

### 機械学習/AI フレームワーク

| フレームワーク | 説明 |
|-------------|------|
| `CoreML` | 機械学習モデルの実行 |
| `CreateML` | 機械学習モデルの作成 |
| `Vision` | コンピュータビジョン |
| `NaturalLanguage` | 自然言語処理 |
| `SoundAnalysis` | 音声分類 |
| `Speech` | 音声認識 |

### ネットワーク/通信フレームワーク

| フレームワーク | 説明 |
|-------------|------|
| `Network` | モダンネットワーキング API |
| `CFNetwork` | Core Foundation ネットワーキング |
| `NetworkExtension` | VPN、コンテンツフィルター |
| `MultipeerConnectivity` | P2P 通信 |

### データ管理フレームワーク

| フレームワーク | 説明 |
|-------------|------|
| `CoreData` | オブジェクトグラフの永続化 |
| `SwiftData` | Swift 向けデータ永続化 |
| `CloudKit` | iCloud データ同期 |

### ハードウェアアクセスフレームワーク

| フレームワーク | 説明 |
|-------------|------|
| `IOKit` | ハードウェアアクセス |
| `CoreBluetooth` | Bluetooth LE |
| `CoreLocation` | 位置情報サービス |
| `CoreMotion` | モーションセンサー |
| `CoreHaptics` | 触覚フィードバック |

### 仮想化/システム拡張

| フレームワーク | 説明 |
|-------------|------|
| `Virtualization` | 仮想マシン |
| `Hypervisor` | ハイパーバイザー API |
| `DriverKit` | ユーザー空間ドライバー |
| `SystemExtensions` | システム拡張 |

---

## 使い方

### 1. 必要なフレームワークのコメントアウトを外す

```cmake
target_link_libraries(${PROJECT_NAME} PRIVATE
    "-framework Foundation"
    "-framework CoreGraphics"
    "-framework Metal"
    # その他必要なフレームワーク
)
```

### 2. メインの CMakeLists.txt からインクルード

```cmake
if(APPLE)
    include(cmake/framework.cmake)
endif()
```

---

## フレームワークの見つけ方

ファイル末尾のコメントに記載されたコマンドで、システムにインストールされているフレームワークを確認できます：

```bash
# システムフレームワーク
find /System/Library/Frameworks -name "*.framework" -depth 1

# ユーザーインストールフレームワーク（Xcode など）
find /Library/Frameworks -name "*.framework" -depth 1
```

---

## 依存関係

| 依存先 | 必須/任意 | 説明 |
|--------|-----------|------|
| `${PROJECT_NAME}` | 必須 | メインプロジェクトのターゲット名 |
| macOS | 必須 | macOS 専用 |

---

## 注意事項

1. **プラットフォームの制限**：このファイルは macOS 専用です。`if(APPLE)` ガード内で使用してください。

2. **フレームワークの利用可能性**：一部のフレームワークは特定の macOS バージョン以降でのみ利用可能です。

3. **アンダースコアプレフィックス**：`_`（例：`_SwiftUI_MapKit`）で始まるフレームワークは内部統合用であり、通常は直接使用しません。

4. **非推奨フレームワーク**：`QTKit`、`Carbon`、`OpenGL` などは非推奨です。新規プロジェクトでは代替を検討してください。

5. **PRIVATE 指定子**：フレームワークは `PRIVATE` でリンクされます。ライブラリをビルドする場合は、必要に応じて `PUBLIC` または `INTERFACE` に変更してください。

6. **Swift 統合**：SwiftUI 関連フレームワークを使用する場合、Swift との統合が必要になることがあります。
