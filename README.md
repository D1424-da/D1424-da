<p align="center">
  <img src="https://capsule-render.vercel.app/api?type=waving&color=0:2E9EF7,100:00A67E&height=120&section=header&text=IT%20Challenge%20from%2044!&fontSize=40&fontAlignY=40"/>
</p>

<h1 align="center">
  <img src="https://readme-typing-svg.herokuapp.com?font=Fira+Code&size=32&duration=2800&pause=2000&color=2E9EF7&center=true&vCenter=true&width=940&lines=Hi+%F0%9F%91%8B+I'm+Daisuke+Ikeda;44%E6%AD%B3%E3%81%8B%E3%82%89IT%E6%A5%AD%E7%95%8C%E3%81%AB%E6%8C%91%E6%88%A6%E4%B8%AD" alt="Typing SVG" />
</h1>

<p align="center">
  <b>24年間の実務経験 × プログラミング技術で価値を創造する</b><br>
  <sub>業務効率化・アプリ開発・システム自動化</sub>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/%F0%9F%9F%A2%20Status-Seeking%20Job%20Opportunities-success?style=for-the-badge" alt="Status"/>
  <img src="https://img.shields.io/badge/Age-44-blue?style=for-the-badge" alt="Age"/>
  <img src="https://img.shields.io/badge/Focus-Automation%20%7C%20Apps%20%7C%20Efficiency-orange?style=for-the-badge" alt="Focus"/>
  <img src="https://komarev.com/ghpvc/?username=D1424-da&color=blueviolet&style=for-the-badge" alt="Profile views"/>
</p>

---

## 🚀 Featured Project

### 📊 測量報告書作成自動化システム

**8年間の測量業務経験から生まれた、業務全体を自動化する統合システム**

#### 解決した課題

測量業務において、以下の課題がありました：
- 写真内容（遠景/近景など）を目視で判別する必要がある
- 報告書に写真を1枚ずつ手作業で配置する必要がある
- 測量画像の管理が煩雑で時間がかかる

この作業は1件あたり**数時間かかっていました**。年間40〜80件の業務で大きな負担となっていたため、**3つのサブシステムを連携させた完全自動化システム**を開発しました。

---

#### システム構成

業務フローに沿った3段階の自動化を実現：

**ステップ1: GPSSCAN（写真リネーム自動化）**
- SIMファイル（測量データ）とGPS情報から、写真を測量点に自動マッチング
- 体系的なファイル名に一括リネーム

**主な機能:**
- SIMファイル解析（A01/A02/D00形式対応）
- GPS座標の自動平面直角座標変換（EPSG:6669-6687）
- ドラッグ&ドロップによる直感的なマッチングUI
- 測量点・地番境界の地図可視化

**技術:** `Python` `Tkinter` `Matplotlib` `pyproj` `pandas` `OpenCV`

