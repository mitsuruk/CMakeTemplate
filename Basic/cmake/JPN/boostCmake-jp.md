# boost.cmake ドキュメント

## 概要

`boost.cmake` は Boost ライブラリをプロジェクトに統合するための CMake 設定ファイルです。使用する Boost コンポーネントを一元管理し、リンクを自動的に設定します。

## ファイル情報

| 項目 | 内容 |
|------|------|
| プロジェクト | CMake テンプレートプロジェクト |
| 作者 | mitsuruk |
| 作成日 | 2025/11/26 |
| ライセンス | MIT License |

---

## インクルードガード

```cmake
include_guard(GLOBAL)
```

このファイルは `include_guard(GLOBAL)` を使用して、複数回インクルードされても一度だけ実行されるようにしています。

**必要な理由：**

- `find_package(Boost ...)` の重複呼び出しを防止
- `target_link_libraries` による重複リンクを防止
- Boost コンポーネントの重複登録を回避

---

## 処理の流れ

```
1. コンポーネント定義 → 2. Boost 検索 → 3. ターゲット名生成 → 4. リンク → 5. デバッグ情報出力
```

---

## 機能の詳細

### 1. Boost コンポーネントの定義

```cmake
set(BOOST_COMPONENTS
    headers            # 必須：共通ヘッダー
    # 以下は任意（コメントアウトを外して有効化）
)
```

使用する Boost コンポーネントをリストとして定義します。必要なコンポーネントのコメントアウトを外して有効にしてください。

#### 使用可能なコンポーネント

| コンポーネント | 説明 |
|--------------|------|
| `headers` | Boost 共通ヘッダー（ほとんどのライブラリに必要） |
| `atomic` | アトミック操作（ロックフリー並行処理用） |
| `chrono` | 時間の表現と計測（`std::chrono` に類似） |
| `container` | 高速な標準コンテナ代替（小サイズ最適化、フラット構造） |
| `context` | 低レベルコンテキストスイッチング（コルーチンとファイバーの基盤） |
| `coroutine` | 協調的マルチタスキング（`Boost::context` 上に構築） |
| `date_time` | 日付・時刻計算（カレンダー時刻、特殊日付サポート） |
| `fiber` | ユーザーランドスレッド（スレッド間の協調スケジューリング） |
| `filesystem` | ファイル・ディレクトリ操作（`std::filesystem` 風 API） |
| `graph` | グラフ構造とアルゴリズム（ダイクストラ、DFS など） |
| `iostreams` | カスタム I/O ストリーム（圧縮/暗号化/メモリバッファサポート） |
| `json` | 高性能 JSON パーサー/ジェネレーター（RFC 完全準拠） |
| `locale` | ローカライズ（i18n/l10n、メッセージ翻訳） |
| `log` | 高度なロギング（フィルタ、フォーマット、非同期など） |
| `log_setup` | Boost.Log 初期化サポート（設定ファイルサポート） |
| `program_options` | コマンドライン/設定ファイルからのオプション解析 |
| `random` | 擬似乱数ジェネレーター（各種分布とエンジン） |
| `regex` | 正規表現（Perl 互換、Unicode サポート） |
| `serialization` | C++ オブジェクトのシリアライズ/デシリアライズ（XML/テキスト/バイナリ） |
| `thread` | スレッド抽象化と同期プリミティブ |
| `timer` | 経過時間の計測 |
| `unit_test_framework` | 統合ユニットテストフレームワーク |
| `url` | URL の解析と生成（標準準拠） |

---

### 2. Boost パッケージの検索

```cmake
find_package(Boost 1.80.0 REQUIRED CONFIG COMPONENTS ${BOOST_COMPONENTS})
```

| パラメータ | 説明 |
|----------|------|
| `1.80.0` | 必要最低バージョン |
| `REQUIRED` | 見つからない場合エラー |
| `CONFIG` | CMake config ファイルモードで検索 |
| `COMPONENTS` | 指定されたコンポーネントを検索 |

---

### 3. ターゲット名の自動生成

```cmake
set(BOOST_DYNAMIC_LIBS "")
foreach(comp IN LISTS BOOST_COMPONENTS)
    list(APPEND BOOST_DYNAMIC_LIBS "Boost::${comp}")
endforeach()
```

コンポーネント名から `Boost::xxx` 形式の CMake ターゲット名を自動生成します。

**例：**
- `headers` → `Boost::headers`
- `filesystem` → `Boost::filesystem`

---

### 4. ターゲットへのリンク

```cmake
target_link_libraries(${PROJECT_NAME} PRIVATE ${BOOST_DYNAMIC_LIBS})
```

生成されたすべての Boost ターゲットをプロジェクトにリンクします。

---

### 5. デバッグ情報の出力

```cmake
message(STATUS "Boost version: ${Boost_VERSION}")
message(STATUS "Boost include dirs: ${Boost_INCLUDE_DIRS}")
message(STATUS "Boost libraries: ${BOOST_DYNAMIC_LIBS}")
```

ビルド時に以下の情報を表示します：
- 検出された Boost バージョン
- インクルードディレクトリ
- リンクされたライブラリのリスト

---

## 使い方

### 基本的な使い方

1. 使用したいコンポーネントのコメントアウトを外す：

```cmake
set(BOOST_COMPONENTS
    headers
    filesystem    # コメントアウトを外す
    regex         # コメントアウトを外す
)
```

2. メインの `CMakeLists.txt` からインクルード：

```cmake
include(cmake/boost.cmake)
```

---

## 依存関係

| 依存先 | 必須/任意 | 説明 |
|--------|-----------|------|
| Boost 1.80.0 以上 | 必須 | システムにインストールされている必要がある |
| `${PROJECT_NAME}` | 必須 | メインプロジェクトのターゲット名 |

---

## 注意事項

1. **Boost のインストール**：Boost はシステムに事前にインストールされている必要があります（Homebrew、vcpkg、システムパッケージなど）。

2. **コンポーネント間の依存関係**：一部のコンポーネントは他のコンポーネントに依存します（例：`log` は `filesystem` と `thread` に依存）。CMake がこれらを自動的に解決します。

3. **Python 関連コンポーネント**：`python313` や `numpy313` などの Python バインディングコンポーネントは特別な設定が必要で、通常は使用しません。

4. **非推奨コンポーネント**：コメント内で「使用は想定していない」とされているコンポーネントは、特定の理由がない限り避けてください。
