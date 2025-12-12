# Submovement Analyzer

本ソフトウェアは、3次元位置データの時系列CSVファイルを読み込み、速度・加速度・躍度（Jerk）を算出することで、到達運動におけるサブムーブメント（Submovement）を自動検出・分類するMATLABアプリケーションです。

Roberts et al. (2024) の手法に基づき、運動開始・終了の検出に加え、Type 1 (Velocity zero-crossing), Type 2 (Acceleration zero-crossing), Type 3 (Jerk zero-crossing) の各サブムーブメントを識別します。

## 主な機能
- 一括処理: 複数のCSVファイルを同時に読み込み、バッチ処理で解析を実行します。
- 柔軟なデータ読み込み: データの開始列や時間列、ヘッダーの有無、および3次元座標（XYZ）の軸マッピングを自由に設定可能です。
- 高度な解析アルゴリズム:
    - ゼロ位相Butterworthフィルタによる平滑化
    - ピーク速度からの逆探索による堅牢な運動開始（Onset）検出
    - 主軸（Primary Axis）への射影成分を用いたサブムーブメント分類
- 可視化: 3次元軌道と、各運動学的指標（速度・加速度・躍度）の波形を、イベントマーカー付きで図示します。
- 詳細なエクスポート: 解析結果（イベントフレーム、サブムーブメントの種類）に加え、座標データや運動学的指標（最大速度、所要時間など）を選択してCSVに出力できます。
- 設定の保存: フィルタ設定や閾値などのパラメータは、アプリ終了時に自動的に保存され、次回起動時に引き継がれます。

## 必要要件　
- MATLAB R2022b 以降 (推奨)
- Signal Processing Toolbox (butter, filtfilt 関数使用のため)

## インストールと起動方法　

本リポジトリのすべてのファイル・フォルダをローカル環境にダウンロードします。
MATLABを起動し、プロジェクトのルートフォルダ（SubmovementAnalyzer.m がある場所）をカレントディレクトリに設定します。
コマンドウィンドウで以下のコマンドを入力して起動します。
```
app = SubmovementAnalyzer.launch();
```
注意: 多重起動を防ぐため、コンストラクタを直接呼び出すのではなく、必ず上記の静的メソッド launch() を使用してください。

## 入力データ形式

読み込み可能なCSVファイルは以下の形式を想定しています。
- 列構成: 時間データ列 + 3次元位置データ（XYZ）を含む行列データ。
- 単位: 位置データの単位はミリメートル (mm) を推奨します（閾値のデフォルト設定が mm/s ベースのため）。

## 使用方法 
GUIは以下の4つのステップ（タブ）に分かれています。

### 1. Import
データの読み込み設定を行います。
CSV Format: 時間列や位置データの開始列を指定します。
Load CSV Files: 解析対象のファイルを選択して読み込みます。

### 2. Analyze 
解析パラメータを設定し、実行します。
- Filter Settings: フィルタの次数 (Order) とカットオフ周波数 (Cutoff) を指定します。サンプリングレート (Fs) は自動算出されますが、手動で指定することも可能です。
- Detection Params: 運動の開始・終了判定に使用する速度閾値 (Vel Thresh) と、安定持続時間 (Min Dur) を設定します。
- 3D Axis Mapping: CSVデータのどの列をプロット上のX/Y/Z軸に割り当てるかを設定します。
- Run Analysis: 全ファイルの解析を実行します。

### 3. Result 
解析結果を個別に確認します。
- 結果テーブルでファイルを選択すると、右側のパネルに軌道と波形が表示されます。
- キーボードの上下キーでファイルを順次切り替えて確認できます。

### 4. Export 
解析結果をCSVファイルとして保存します。 
- Output Options: 出力ファイルに含める情報をチェックボックスで選択します（座標データ、各種メトリクスなど）。
- Export to CSV: 結果を保存します。

## プロジェクト構成 
本ソフトウェアはMVCパターンに基づいて設計されています。
```
ProjectRoot/
├── SubmovementAnalyzer.m           # [Controller] アプリの起動・制御
├── settings.json                   # [Config] 設定ファイル (自動生成)
├── data/                           # [Data] サンプルデータ置き場
└── +MotionAnalysis/                # [Namespace] 解析パッケージ
    ├── +Algorithms/                # 計算ロジック (フィルタ, 微分, イベント検出)
    ├── +FileIO/                    # ファイル入出力, 設定管理
    └── +UI/                        # UIコンポーネント定義, 描画ロジック, リソース
```

## 参考文献 
本ソフトウェアのアルゴリズムは以下の論文に基づいています。
    Roberts, J. W., Burkitt, J. J., & Elliott, D. (2024). The type 1 submovement conundrum: an investigation into the function of velocity zero-crossings within two-component aiming movements. Experimental Brain Research, 242, 921–935.

## ライセンス
This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