[![GPSSCAN](https://img.shields.io/badge/GPSSCAN-Repository-181717?style=for-the-badge&logo=github)](https://github.com/D1424-da/GPSSCAN)

---

**ステップ2: AI画像認識（写真分類自動化）**
- 機械学習により、写真の内容を自動判別
- 遠景/近景などを自動分類し、次のステップに必要な情報を付与

**技術的な取り組み:**
- 192,000枚の画像データセット作成（12クラス × 各16,000枚）
- TensorFlow/Kerasによるディープラーニングモデル構築
- データ拡張による汎化性能向上

**技術:** `Python` `TensorFlow/Keras` `OpenCV` `scikit-learn`

[![AI](https://img.shields.io/badge/AI-Repository-181717?style=for-the-badge&logo=github)](https://github.com/D1424-da/AI)

---

**ステップ3: 自動写真アルバム（報告書配置自動化）**

Excel VBAにより、整理された写真を報告書フォーマットに自動配置し、最終的な測量報告書を完成させます。

**実装内容:**
- 測量点ごとに写真を自動配置
- 遠景/近景の配置位置を自動判定
- 報告書フォーマットに準拠した体裁調整

**技術:** `Excel VBA` `マクロ自動化`

**自動化の様子:**

<p align="center">
  <img src="images/vba.gif" alt="自動配置のデモ" width="700"/>
</p>

**完成例（ビフォー・アフター）:**

<p align="center">
  <img src="images/VBAmain.png" alt="手作業 vs 自動化" width="700"/>
</p>

> **※業務データを含むため、リポジトリは非公開としています**

---

#### 成果

- **作業時間**: 数時間 → 数分に短縮
- **適用業務数**: 年間40〜80件
- **システム連携**: 3つのサブシステムによる統合ワークフロー

---

## 💼 Other Projects

### 📁 [高速ファイル検索アプリ](https://github.com/D1424-da/file-search-app)

**課題:** 測量資料を紙ベースで保管していたため、保管場所と書類管理が大変

**解決策:** PDFやワード、エクセルの内容を読み取りデータベース化し、検索文字でタイトルと内容の両方検索できるようにしているため管理、保管がしやすくなった。

**主な機能:**
- PDF、Word、Excelファイルの自動テキスト抽出
- ファイル名とファイル内容の両方を対象とした高速検索
- データベース化による効率的な文書管理
- 直感的なGUIによる簡単操作

**技術:** `Python` `Tkinter`

[![Repo](https://img.shields.io/badge/View%20Repository-181717?style=for-the-badge&logo=github)](https://github.com/D1424-da/file-search-app)

---

## 💻 Tech Stack

### 言語
![Python](https://img.shields.io/badge/Python-3776AB?style=for-the-badge&logo=python&logoColor=white)
![Excel VBA](https://img.shields.io/badge/Excel%20VBA-217346?style=for-the-badge&logo=microsoft-excel&logoColor=white)
![JavaScript](https://img.shields.io/badge/JavaScript-F7DF1E?style=for-the-badge&logo=javascript&logoColor=black)
![PHP](https://img.shields.io/badge/PHP-777BB4?style=for-the-badge&logo=php&logoColor=white)
![C#](https://img.shields.io/badge/C%23-239120?style=for-the-badge&logo=c-sharp&logoColor=white)
![SQL](https://img.shields.io/badge/SQL-4479A1?style=for-the-badge&logo=mysql&logoColor=white)

### フレームワーク・ライブラリ
![Tkinter](https://img.shields.io/badge/Tkinter-3776AB?style=for-the-badge&logo=python&logoColor=white)
![Pandas](https://img.shields.io/badge/Pandas-150458?style=for-the-badge&logo=pandas&logoColor=white)
![NumPy](https://img.shields.io/badge/NumPy-013243?style=for-the-badge&logo=numpy&logoColor=white)
![Matplotlib](https://img.shields.io/badge/Matplotlib-11557c?style=for-the-badge&logo=python&logoColor=white)
![OpenCV](https://img.shields.io/badge/OpenCV-5C3EE8?style=for-the-badge&logo=opencv&logoColor=white)
![TensorFlow](https://img.shields.io/badge/TensorFlow-FF6F00?style=for-the-badge&logo=tensorflow&logoColor=white)
![scikit-learn](https://img.shields.io/badge/scikit--learn-F7931E?style=for-the-badge&logo=scikit-learn&logoColor=white)

### ツール
![Git](https://img.shields.io/badge/Git-F05032?style=for-the-badge&logo=git&logoColor=white)
![VS Code](https://img.shields.io/badge/VS%20Code-007ACC?style=for-the-badge&logo=visual-studio-code&logoColor=white)

---

## 👨‍💻 About Me

**公共職業訓練（2025年6月〜12月）**にてプログラミング技術を習得中。
24年間の実務経験と技術力を掛け合わせ、企業の課題解決に貢献できる人材を目指しています。

### 学習スタイル

- **理論と実践の両立**: オライリー技術書で理論を学び、即座にプロジェクトで実装
- **実務課題の解決**: 測量業務の経験から、業務自動化システムを開発
- **システム設計力**: 複数の技術を統合し、業務フロー全体を最適化

---

## 💼 Work Experience

### 🏗️ 測量業務（8年3ヶ月）
**土地家屋調査士事務所 | 2017年4月 〜 2025年6月**

- 年間40〜80件の境界確定・登記業務を担当
- 測量士補資格取得（2021年1月）
- 業務フロー全体を理解し、自動化システムの設計・開発に活用

### 🍱 食品業界（3年4ヶ月）
**仕出し・惣菜販売業（経営統括）| 2013年6月 〜 2016年10月**

- SNS集客で月間60件の新規顧客獲得
- デジタルマーケティングの実践経験

### その他の経験

| 期間 | 職種 | 主な成果 |
|------|------|----------|
| 2010-2013 | 古着リサイクルショップ経営 | Webページ制作の基礎習得 |
| 2006-2010 | 総合リサイクルショップ店舗責任者 | グループ9店舗中売上伸び率1位達成 |

---

## 📊 GitHub Stats

<p align="center">
  <img height="170em" src="https://github-readme-stats.vercel.app/api?username=D1424-da&show_icons=true&theme=tokyonight&include_all_commits=true&count_private=true"/>
  <img height="170em" src="https://github-readme-stats.vercel.app/api/top-langs/?username=D1424-da&layout=compact&langs_count=8&theme=tokyonight"/>
</p>

<p align="center">
  <img src="https://github-readme-streak-stats.herokuapp.com/?user=D1424-da&theme=tokyonight" alt="GitHub Streak"/>
</p>

---

## 📚 継続的な学習

<details>
<summary><b>現在学習中の技術書</b></summary>

### オライリー技術書（4冊）
- 入門 Python 3
- Pythonではじめる機械学習
- 退屈なことはPythonにやらせよう
- ゼロから作るDeep Learning

### 入門書（12冊）
**完読済み（9冊）:**
- Python 1年生 / 2年生（スクレイピング・データ分析）/ 3年生（機械学習・ディープラーニング）
- データサイエンス 1年生、SQL 1年生、JavaScript 1年生
- ChatGPTプログラミング 1年生

**学習中（3冊）:**
- Java 1年生、Python 2年生 アプリ開発、AWS 1年生

**学習方針**: 理論だけでなく、学んだ知識を即座にプロジェクトで実装

</details>

---

## 🎯 Current Goals

- オライリー技術書の完読と実践
- 業務自動化システムのポートフォリオ拡充
- 業務効率化・システム開発分野での転職成功

---

## 🎓 保有資格

<table>
  <tr>
    <td align="center" width="33%">
      <img src="https://img.icons8.com/color/96/000000/survey.png" width="48"/>
      <br><b>測量士補</b>
      <br><sub>2021年1月</sub>
    </td>
    <td align="center" width="33%">
      <img src="https://img.icons8.com/color/96/000000/car.png" width="48"/>
      <br><b>普通自動車免許</b>
      <br><sub>2001年6月</sub>
    </td>
    <td align="center" width="33%">
      <img src="https://img.icons8.com/color/96/000000/motorcycle.png" width="48"/>
      <br><b>普通自動二輪免許</b>
      <br><sub>2001年6月</sub>
    </td>
  </tr>
</table>

---

## 📫 Contact

<p align="center">
  現在、<b>業務効率化・アプリ開発・システム自動化</b>分野での転職活動中です。<br>
  44歳未経験ですが、24年間の実務経験と技術力で必ず貢献できます。
</p>

<p align="center">
  <a href="https://github.com/D1424-da">
    <img src="https://img.shields.io/badge/GitHub-181717?style=for-the-badge&logo=github&logoColor=white" alt="GitHub"/>
  </a>
  <a href="mailto:d.i.a.0101@gmail.com">
    <img src="https://img.shields.io/badge/Email-D14836?style=for-the-badge&logo=gmail&logoColor=white" alt="Email"/>
  </a>
  <a href="https://D1424-da.github.io/profile-page/">
    <img src="https://img.shields.io/badge/Portfolio-4285F4?style=for-the-badge&logo=google-chrome&logoColor=white" alt="Portfolio"/>
  </a>
</p>

---

<div align="center">
  <h3>💡 "Never too late to start"</h3>
  <p>
    <em>44歳からのIT挑戦。実務経験 × 技術力で価値を創造します。</em>
  </p>
</div>

<p align="center">
  <img src="https://capsule-render.vercel.app/api?type=waving&color=gradient&height=100&section=footer"/>
</p>