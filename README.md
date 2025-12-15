# Submovement Analyzer

__Submovement Analyzer__ は3次元位置データの時系列CSVファイルを読み込み、速度・加速度・躍度（Jerk）を算出することで、到達運動におけるサブムーブメント（Submovement）を自動検出・分類するMATLABアプリケーションです。

Roberts et al. (2024) の手法に基づき、運動開始・終了の検出に加え、Type 1 (Velocity zero-crossing), Type 2 (Acceleration zero-crossing), Type 3 (Jerk zero-crossing) の各サブムーブメントを識別します。

## 主な機能
- __一括処理__:
    - 複数のCSVファイルを同時に読み込み、一括で解析を実行
- __柔軟なデータ読み込み__: 
    - データの開始列や時間列、ヘッダーの有無を指定
    - 単位変換機能: mm, cm, mの入力データに対応
- __解析アルゴリズム__:
    - ゼロ位相Butterworthフィルタによる平滑化 (フィルター次数・カットオフ周波数を指定)
    - サンプリングレートの自動算出機能 (手動指定も可) 
    - ピーク速度からの逆探索による堅牢な運動開始（Onset）検出
- __可視化__: 
    - 3次元軌道と運動学的指標（速度・加速度・躍度）の同期プロット
    - 軸マッピング（CSVのどの列をXYZに割り当てるか）の動的変更
    - 表示オプション（グリッド、軌道、イベント点）のON/OFF切り替え
- __詳細な出力__: 
    - 解析結果（イベントフレーム、サブムーブメントの種類）に加え、座標データや運動学的指標（最大速度、所要時間など）を選択してCSVに出力
- __設定の保存__: 
    - フィルタ設定や閾値などのパラメータは、アプリ終了時に自動的に保存され、次回起動時に引き継ぎ

## 必要要件　
- MATLAB R2022b 以降 (推奨)
- Signal Processing Toolbox (butter, filtfilt 関数使用のため)

## インストールと起動方法　
1. 本リポジトリのすべてのファイル・フォルダをローカル環境にダウンロードします。
2. MATLABを起動し、プロジェクトのルートフォルダ（SubmovementAnalyzer.m がある場所）をカレントディレクトリに設定します。
3. コマンドウィンドウで以下のコマンドを入力して起動します。
```
app = SubmovementAnalyzer.launch();
```
__注意__: 多重起動を防ぐため、コンストラクタを直接呼び出すのではなく、必ず上記の静的メソッド `launch()` を使用してください。

## 入力データ形式

読み込み可能なCSVファイルは以下の形式を想定しています。
- __ファイル形式__: CSV (カンマ区切り) 
- __データ構造__: 時間データ列 + 3次元位置データ（XYZ）を含む行列データ。
- __ヘッダー行__: あり・なし両対応 (インポート設定で指定可能)

## 使用方法 
GUIは以下の4つのステップ（タブ）に分かれています。

### 1. Import (データの読み込み)
- __CSV Format__: 時間列 (Time Col) や位置データの開始列 (Pos Start) を指定
- __Unit__: 入力データの単位 (mm, cm, cm) を選択
- __Load CSV Files__: 解析対象のファイルを選択して読み込み

### 2. Analyze (解析の実行) 
- __Filter Settings__: フィルタの次数 (Order) とカットオフ周波数 (Cutoff) を指定
- __Auto FS__: チェックを入れるとデータからサンプリングレートを自動算出。外すと手動入力 (Manual Fs) が有効化
- __Detection Params__: 
    - __Vel Thresh__: 運動の開始・終了判定に使用する速度閾値 (mm/s) 
    - __Min Dur__: 状態が安定しているとみなすための最小持続時間 (ms)
- __Run Analysis__: 全ファイルの解析を実行

### 3. Visualization (結果の確認)
- __Axis Mapping__: CSVデータの列 (Col 1, 2, 3) を、プロット上の X, Y, Z 軸にどう割り当てるかを設定
- __Display Options__:
    - __Show Grid__: グリッドの表示/非表示
    - __Show Trajectory__: 運動軌道の表示/非表示
    - __Show Events__: 開始点・終了点・サブムーブメント点のマーカー表示/非表示
- __Result Table__: 
    - 結果テーブルでファイルを選択すると、右側のパネルに軌道と波形が表示
    - キーボードの上下キーでファイルを順次切り替えて確認可

### 4. Export (結果の保存)
- __Output Options__: CSVに出力する項目をチェックボックスで選択します。
    - __General__: サブムーブメントのタイプ
    - __Coordinates__: 各イベント（Onset, Offset, Sub）のXYZ座標
    - __Metrics__: 総所要時間、最大速度などの運動学的指標
- __Export to CSV__: 選択した内容でサマリーファイルを保存します。

## プロジェクト構成 (Architecture)
本ソフトウェアは MVP (Model-View-Presenter) パターンに基づいて設計されており、責務が明確に分離されています。
```
ProjectRoot/
├── SubmovementAnalyzer.m           # [Presenter] アプリの起動・イベント制御・ModelとViewの仲介
├── settings.json                   # [Config] 設定ファイル (自動生成)
├── data/                           # [Data] サンプルデータ置き場
└── +MotionAnalysis/                # [Root Package]
    ├── +Model/                     # [Model Layer] ビジネスロジックと状態保持
    │   ├── AppModel.m              # データと設定の状態管理
    │   ├── AnalysisEngine.m        # 解析パイプラインの実行エンジン
    │   └── +Algorithms/            # 純粋な計算アルゴリズム群 (フィルタ, 微分, イベント検出)
    ├── +View/                      # [View Layer] UI構築と描画
    │   ├── MainView.m              # UIコンポーネント定義とレイアウト
    │   ├── Plotter.m               # グラフ描画ロジック
    │   ├── GraphStyle.m            # グラフのスタイル定数 (色, 線種)
    │   └── AppConstants.m          # UIの文字列リソース定数
    └── +IO/                        # [Infrastructure] 入出力
        ├── Config.m                # 設定ファイルの読み書き
        ├── loadBatch.m             # CSV読み込み
        └── exportSummary.m         # CSV書き出し
```
### 開発者向けガイド
- __アルゴリズムの変更__: +Model/+Algorithms/ 内の関数を編集
- __UIレイアウトの変更__: +View/MainView.m を編集
- __グラフの見た目の変更__: +View/GraphStyle.m の定数を編集

## 参考文献 
本ソフトウェアのアルゴリズムは以下の論文に基づいています。
> Roberts, J. W., Burkitt, J. J., & Elliott, D. (2024). The type 1 submovement conundrum: an investigation into the function of velocity zero-crossings within two-component aiming movements. Experimental Brain Research, 242, 921–935.

## ライセンス
This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.